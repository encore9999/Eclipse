import '../../../../core/utils/result.dart';
import '../entities/server.dart';
import '../repositories/server_repository.dart';

/// Use Case: Поиск серверов с фильтрацией
class SearchServers {
  final ServerRepository _repository;

  SearchServers(this._repository);

  /// Поиск серверов по запросу с дополнительными фильтрами
  Future<Result<List<Server>>> call({
    String query = '',
    String? protocol,
    String? country,
    bool? onlyFavorites,
    bool? onlyOnline,
    ServerSortBy sortBy = ServerSortBy.ping,
    SortOrder sortOrder = SortOrder.ascending,
  }) async {
    // Начинаем с базового поиска
    Result<List<Server>> result;
    
    if (query.isNotEmpty) {
      result = await _repository.searchServers(query);
    } else {
      result = await _repository.getServers();
    }

    if (result is FailureResult) return result;

    var servers = (result as Success<List<Server>>).data;

    // Применяем фильтры
    if (protocol != null) {
      servers = servers.where((s) => 
        s.protocol.name.toLowerCase() == protocol.toLowerCase()
      ).toList();
    }

    if (country != null) {
      servers = servers.where((s) => 
        s.countryCode?.toLowerCase() == country.toLowerCase() ||
        s.country?.toLowerCase() == country.toLowerCase()
      ).toList();
    }

    if (onlyFavorites == true) {
      servers = servers.where((s) => s.isFavorite).toList();
    }

    if (onlyOnline == true) {
      servers = servers.where((s) => s.ping != null).toList();
    }

    // Сортируем
    servers = _sortServers(servers, sortBy, sortOrder);

    return Result.success(servers);
  }

  /// Сортировка серверов
  List<Server> _sortServers(
    List<Server> servers,
    ServerSortBy sortBy,
    SortOrder order,
  ) {
    final sorted = List<Server>.from(servers);

    int compareFunction(Server a, Server b) {
      int result;
      
      switch (sortBy) {
        case ServerSortBy.name:
          result = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case ServerSortBy.ping:
          final aPing = a.ping ?? 9999;
          final bPing = b.ping ?? 9999;
          result = aPing.compareTo(bPing);
          break;
        case ServerSortBy.country:
          result = (a.country ?? '').compareTo(b.country ?? '');
          break;
        case ServerSortBy.protocol:
          result = a.protocol.name.compareTo(b.protocol.name);
          break;
        case ServerSortBy.lastUsed:
          final aTime = a.lastUsedAt?.millisecondsSinceEpoch ?? 0;
          final bTime = b.lastUsedAt?.millisecondsSinceEpoch ?? 0;
          result = bTime.compareTo(aTime); // Сначала недавние
          break;
        case ServerSortBy.usageCount:
          result = b.usageCount.compareTo(a.usageCount); // Сначала популярные
          break;
      }

      return order == SortOrder.ascending ? result : -result;
    }

    sorted.sort(compareFunction);
    return sorted;
  }
}

/// Поля сортировки серверов
enum ServerSortBy {
  name,
  ping,
  country,
  protocol,
  lastUsed,
  usageCount,
}

/// Порядок сортировки
enum SortOrder {
  ascending,
  descending,
}