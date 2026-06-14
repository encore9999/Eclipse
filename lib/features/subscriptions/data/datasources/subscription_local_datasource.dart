import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/subscription.dart';

/// Локальный источник данных для подписок
class SubscriptionLocalDataSource {
  static const String _subscriptionsBoxName = 'subscriptions';
  static const String _subscriptionSettingsBoxName = 'subscription_settings';
  
  late Box<String> _subscriptionsBox;
  late Box<String> _settingsBox;

  /// Инициализация
  Future<void> init() async {
    _subscriptionsBox = await Hive.openBox<String>(_subscriptionsBoxName);
    _settingsBox = await Hive.openBox<String>(_subscriptionSettingsBoxName);
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // CRUD подписок
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Получить все подписки
  List<Subscription> getSubscriptions() {
    return _subscriptionsBox.values.map((json) {
      return _subscriptionFromJson(json);
    }).toList();
  }

  /// Получить подписку по ID
  Subscription? getSubscriptionById(String id) {
    final json = _subscriptionsBox.get(id);
    if (json == null) return null;
    return _subscriptionFromJson(json);
  }

  /// Сохранить подписку
  Future<void> saveSubscription(Subscription subscription) async {
    final json = _subscriptionToJson(subscription);
    await _subscriptionsBox.put(subscription.id, json);
  }

  /// Удалить подписку
  Future<void> deleteSubscription(String id) async {
    await _subscriptionsBox.delete(id);
    await _settingsBox.delete('last_update_$id');
    await _settingsBox.delete('servers_count_$id');
  }

  /// Очистить все подписки
  Future<void> clearAll() async {
    await _subscriptionsBox.clear();
    await _settingsBox.clear();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Настройки подписки
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Сохранить время последнего обновления
  Future<void> saveLastUpdateTime(String subscriptionId, DateTime time) async {
    await _settingsBox.put('last_update_$subscriptionId', time.toIso8601String());
  }

  /// Получить время последнего обновления
  DateTime? getLastUpdateTime(String subscriptionId) {
    final time = _settingsBox.get('last_update_$subscriptionId');
    if (time == null) return null;
    return DateTime.tryParse(time);
  }

  /// Сохранить количество серверов в подписке
  Future<void> saveServerCount(String subscriptionId, int count) async {
    await _settingsBox.put('servers_count_$subscriptionId', count.toString());
  }

  /// Получить количество серверов
  int getServerCount(String subscriptionId) {
    final count = _settingsBox.get('servers_count_$subscriptionId');
    return int.tryParse(count ?? '0') ?? 0;
  }

  /// Получить количество подписок
  int getSubscriptionCount() => _subscriptionsBox.length;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Сериализация
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Subscription _subscriptionFromJson(String json) {
    final parts = json.split('|');
    // Простой формат хранения: id|name|url|type|status|createdAt|lastUpdate|nextUpdate|expiresAt|isAuto|interval|serverCount|errorMsg|retryCount
    return Subscription(
      id: parts[0],
      name: parts.length > 1 ? parts[1] : '',
      url: parts.length > 2 ? parts[2] : '',
      type: SubscriptionType.values.firstWhere(
        (t) => t.name == parts[3],
        orElse: () => SubscriptionType.url,
      ),
      status: SubscriptionStatus.values.firstWhere(
        (s) => s.name == parts[4],
        orElse: () => SubscriptionStatus.active,
      ),
      createdAt: parts.length > 5 ? DateTime.tryParse(parts[5]) : null,
      lastUpdate: parts.length > 6 ? DateTime.tryParse(parts[6]) : null,
      nextUpdate: parts.length > 7 ? DateTime.tryParse(parts[7]) : null,
      expiresAt: parts.length > 8 ? DateTime.tryParse(parts[8]) : null,
      isAutoUpdate: parts.length > 9 ? parts[9] == 'true' : true,
      autoUpdateInterval: parts.length > 10 
          ? Duration(hours: int.tryParse(parts[10]) ?? 6)
          : const Duration(hours: 6),
      serverCount: parts.length > 11 ? int.tryParse(parts[11]) ?? 0 : 0,
      errorMessage: parts.length > 12 ? parts[12] : null,
      updateRetryCount: parts.length > 13 ? int.tryParse(parts[13]) ?? 0 : 0,
    );
  }

  String _subscriptionToJson(Subscription sub) {
    return [
      sub.id,
      sub.name,
      sub.url,
      sub.type.name,
      sub.status.name,
      sub.createdAt?.toIso8601String() ?? '',
      sub.lastUpdate?.toIso8601String() ?? '',
      sub.nextUpdate?.toIso8601String() ?? '',
      sub.expiresAt?.toIso8601String() ?? '',
      sub.isAutoUpdate.toString(),
      sub.autoUpdateInterval.inHours.toString(),
      sub.serverCount.toString(),
      sub.errorMessage ?? '',
      sub.updateRetryCount.toString(),
    ].join('|');
  }

  /// Закрыть боксы
  Future<void> close() async {
    await _subscriptionsBox.close();
    await _settingsBox.close();
  }
}