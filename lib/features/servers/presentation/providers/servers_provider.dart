import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/ping_utils.dart';
import '../../domain/entities/server.dart';
import '../../domain/entities/server_group.dart';
import '../../domain/usecases/test_server.dart';
import '../../domain/usecases/search_servers.dart';
import '../../domain/repositories/server_repository.dart';
import '../../../../vpn_engine/domain/entities/vpn_protocol.dart';
import '../../../../injection_container.dart';

class ServersState {
  final List<Server> servers;
  final List<ServerGroup> groups;
  final bool isLoading;
  final String searchQuery;
  final String? filterProtocol;
  final String? filterCountry;
  final bool onlyFavorites;
  final bool onlyOnline;
  final ServerSortBy sortBy;
  final SortOrder sortOrder;
  final String? testingServerId;
  final Map<String, ServerTestResult> testResults;

  const ServersState({
    this.servers = const [], this.groups = const [], this.isLoading = false,
    this.searchQuery = '', this.filterProtocol, this.filterCountry,
    this.onlyFavorites = false, this.onlyOnline = false,
    this.sortBy = ServerSortBy.ping, this.sortOrder = SortOrder.ascending,
    this.testingServerId, this.testResults = const {},
  });

  List<Server> get filteredServers {
    var result = List<Server>.from(servers);
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where((s) => s.name.toLowerCase().contains(q) || s.address.toLowerCase().contains(q) || s.protocol.displayName.toLowerCase().contains(q)).toList();
    }
    if (filterProtocol != null) result = result.where((s) => s.protocol.name == filterProtocol).toList();
    if (filterCountry != null) result = result.where((s) => s.countryCode == filterCountry).toList();
    if (onlyFavorites) result = result.where((s) => s.isFavorite).toList();
    if (onlyOnline) result = result.where((s) => s.ping != null && s.ping! > 0).toList();
    result.sort((a, b) {
      int c;
      switch (sortBy) {
        case ServerSortBy.name: c = a.name.compareTo(b.name);
        case ServerSortBy.ping: c = (a.ping ?? 9999).compareTo(b.ping ?? 9999);
        case ServerSortBy.country: c = (a.country ?? '').compareTo(b.country ?? '');
        case ServerSortBy.protocol: c = a.protocol.name.compareTo(b.protocol.name);
        case ServerSortBy.lastUsed: c = (b.lastUsedAt?.millisecondsSinceEpoch ?? 0).compareTo(a.lastUsedAt?.millisecondsSinceEpoch ?? 0);
        case ServerSortBy.usageCount: c = b.usageCount.compareTo(a.usageCount);
      }
      return sortOrder == SortOrder.ascending ? c : -c;
    });
    return result;
  }

  ServersState copyWith({List<Server>? servers, List<ServerGroup>? groups, bool? isLoading, String? searchQuery, String? filterProtocol, String? filterCountry, bool? onlyFavorites, bool? onlyOnline, ServerSortBy? sortBy, SortOrder? sortOrder, String? testingServerId, Map<String, ServerTestResult>? testResults}) {
    return ServersState(servers: servers ?? this.servers, groups: groups ?? this.groups, isLoading: isLoading ?? this.isLoading, searchQuery: searchQuery ?? this.searchQuery, filterProtocol: filterProtocol ?? this.filterProtocol, filterCountry: filterCountry ?? this.filterCountry, onlyFavorites: onlyFavorites ?? this.onlyFavorites, onlyOnline: onlyOnline ?? this.onlyOnline, sortBy: sortBy ?? this.sortBy, sortOrder: sortOrder ?? this.sortOrder, testingServerId: testingServerId ?? this.testingServerId, testResults: testResults ?? this.testResults);
  }
}

class ServersNotifier extends StateNotifier<ServersState> {
  final ServerRepository _repository;
  final TestServer _testServer;

  ServersNotifier({required ServerRepository repository, required TestServer testServer})
      : _repository = repository, _testServer = testServer, super(const ServersState()) {
    loadServers();
  }

  Future<void> loadServers() async {
    state = state.copyWith(isLoading: true);
    print('[Servers] Loading servers from storage...');

    final serversResult = await _repository.getServers();
    List<Server> servers = [];
    if (serversResult is Success<List<Server>>) {
      servers = serversResult.data;
    }
    print('[Servers] Loaded ${servers.length} servers');

    // Тестируем пинг для серверов без пинга
    for (int i = 0; i < servers.length; i++) {
      if (servers[i].ping == null || servers[i].ping == 0) {
        final p = await PingUtils.ping(servers[i].address);
        if (p != null && p > 0) {
          servers[i] = servers[i].copyWith(ping: p);
          await _repository.updatePing(servers[i].id, p);
        }
      }
    }

    state = state.copyWith(servers: servers, isLoading: false);
  }

  void setSearchQuery(String query) => state = state.copyWith(searchQuery: query);
  void setProtocolFilter(String? protocol) => state = state.copyWith(filterProtocol: protocol);
  void toggleOnlyFavorites() => state = state.copyWith(onlyFavorites: !state.onlyFavorites);
  void toggleOnlyOnline() => state = state.copyWith(onlyOnline: !state.onlyOnline);
  void clearFilters() => state = state.copyWith(searchQuery: '', filterProtocol: null, onlyFavorites: false, onlyOnline: false);

  void setSortBy(ServerSortBy sortBy) {
    state = state.copyWith(sortBy: sortBy, sortOrder: state.sortBy == sortBy ? (state.sortOrder == SortOrder.ascending ? SortOrder.descending : SortOrder.ascending) : SortOrder.ascending);
  }

  Future<void> toggleFavorite(String serverId) async {
    final result = await _repository.toggleFavorite(serverId);
    result.when(success: (s) => state = state.copyWith(servers: state.servers.map((x) => x.id == serverId ? s : x).toList()), failure: (_) {});
  }

  Future<void> testSingleServer(String serverId) async {
    final server = state.servers.firstWhere((s) => s.id == serverId);
    state = state.copyWith(testingServerId: serverId);
    final result = await _testServer(server);
    result.when(success: (r) { final m = Map<String, ServerTestResult>.from(state.testResults); m[serverId] = r; state = state.copyWith(testingServerId: null, testResults: m); }, failure: (_) => state = state.copyWith(testingServerId: null));
  }

  Future<void> testAllServers() async {
    final result = await _testServer.testMultiple(state.servers);
    result.when(success: (results) { final m = <String, ServerTestResult>{}; for (final r in results) { m[r.serverId] = r; } state = state.copyWith(testResults: m); }, failure: (_) {});
  }
}

final serversProvider = StateNotifierProvider<ServersNotifier, ServersState>((ref) {
  return ServersNotifier(repository: sl.get<ServerRepository>(), testServer: sl.get<TestServer>());
});

final filteredServersProvider = Provider<List<Server>>((ref) {
  return ref.watch(serversProvider).filteredServers;
});