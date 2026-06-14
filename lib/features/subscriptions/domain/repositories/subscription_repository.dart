import '../../../../core/utils/result.dart';
import '../entities/subscription.dart';
import '../../../servers/domain/entities/server.dart';

/// Интерфейс репозитория подписок
abstract class SubscriptionRepository {
  /// Получить все подписки
  Future<Result<List<Subscription>>> getSubscriptions();

  /// Получить подписку по ID
  Future<Result<Subscription>> getSubscriptionById(String id);

  /// Добавить новую подписку
  Future<Result<Subscription>> addSubscription({
    required String name,
    required String url,
    SubscriptionType? type,
    Map<String, dynamic>? headers,
  });

  /// Обновить подписку (получить новые серверы)
  Future<Result<Subscription>> updateSubscription(String id);

  /// Обновить все подписки
  Future<Result<List<Subscription>>> updateAllSubscriptions();

  /// Удалить подписку и все её серверы
  Future<Result<void>> deleteSubscription(String id);

  /// Включить/выключить автообновление
  Future<Result<Subscription>> toggleAutoUpdate(String id);

  /// Изменить интервал автообновления
  Future<Result<Subscription>> setUpdateInterval(String id, Duration interval);

  /// Приостановить подписку
  Future<Result<Subscription>> pauseSubscription(String id);

  /// Возобновить подписку
  Future<Result<Subscription>> resumeSubscription(String id);

  /// Переименовать подписку
  Future<Result<Subscription>> renameSubscription(String id, String newName);

  /// Получить серверы, принадлежащие подписке
  Future<Result<List<Server>>> getSubscriptionServers(String subscriptionId);

  /// Проверить валидность URL подписки
  Future<Result<bool>> validateSubscriptionUrl(String url);

  /// Определить тип подписки по содержимому
  Future<Result<SubscriptionType>> detectSubscriptionType(String url);

  /// Получить статистику по подписке
  Future<Result<SubscriptionStats>> getSubscriptionStats(String id);

  /// Экспортировать подписку в конфигурационную ссылку
  Future<Result<String>> exportSubscription(String id);
}

/// Статистика подписки
class SubscriptionStats {
  final int totalServers;
  final int onlineServers;
  final int offlineServers;
  final double averagePing;
  final int totalTraffic;

  const SubscriptionStats({
    required this.totalServers,
    required this.onlineServers,
    required this.offlineServers,
    required this.averagePing,
    required this.totalTraffic,
  });
}