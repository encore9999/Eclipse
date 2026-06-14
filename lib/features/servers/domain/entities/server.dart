import 'package:equatable/equatable.dart';
import '../../../../vpn_engine/domain/entities/vpn_protocol.dart';

/// Доменная сущность сервера
class Server extends Equatable {
  final String id;
  final String name;
  final String address;
  final int port;
  final VpnProtocol protocol;
  final String? country;
  final String? countryCode; // ISO 3166-1 alpha-2 (например, "US", "DE")
  final String? city;
  final String? remark;
  final int? ping; // в миллисекундах
  final bool isFavorite;
  final DateTime addedAt;
  final DateTime? lastUsedAt;
  final int usageCount;
  final String? subscriptionId; // ID подписки, из которой получен сервер

  // Настройки протокола (зависят от типа)
  final Map<String, dynamic> protocolSettings;

  const Server({
    required this.id,
    required this.name,
    required this.address,
    required this.port,
    required this.protocol,
    this.country,
    this.countryCode,
    this.city,
    this.remark,
    this.ping,
    this.isFavorite = false,
    required this.addedAt,
    this.lastUsedAt,
    this.usageCount = 0,
    this.subscriptionId,
    required this.protocolSettings,
  });

  /// Создать копию с изменениями
  Server copyWith({
    String? id,
    String? name,
    String? address,
    int? port,
    VpnProtocol? protocol,
    String? country,
    String? countryCode,
    String? city,
    String? remark,
    int? ping,
    bool? isFavorite,
    DateTime? addedAt,
    DateTime? lastUsedAt,
    int? usageCount,
    String? subscriptionId,
    Map<String, dynamic>? protocolSettings,
  }) {
    return Server(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      port: port ?? this.port,
      protocol: protocol ?? this.protocol,
      country: country ?? this.country,
      countryCode: countryCode ?? this.countryCode,
      city: city ?? this.city,
      remark: remark ?? this.remark,
      ping: ping ?? this.ping,
      isFavorite: isFavorite ?? this.isFavorite,
      addedAt: addedAt ?? this.addedAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      usageCount: usageCount ?? this.usageCount,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      protocolSettings: protocolSettings ?? this.protocolSettings,
    );
  }

  /// Отображаемое местоположение
  String get location {
    if (city != null && country != null) return '$city, $country';
    if (country != null) return country!;
    return 'Unknown';
  }

  /// Строка подключения (для отображения)
  String get connectionString => '$address:$port';

  /// Форматированный пинг
  String get formattedPing {
    if (ping == null) return 'N/A';
    if (ping! < 100) return '${ping}ms ⚡';
    if (ping! < 300) return '${ping}ms';
    return '${ping}ms 🐌';
  }

  /// UUID для VLESS/VMess/Trojan
  String? get uuid => protocolSettings['uuid'] as String?;

  /// Пароль для Shadowsocks
  String? get password => protocolSettings['password'] as String?;

  /// Приватный ключ для WireGuard
  String? get privateKey => protocolSettings['privateKey'] as String?;

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        port,
        protocol,
        country,
        city,
        ping,
        isFavorite,
        lastUsedAt,
      ];
}