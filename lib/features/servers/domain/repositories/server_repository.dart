import '../../../../core/utils/result.dart';
import '../entities/server.dart';
import '../entities/server_group.dart';

/// Интерфейс репозитория серверов
abstract class ServerRepository {
  /// Получить все серверы
  Future<Result<List<Server>>> getServers();

  /// Получить сервер по ID
  Future<Result<Server>> getServerById(String id);

  /// Добавить сервер
  Future<Result<Server>> addServer(Server server);

  /// Обновить сервер
  Future<Result<Server>> updateServer(Server server);

  /// Удалить сервер
  Future<Result<void>> deleteServer(String id);

  /// Удалить несколько серверов
  Future<Result<void>> deleteServers(List<String> ids);

  /// Добавить/убрать из избранного
  Future<Result<Server>> toggleFavorite(String id);

  /// Обновить пинг для сервера
  Future<Result<Server>> updatePing(String id, int? ping);

  /// Отметить сервер как использованный
  Future<Result<void>> markAsUsed(String id);

  /// Получить лучший сервер (по пингу)
  Future<Result<Server>> getBestServer();

  /// Поиск серверов
  Future<Result<List<Server>>> searchServers(String query);

  /// Получить серверы по протоколу
  Future<Result<List<Server>>> getServersByProtocol(String protocol);

  /// Получить серверы по стране
  Future<Result<List<Server>>> getServersByCountry(String countryCode);

  /// Получить серверы из подписки
  Future<Result<List<Server>>> getServersBySubscription(String subscriptionId);

  // ━━━━━━━ Группы ━━━━━━━

  /// Получить все группы
  Future<Result<List<ServerGroup>>> getGroups();

  /// Создать группу
  Future<Result<ServerGroup>> createGroup(ServerGroup group);

  /// Обновить группу
  Future<Result<ServerGroup>> updateGroup(ServerGroup group);

  /// Удалить группу
  Future<Result<void>> deleteGroup(String id);

  /// Добавить сервер в группу
  Future<Result<void>> addServerToGroup(String serverId, String groupId);

  /// Удалить сервер из группы
  Future<Result<void>> removeServerFromGroup(String serverId, String groupId);

  // ━━━━━━━ Импорт/Экспорт ━━━━━━━

  /// Импортировать серверы из списка
  Future<Result<int>> importServers(List<Server> servers);

  /// Экспортировать серверы в конфигурационную ссылку
  Future<Result<String>> exportServerAsLink(String id);

  /// Очистить все серверы
  Future<Result<void>> clearAll();

  /// Получить общее количество серверов
  Future<Result<int>> getServerCount();
}