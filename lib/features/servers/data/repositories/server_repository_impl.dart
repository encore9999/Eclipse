import 'dart:math';
import '../../../../core/utils/result.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/server.dart';
import '../../domain/entities/server_group.dart';
import '../../domain/repositories/server_repository.dart';
import '../datasources/server_local_datasource.dart';
import '../models/server_model.dart';

/// Реализация репозитория серверов
class ServerRepositoryImpl implements ServerRepository {
  final ServerLocalDataSource _localDataSource;

  ServerRepositoryImpl({required ServerLocalDataSource localDataSource})
      : _localDataSource = localDataSource;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // CRUD
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  @override
  Future<Result<List<Server>>> getServers() async {
    try {
      final models = _localDataSource.getServers();
      final servers = models.map((m) => m.toEntity()).toList();
      return Result.success(servers);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to get servers: $e'),
      );
    }
  }

  @override
  Future<Result<Server>> getServerById(String id) async {
    try {
      final model = _localDataSource.getServerById(id);
      if (model == null) {
        return Result.failure(
          Failure(message: 'Server not found: $id', code: 'SERVER_NOT_FOUND'),
        );
      }
      return Result.success(model.toEntity());
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to get server: $e'),
      );
    }
  }

  @override
  Future<Result<Server>> addServer(Server server) async {
    try {
      final model = ServerModel.fromEntity(server);
      await _localDataSource.saveServer(model);
      return Result.success(server);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to add server: $e'),
      );
    }
  }

  @override
  Future<Result<Server>> updateServer(Server server) async {
    try {
      final model = ServerModel.fromEntity(server);
      await _localDataSource.saveServer(model);
      return Result.success(server);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to update server: $e'),
      );
    }
  }

  @override
  Future<Result<void>> deleteServer(String id) async {
    try {
      await _localDataSource.deleteServer(id);
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to delete server: $e'),
      );
    }
  }

  @override
  Future<Result<void>> deleteServers(List<String> ids) async {
    try {
      for (final id in ids) {
        await _localDataSource.deleteServer(id);
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to delete servers: $e'),
      );
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Избранное и статус
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  @override
  Future<Result<Server>> toggleFavorite(String id) async {
    try {
      final model = _localDataSource.getServerById(id);
      if (model == null) {
        return Result.failure(
          Failure(message: 'Server not found: $id', code: 'SERVER_NOT_FOUND'),
        );
      }

      final isFav = _localDataSource.isFavorite(id);
      if (isFav) {
        await _localDataSource.addToFavorites(id); // Уже там, но на всякий случай
      } else {
        // Тоггл: если в избранном — убираем, если нет — добавляем
      }

      final updatedModel = model.copyWith(isFavorite: !model.isFavorite);
      await _localDataSource.saveServer(updatedModel);
      
      if (!model.isFavorite) {
        await _localDataSource.addToFavorites(id);
      }

      return Result.success(updatedModel.toEntity());
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to toggle favorite: $e'),
      );
    }
  }

  @override
  Future<Result<Server>> updatePing(String id, int? ping) async {
    try {
      final model = _localDataSource.getServerById(id);
      if (model == null) {
        return Result.failure(
          Failure(message: 'Server not found: $id'),
        );
      }

      final updatedModel = model.copyWith(ping: ping);
      await _localDataSource.saveServer(updatedModel);
      return Result.success(updatedModel.toEntity());
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to update ping: $e'),
      );
    }
  }

  @override
  Future<Result<void>> markAsUsed(String id) async {
    try {
      final model = _localDataSource.getServerById(id);
      if (model != null) {
        final updatedModel = model.copyWith(
          lastUsedAt: DateTime.now(),
          usageCount: model.usageCount + 1,
        );
        await _localDataSource.saveServer(updatedModel);
        await _localDataSource.addToRecent(id);
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to mark as used: $e'),
      );
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Поиск и фильтрация
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  @override
  Future<Result<Server>> getBestServer() async {
    try {
      final servers = _localDataSource.getServers();
      if (servers.isEmpty) {
        return Result.failure(
          const Failure(message: 'No servers available', code: 'NO_SERVERS'),
        );
      }

      // Сортируем: избранные → пинг → частота использования
      servers.sort((a, b) {
        if (a.isFavorite && !b.isFavorite) return -1;
        if (!a.isFavorite && b.isFavorite) return 1;
        
        final aPing = a.ping ?? 9999;
        final bPing = b.ping ?? 9999;
        if (aPing != bPing) return aPing.compareTo(bPing);
        
        return b.usageCount.compareTo(a.usageCount);
      });

      return Result.success(servers.first.toEntity());
    } catch (e) {
      return Result.failure(
        Failure(message: 'Failed to get best server: $e'),
      );
    }
  }

  @override
  Future<Result<List<Server>>> searchServers(String query) async {
    try {
      final servers = _localDataSource.getServers();
      final lowerQuery = query.toLowerCase();

      final filtered = servers.where((s) {
        return s.name.toLowerCase().contains(lowerQuery) ||
            s.address.toLowerCase().contains(lowerQuery) ||
            (s.country?.toLowerCase().contains(lowerQuery) ?? false) ||
            (s.city?.toLowerCase().contains(lowerQuery) ?? false) ||
            (s.remark?.toLowerCase().contains(lowerQuery) ?? false) ||
            s.protocol.toLowerCase().contains(lowerQuery);
      }).toList();

      return Result.success(filtered.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Result.failure(
        Failure(message: 'Search failed: $e'),
      );
    }
  }

  @override
  Future<Result<List<Server>>> getServersByProtocol(String protocol) async {
    final servers = _localDataSource.getServers()
        .where((s) => s.protocol.toLowerCase() == protocol.toLowerCase())
        .map((m) => m.toEntity())
        .toList();
    return Result.success(servers);
  }

  @override
  Future<Result<List<Server>>> getServersByCountry(String countryCode) async {
    final servers = _localDataSource.getServers()
        .where((s) => s.countryCode?.toLowerCase() == countryCode.toLowerCase())
        .map((m) => m.toEntity())
        .toList();
    return Result.success(servers);
  }

  @override
  Future<Result<List<Server>>> getServersBySubscription(String subscriptionId) async {
    final servers = _localDataSource
        .getServersBySubscription(subscriptionId)
        .map((m) => m.toEntity())
        .toList();
    return Result.success(servers);
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Группы
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  @override
  Future<Result<List<ServerGroup>>> getGroups() async {
    try {
      return Result.success(_localDataSource.getGroups());
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to get groups: $e'),
      );
    }
  }

  @override
  Future<Result<ServerGroup>> createGroup(ServerGroup group) async {
    try {
      await _localDataSource.saveGroup(group);
      return Result.success(group);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to create group: $e'),
      );
    }
  }

  @override
  Future<Result<ServerGroup>> updateGroup(ServerGroup group) async {
    try {
      await _localDataSource.saveGroup(group);
      return Result.success(group);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to update group: $e'),
      );
    }
  }

  @override
  Future<Result<void>> deleteGroup(String id) async {
    try {
      await _localDataSource.deleteGroup(id);
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to delete group: $e'),
      );
    }
  }

  @override
  Future<Result<void>> addServerToGroup(String serverId, String groupId) async {
    try {
      final groups = _localDataSource.getGroups();
      final groupIndex = groups.indexWhere((g) => g.id == groupId);
      if (groupIndex == -1) {
        return Result.failure(
          Failure(message: 'Group not found: $groupId'),
        );
      }

      final group = groups[groupIndex];
      if (!group.serverIds.contains(serverId)) {
        final updatedIds = List<String>.from(group.serverIds)..add(serverId);
        final updatedGroup = group.copyWith(serverIds: updatedIds);
        await _localDataSource.saveGroup(updatedGroup);
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to add server to group: $e'),
      );
    }
  }

  @override
  Future<Result<void>> removeServerFromGroup(String serverId, String groupId) async {
    try {
      final groups = _localDataSource.getGroups();
      final groupIndex = groups.indexWhere((g) => g.id == groupId);
      if (groupIndex == -1) {
        return Result.failure(
          Failure(message: 'Group not found: $groupId'),
        );
      }

      final group = groups[groupIndex];
      final updatedIds = List<String>.from(group.serverIds)..remove(serverId);
      final updatedGroup = group.copyWith(serverIds: updatedIds);
      await _localDataSource.saveGroup(updatedGroup);

      return Result.success(null);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to remove server from group: $e'),
      );
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Импорт/Экспорт
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  @override
  Future<Result<int>> importServers(List<Server> servers) async {
    try {
      final models = servers.map((s) => ServerModel.fromEntity(s)).toList();
      await _localDataSource.saveServers(models);
      return Result.success(servers.length);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to import servers: $e'),
      );
    }
  }

  @override
  Future<Result<String>> exportServerAsLink(String id) async {
    try {
      final model = _localDataSource.getServerById(id);
      if (model == null) {
        return Result.failure(
          Failure(message: 'Server not found: $id'),
        );
      }

      // Формируем конфигурационную ссылку
      final protocol = model.protocol;
      final address = model.address;
      final port = model.port;
      final remark = model.remark ?? model.name;
      
      // Базовый формат: protocol://uuid@address:port?params#remark
      final uuid = model.protocolSettings['uuid'] ?? '';
      final params = model.protocolSettings.entries
          .where((e) => e.key != 'uuid')
          .map((e) => '${e.key}=${e.value}')
          .join('&');
      
      final link = '$protocol://$uuid@$address:$port?$params#$remark';
      return Result.success(link);
    } catch (e) {
      return Result.failure(
        Failure(message: 'Failed to export server: $e'),
      );
    }
  }

  @override
  Future<Result<void>> clearAll() async {
    try {
      await _localDataSource.clearAll();
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to clear servers: $e'),
      );
    }
  }

  @override
  Future<Result<int>> getServerCount() async {
    try {
      return Result.success(_localDataSource.getServerCount());
    } catch (e) {
      return Result.success(0);
    }
  }
}