import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../domain/usecases/add_subscription.dart';
import '../../domain/usecases/update_subscription.dart';
import '../../../servers/presentation/providers/servers_provider.dart';
import '../../../../injection_container.dart';

class SubscriptionsState {
  final List<Subscription> subscriptions;
  final bool isLoading;
  final bool isAdding;
  final String? updatingId;
  final String? errorMessage;
  const SubscriptionsState({this.subscriptions = const [], this.isLoading = false, this.isAdding = false, this.updatingId, this.errorMessage});
  SubscriptionsState copyWith({List<Subscription>? subscriptions, bool? isLoading, bool? isAdding, String? updatingId, String? errorMessage}) {
    return SubscriptionsState(subscriptions: subscriptions ?? this.subscriptions, isLoading: isLoading ?? this.isLoading, isAdding: isAdding ?? this.isAdding, updatingId: updatingId ?? this.updatingId, errorMessage: errorMessage ?? this.errorMessage);
  }
}

class SubscriptionsNotifier extends StateNotifier<SubscriptionsState> {
  final SubscriptionRepository _repository;
  final AddSubscription _addSubscription;
  final UpdateSubscription _updateSubscription;
  final Ref _ref;

  SubscriptionsNotifier({required SubscriptionRepository repository, required AddSubscription addSubscription, required UpdateSubscription updateSubscription, required Ref ref})
      : _repository = repository, _addSubscription = addSubscription, _updateSubscription = updateSubscription, _ref = ref, super(const SubscriptionsState()) {
    loadSubscriptions();
  }

  Future<void> loadSubscriptions() async {
    state = state.copyWith(isLoading: true);
    final result = await _repository.getSubscriptions();
    result.when(success: (subs) => state = state.copyWith(subscriptions: subs, isLoading: false), failure: (f) => state = state.copyWith(isLoading: false, errorMessage: f.message));
  }

  Future<bool> addSubscription({String name = '', required String url}) async {
    print('[SUB] addSubscription called!'); state = state.copyWith(isAdding: true, errorMessage: null);
    final result = await _addSubscription(name: name, url: url);
    bool success = false;
    result.when(
      success: (sub) { state = state.copyWith(subscriptions: [...state.subscriptions, sub], isAdding: false); _ref.read(serversProvider.notifier).loadServers(); success = true; },
      failure: (f) => state = state.copyWith(isAdding: false, errorMessage: f.message),
    );
    return success;
  }

  Future<void> updateSubscription(String id) async {
    state = state.copyWith(updatingId: id);
    final result = await _updateSubscription(id);
    result.when(
      success: (updatedSub) { final subs = state.subscriptions.map((s) => s.id == id ? updatedSub : s).toList(); state = state.copyWith(subscriptions: subs, updatingId: null); _ref.read(serversProvider.notifier).loadServers(); },
      failure: (f) => state = state.copyWith(updatingId: null, errorMessage: f.message),
    );
  }

  Future<void> updateAll() async { for (final sub in state.subscriptions) { await updateSubscription(sub.id); } }

  Future<void> deleteSubscription(String id) async {
    await _repository.deleteSubscription(id);
    state = state.copyWith(subscriptions: state.subscriptions.where((s) => s.id != id).toList());
    _ref.read(serversProvider.notifier).loadServers();
  }

  Future<void> toggleAutoUpdate(String id) async {
    final result = await _repository.toggleAutoUpdate(id);
    result.when(success: (sub) => state = state.copyWith(subscriptions: state.subscriptions.map((s) => s.id == id ? sub : s).toList()), failure: (_) {});
  }

  Future<void> renameSubscription(String id, String newName) async {
    final result = await _repository.renameSubscription(id, newName);
    result.when(success: (sub) => state = state.copyWith(subscriptions: state.subscriptions.map((s) => s.id == id ? sub : s).toList()), failure: (_) {});
  }
}

final subscriptionsProvider = StateNotifierProvider<SubscriptionsNotifier, SubscriptionsState>((ref) {
  return SubscriptionsNotifier(repository: sl.get<SubscriptionRepository>(), addSubscription: sl.get<AddSubscription>(), updateSubscription: sl.get<UpdateSubscription>(), ref: ref);
});