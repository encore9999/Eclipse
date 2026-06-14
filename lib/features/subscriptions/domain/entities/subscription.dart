import 'package:equatable/equatable.dart';

/// Тип подписки
enum SubscriptionType {
  url,    // Прямая ссылка
  base64, // Base64 закодированная
  json,   // JSON формат (Clash)
}

/// Статус подписки
enum SubscriptionStatus {
  active,   // Активна и обновляется
  updating, // В процессе обновления
  error,    // Ошибка при обновлении
  expired,  // Истекла
  paused,   // Приостановлена
}

/// Доменная сущность подписки
class Subscription extends Equatable {
  final String id;
  final String name;
  final String url;
  final SubscriptionType type;
  final SubscriptionStatus status;
  final DateTime? createdAt;
  final DateTime? lastUpdate;
  final DateTime? nextUpdate;
  final DateTime? expiresAt;
  final bool isAutoUpdate;
  final Duration autoUpdateInterval;
  final int serverCount;
  final String? errorMessage;
  final int updateRetryCount;
  final Map<String, dynamic>? headers; // Кастомные заголовки для запроса

  const Subscription({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    this.status = SubscriptionStatus.active,
    this.createdAt,
    this.lastUpdate,
    this.nextUpdate,
    this.expiresAt,
    this.isAutoUpdate = true,
    this.autoUpdateInterval = const Duration(hours: 6),
    this.serverCount = 0,
    this.errorMessage,
    this.updateRetryCount = 0,
    this.headers,
  });

  Subscription copyWith({
    String? id,
    String? name,
    String? url,
    SubscriptionType? type,
    SubscriptionStatus? status,
    DateTime? createdAt,
    DateTime? lastUpdate,
    DateTime? nextUpdate,
    DateTime? expiresAt,
    bool? isAutoUpdate,
    Duration? autoUpdateInterval,
    int? serverCount,
    String? errorMessage,
    int? updateRetryCount,
    Map<String, dynamic>? headers,
  }) {
    return Subscription(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      nextUpdate: nextUpdate ?? this.nextUpdate,
      expiresAt: expiresAt ?? this.expiresAt,
      isAutoUpdate: isAutoUpdate ?? this.isAutoUpdate,
      autoUpdateInterval: autoUpdateInterval ?? this.autoUpdateInterval,
      serverCount: serverCount ?? this.serverCount,
      errorMessage: errorMessage ?? this.errorMessage,
      updateRetryCount: updateRetryCount ?? this.updateRetryCount,
      headers: headers ?? this.headers,
    );
  }

  /// Форматированное время последнего обновления
  String get formattedLastUpdate {
    if (lastUpdate == null) return 'Never';
    final diff = DateTime.now().difference(lastUpdate!);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  /// Форматированное время до следующего обновления
  String get formattedNextUpdate {
    if (nextUpdate == null) return 'N/A';
    final diff = nextUpdate!.difference(DateTime.now());
    if (diff.inMinutes < 0) return 'Overdue';
    if (diff.inMinutes < 60) return 'in ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'in ${diff.inHours}h';
    return 'in ${diff.inDays}d';
  }

  /// Активна ли подписка
  bool get isActive => status == SubscriptionStatus.active || status == SubscriptionStatus.updating;

  /// Требует ли обновления
  bool get needsUpdate {
    if (!isAutoUpdate) return false;
    if (nextUpdate == null) return true;
    return DateTime.now().isAfter(nextUpdate!);
  }

  /// Достигнут ли лимит повторных попыток
  bool get maxRetriesReached => updateRetryCount >= 3;

  /// Сколько серверов в подписке
  String get formattedServerCount => '$serverCount servers';

  @override
  List<Object?> get props => [
        id,
        name,
        url,
        type,
        status,
        lastUpdate,
        nextUpdate,
        expiresAt,
        isAutoUpdate,
        serverCount,
      ];
}