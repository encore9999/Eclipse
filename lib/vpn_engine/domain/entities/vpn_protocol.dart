/// Поддерживаемые VPN-протоколы
enum VpnProtocol {
  vless,
  vmess,
  trojan,
  shadowsocks,
  hysteria2,
  tuic,
  wireguard;

  /// Человекочитаемое название
  String get displayName {
    switch (this) {
      case VpnProtocol.vless: return 'VLESS';
      case VpnProtocol.vmess: return 'VMess';
      case VpnProtocol.trojan: return 'Trojan';
      case VpnProtocol.shadowsocks: return 'Shadowsocks';
      case VpnProtocol.hysteria2: return 'Hysteria 2';
      case VpnProtocol.tuic: return 'TUIC';
      case VpnProtocol.wireguard: return 'WireGuard';
    }
  }

  /// Схема для URI ссылок
  String get scheme {
    switch (this) {
      case VpnProtocol.vless: return 'vless';
      case VpnProtocol.vmess: return 'vmess';
      case VpnProtocol.trojan: return 'trojan';
      case VpnProtocol.shadowsocks: return 'ss';
      case VpnProtocol.hysteria2: return 'hysteria2';
      case VpnProtocol.tuic: return 'tuic';
      case VpnProtocol.wireguard: return 'wireguard';
    }
  }

  /// Порт по умолчанию
  int get defaultPort {
    switch (this) {
      case VpnProtocol.vless: return 443;
      case VpnProtocol.vmess: return 443;
      case VpnProtocol.trojan: return 443;
      case VpnProtocol.shadowsocks: return 8388;
      case VpnProtocol.hysteria2: return 443;
      case VpnProtocol.tuic: return 443;
      case VpnProtocol.wireguard: return 51820;
    }
  }

  /// Поддерживает ли протокол multiplexing
  bool get supportsMultiplexing {
    switch (this) {
      case VpnProtocol.vless:
      case VpnProtocol.vmess:
      case VpnProtocol.trojan:
        return true;
      default:
        return false;
    }
  }

  /// Поддерживает ли протокол UDP
  bool get supportsUdp {
    switch (this) {
      case VpnProtocol.shadowsocks:
      case VpnProtocol.hysteria2:
      case VpnProtocol.tuic:
      case VpnProtocol.wireguard:
        return true;
      default:
        return false;
    }
  }

  /// Создать из строки (схемы)
  static VpnProtocol? fromScheme(String scheme) {
    final clean = scheme.toLowerCase().replaceAll('://', '');
    switch (clean) {
      case 'vless': return VpnProtocol.vless;
      case 'vmess': return VpnProtocol.vmess;
      case 'trojan': return VpnProtocol.trojan;
      case 'ss':
      case 'shadowsocks': return VpnProtocol.shadowsocks;
      case 'hysteria2':
      case 'hysteria': return VpnProtocol.hysteria2;
      case 'tuic': return VpnProtocol.tuic;
      case 'wireguard': return VpnProtocol.wireguard;
      default: return null;
    }
  }

  /// Поддерживаемые типы транспорта для каждого протокола
  List<String> get supportedTransports {
    switch (this) {
      case VpnProtocol.vless:
        return ['tcp', 'ws', 'grpc', 'httpupgrade', 'splithttp'];
      case VpnProtocol.vmess:
        return ['tcp', 'ws', 'grpc', 'httpupgrade'];
      case VpnProtocol.trojan:
        return ['tcp', 'ws', 'grpc'];
      case VpnProtocol.shadowsocks:
        return ['tcp', 'udp'];
      case VpnProtocol.hysteria2:
        return ['udp'];
      case VpnProtocol.tuic:
        return ['udp'];
      case VpnProtocol.wireguard:
        return ['udp'];
    }
  }

  /// Поддерживаемые типы шифрования для каждого протокола
  List<String> get supportedSecurity {
    switch (this) {
      case VpnProtocol.vless:
        return ['none', 'tls', 'reality', 'xtls'];
      case VpnProtocol.vmess:
        return ['auto', 'aes-128-gcm', 'chacha20-poly1305', 'none'];
      case VpnProtocol.trojan:
        return ['tls'];
      case VpnProtocol.shadowsocks:
        return ['aes-256-gcm', 'chacha20-ietf-poly1305', '2022-blake3-aes-256-gcm'];
      case VpnProtocol.hysteria2:
        return ['tls'];
      case VpnProtocol.tuic:
        return ['tls'];
      case VpnProtocol.wireguard:
        return ['noise'];
    }
  }
}