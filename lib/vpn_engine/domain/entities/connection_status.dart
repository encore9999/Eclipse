import 'package:equatable/equatable.dart';

/// Статус VPN-подключения
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  disconnecting,
  error,
}

/// Полная информация о текущем состоянии VPN-соединения
class ConnectionStatus extends Equatable {
  final ConnectionState state;
  final String? serverId;
  final String? serverName;
  final String? serverAddress;
  final String? protocol;
  final String? country;
  final String? city;
  final DateTime? connectedSince;
  final Duration? connectionDuration;
  final int? ping;
  final String? publicIp;
  final String? errorMessage;
  final bool killSwitchEnabled;
  final bool dnsLeakProtected;
  final bool ipv6Protected;

  const ConnectionStatus({
    this.state = ConnectionState.disconnected,
    this.serverId,
    this.serverName,
    this.serverAddress,
    this.protocol,
    this.country,
    this.city,
    this.connectedSince,
    this.connectionDuration,
    this.ping,
    this.publicIp,
    this.errorMessage,
    this.killSwitchEnabled = false,
    this.dnsLeakProtected = false,
    this.ipv6Protected = false,
  });

  /// Создаёт статус "отключено"
  factory ConnectionStatus.disconnected() => const ConnectionStatus(
        state: ConnectionState.disconnected,
      );

  /// Создаёт статус "подключение"
  factory ConnectionStatus.connecting({
    String? serverName,
    String? serverAddress,
    String? protocol,
  }) =>
      ConnectionStatus(
        state: ConnectionState.connecting,
        serverName: serverName,
        serverAddress: serverAddress,
        protocol: protocol,
      );

  /// Создаёт статус "подключено"
  factory ConnectionStatus.connected({
    required String serverId,
    required String serverName,
    required String serverAddress,
    required String protocol,
    String? country,
    String? city,
    String? publicIp,
    int? ping,
  }) =>
      ConnectionStatus(
        state: ConnectionState.connected,
        serverId: serverId,
        serverName: serverName,
        serverAddress: serverAddress,
        protocol: protocol,
        country: country,
        city: city,
        publicIp: publicIp,
        ping: ping,
        connectedSince: DateTime.now(),
        connectionDuration: Duration.zero,
      );

  /// Создаёт статус "ошибка"
  factory ConnectionStatus.error(String message) => ConnectionStatus(
        state: ConnectionState.error,
        errorMessage: message,
      );

  // ━━━━━━━ Удобные геттеры ━━━━━━━

  bool get isConnected => state == ConnectionState.connected;
  bool get isConnecting => state == ConnectionState.connecting;
  bool get isDisconnected => state == ConnectionState.disconnected;
  bool get isReconnecting => state == ConnectionState.reconnecting;
  bool get isError => state == ConnectionState.error;
  bool get isActive => isConnected || isConnecting || isReconnecting;

  /// Обновляет длительность соединения
  ConnectionStatus updateDuration(Duration duration) {
    return copyWith(connectionDuration: duration);
  }

  /// Обновляет пинг
  ConnectionStatus updatePing(int ping) {
    return copyWith(ping: ping);
  }

  /// Обновляет публичный IP
  ConnectionStatus updatePublicIp(String ip) {
    return copyWith(publicIp: ip);
  }

  /// Копирование с изменением полей
  ConnectionStatus copyWith({
    ConnectionState? state,
    String? serverId,
    String? serverName,
    String? serverAddress,
    String? protocol,
    String? country,
    String? city,
    DateTime? connectedSince,
    Duration? connectionDuration,
    int? ping,
    String? publicIp,
    String? errorMessage,
    bool? killSwitchEnabled,
    bool? dnsLeakProtected,
    bool? ipv6Protected,
  }) {
    return ConnectionStatus(
      state: state ?? this.state,
      serverId: serverId ?? this.serverId,
      serverName: serverName ?? this.serverName,
      serverAddress: serverAddress ?? this.serverAddress,
      protocol: protocol ?? this.protocol,
      country: country ?? this.country,
      city: city ?? this.city,
      connectedSince: connectedSince ?? this.connectedSince,
      connectionDuration: connectionDuration ?? this.connectionDuration,
      ping: ping ?? this.ping,
      publicIp: publicIp ?? this.publicIp,
      errorMessage: errorMessage ?? this.errorMessage,
      killSwitchEnabled: killSwitchEnabled ?? this.killSwitchEnabled,
      dnsLeakProtected: dnsLeakProtected ?? this.dnsLeakProtected,
      ipv6Protected: ipv6Protected ?? this.ipv6Protected,
    );
  }

  @override
  List<Object?> get props => [
        state,
        serverId,
        serverName,
        serverAddress,
        protocol,
        country,
        city,
        connectedSince,
        connectionDuration,
        ping,
        publicIp,
        errorMessage,
        killSwitchEnabled,
        dnsLeakProtected,
        ipv6Protected,
      ];
}