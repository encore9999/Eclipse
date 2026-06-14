import '../../../../core/utils/result.dart';
import '../../../../core/errors/failures.dart';
import '../entities/subscription.dart';
import '../repositories/subscription_repository.dart';

class UpdateSubscription {
  final SubscriptionRepository _repository;
  UpdateSubscription(this._repository);

  Future<Result<Subscription>> call(String subscriptionId) async {
    final subResult = await _repository.getSubscriptionById(subscriptionId);
    if (subResult is FailureResult) return subResult;
    final subscription = (subResult as Success<Subscription>).data;
    if (subscription.status == SubscriptionStatus.paused) {
      return Result.failure(Failure(message: 'Subscription is paused', code: 'SUBSCRIPTION_PAUSED'));
    }
    return _repository.updateSubscription(subscriptionId);
  }
}