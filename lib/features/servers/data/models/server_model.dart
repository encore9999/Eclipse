import 'dart:convert';
import '../../domain/entities/server.dart';
import '../../../../vpn_engine/domain/entities/vpn_protocol.dart';

/// Модель сервера для работы с данными (JSON/Hive)
class ServerModel {
  final String id;
  final String name;
  final String address;
  final int port;
  final String protocol;
  final String? country;
  final String? countryCode;
  final String? city;
  final String? remark;
  final int? ping;
  final bool isFavorite;
  final DateTime addedAt;
  final DateTime? lastUsedAt;
  final int usageCount;
  final String? subscriptionId;
  final Map<String, dynamic> protocolSettings;

  const ServerModel({
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

  ServerModel copyWith({
    String? id,
    String? name,
    String? address,
    int? port,
    String? protocol,
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
    return ServerModel(
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

  /// Из Entity в Model
  factory ServerModel.fromEntity(Server server) {
    return ServerModel(
      id: server.id,
      name: server.name,
      address: server.address,
      port: server.port,
      protocol: server.protocol.name,
      country: server.country,
      countryCode: server.countryCode,
      city: server.city,
      remark: server.remark,
      ping: server.ping,
      isFavorite: server.isFavorite,
      addedAt: server.addedAt,
      lastUsedAt: server.lastUsedAt,
      usageCount: server.usageCount,
      subscriptionId: server.subscriptionId,
      protocolSettings: server.protocolSettings,
    );
  }

  /// Из Model в Entity
  Server toEntity() {
    return Server(
      id: id,
      name: name,
      address: address,
      port: port,
      protocol: VpnProtocol.values.firstWhere(
        (p) => p.name == protocol,
        orElse: () => VpnProtocol.vless,
      ),
      country: country,
      countryCode: countryCode,
      city: city,
      remark: remark,
      ping: ping,
      isFavorite: isFavorite,
      addedAt: addedAt,
      lastUsedAt: lastUsedAt,
      usageCount: usageCount,
      subscriptionId: subscriptionId,
      protocolSettings: Map<String, dynamic>.from(protocolSettings),
    );
  }

  /// Из JSON
  factory ServerModel.fromJson(Map<String, dynamic> json) {
    return ServerModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      address: json['address'] as String? ?? '',
      port: json['port'] as int? ?? 0,
      protocol: json['protocol'] as String? ?? 'vless',
      country: json['country'] as String?,
      countryCode: json['countryCode'] as String?,
      city: json['city'] as String?,
      remark: json['remark'] as String?,
      ping: json['ping'] as int?,
      isFavorite: json['isFavorite'] as bool? ?? false,
      addedAt: json['addedAt'] != null
          ? DateTime.tryParse(json['addedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.tryParse(json['lastUsedAt'] as String)
          : null,
      usageCount: json['usageCount'] as int? ?? 0,
      subscriptionId: json['subscriptionId'] as String?,
      protocolSettings: json['protocolSettings'] as Map<String, dynamic>? ?? {},
    );
  }

  /// В JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'port': port,
      'protocol': protocol,
      'country': country,
      'countryCode': countryCode,
      'city': city,
      'remark': remark,
      'ping': ping,
      'isFavorite': isFavorite,
      'addedAt': addedAt.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
      'usageCount': usageCount,
      'subscriptionId': subscriptionId,
      'protocolSettings': protocolSettings,
    };
  }

  /// Из конфигурационной ссылки
  factory ServerModel.fromShareLink(String link) {
    final uri = Uri.parse(link);
    final protocol = VpnProtocol.fromScheme(uri.scheme);
    if (protocol == null) throw FormatException('Unknown protocol: ${uri.scheme}');

    return ServerModel(
      id: link.hashCode.toString(),
      name: uri.fragment.isNotEmpty ? uri.fragment : uri.host,
      address: uri.host,
      port: uri.port,
      protocol: protocol.name,
      remark: uri.fragment.isNotEmpty ? uri.fragment : null,
      addedAt: DateTime.now(),
      protocolSettings: {
        ...uri.queryParameters,
        'uuid': uri.userInfo.isNotEmpty ? uri.userInfo : null,
      },
    );
  }
}