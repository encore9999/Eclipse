import 'dart:convert';
import '../../../../features/servers/domain/entities/server.dart';
import '../../../../vpn_engine/domain/entities/vpn_protocol.dart';

class SingBoxConfig {
  final Map<String, dynamic> _config;

  SingBoxConfig._(this._config);

  factory SingBoxConfig.fromServer(Server server, {SingBoxConfigOptions? options}) {
    final opts = options ?? const SingBoxConfigOptions();

    return SingBoxConfig._({
      'log': {
        'level': opts.logLevel,
        'timestamp': true,
      },
      'dns': _buildDns(opts),
      'inbounds': _buildInbounds(opts),
      'outbounds': [
        _buildMainOutbound(server, opts),
        _buildDirectOutbound(),
      ],
      'route': _buildRoute(opts),
      'experimental': {
        'clash_api': {
          'external_controller': '127.0.0.1:9090',
          'external_ui': '',
          if (opts.apiSecret != null) 'secret': opts.apiSecret,
        },
        'cache_file': {
          'enabled': false,
          'path': 'cache.db',
        },
      },
    });
  }

  String toJson() => const JsonEncoder.withIndent('  ').convert(_config);
  Map<String, dynamic> toMap() => Map<String, dynamic>.from(_config);

  // Новый формат DNS для sing-box 1.12+
  static Map<String, dynamic> _buildDns(SingBoxConfigOptions opts) {
    return {
      'servers': [
        {
          'tag': 'dns-remote',
          'address': 'tls://1.1.1.1',
          'strategy': 'prefer_ipv4',
        },
        {
          'tag': 'dns-local',
          'address': 'https://dns.alidns.com/dns-query',
          'strategy': 'prefer_ipv4',
          'detour': 'direct',
        },
      ],
      'rules': [
        {
          'domain_suffix': ['cn'],
          'server': 'dns-local',
        },
        {
          'outbound': ['direct', 'bypass'],
          'server': 'dns-local',
        },
      ],
      'final': 'dns-remote',
    };
  }

  static List<Map<String, dynamic>> _buildInbounds(SingBoxConfigOptions opts) {
    final inbounds = <Map<String, dynamic>>[
      {
        'type': 'mixed',
        'tag': 'mixed-in',
        'listen': opts.listenAddress,
        'listen_port': opts.mixedPort,
      },
    ];

    // TUN режим
    if (opts.tunEnabled) {
      inbounds.add({
        'type': 'tun',
        'tag': 'tun-in',
        'address': ['172.19.0.1/30', 'fdfe:dcba:9876::1/126'],
        'auto_route': true,
        'strict_route': false,
        'stack': 'mixed',
      });
    }

    return inbounds;
  }

  static Map<String, dynamic> _buildMainOutbound(Server server, SingBoxConfigOptions opts) {
    final base = <String, dynamic>{
      'tag': 'proxy',
      'server': server.address,
      'server_port': server.port,
    };

    switch (server.protocol) {
      case VpnProtocol.vless:
        return _buildVLESS(base, server);
      case VpnProtocol.vmess:
        return _buildVMess(base, server);
      case VpnProtocol.trojan:
        return _buildTrojan(base, server);
      case VpnProtocol.shadowsocks:
        return _buildShadowsocks(base, server);
      case VpnProtocol.hysteria2:
        return _buildHysteria2(base, server);
      case VpnProtocol.tuic:
        return _buildTuic(base, server);
      case VpnProtocol.wireguard:
        return _buildWireGuard(base, server);
    }
  }

  static Map<String, dynamic> _buildVLESS(Map<String, dynamic> base, Server server) {
    final settings = server.protocolSettings;
    return {
      'type': 'vless',
      ...base,
      'uuid': settings['uuid'],
      'flow': settings['flow'] ?? '',
      'tls': _buildTls(settings),
      'transport': _buildTransport(settings),
      'packet_encoding': 'xudp',
    };
  }

  static Map<String, dynamic> _buildVMess(Map<String, dynamic> base, Server server) {
    final settings = server.protocolSettings;
    return {
      'type': 'vmess',
      ...base,
      'uuid': settings['uuid'],
      'security': settings['security'] ?? 'auto',
      'alter_id': settings['alterId'] ?? 0,
      'tls': _buildTls(settings),
      'transport': _buildTransport(settings),
    };
  }

  static Map<String, dynamic> _buildTrojan(Map<String, dynamic> base, Server server) {
    final settings = server.protocolSettings;
    return {
      'type': 'trojan',
      ...base,
      'password': settings['password'] ?? settings['uuid'] ?? '',
      'tls': _buildTls(settings),
      'transport': _buildTransport(settings),
    };
  }

  static Map<String, dynamic> _buildShadowsocks(Map<String, dynamic> base, Server server) {
    final settings = server.protocolSettings;
    return {
      'type': 'shadowsocks',
      ...base,
      'method': settings['method'] ?? '2022-blake3-aes-256-gcm',
      'password': settings['password'],
    };
  }

  static Map<String, dynamic> _buildHysteria2(Map<String, dynamic> base, Server server) {
    final settings = server.protocolSettings;
    return {
      'type': 'hysteria2',
      ...base,
      'password': settings['password'],
      'up_mbps': int.tryParse(settings['up']?.toString() ?? '100') ?? 100,
      'down_mbps': int.tryParse(settings['down']?.toString() ?? '200') ?? 200,
      'tls': {
        'enabled': true,
        'server_name': settings['sni'] ?? server.address,
        'insecure': settings['allowInsecure'] ?? false,
      },
    };
  }

  static Map<String, dynamic> _buildTuic(Map<String, dynamic> base, Server server) {
    final settings = server.protocolSettings;
    return {
      'type': 'tuic',
      ...base,
      'uuid': settings['uuid'],
      'password': settings['password'],
      'congestion_control': settings['congestion'] ?? 'bbr',
      'tls': {
        'enabled': true,
        'server_name': settings['sni'] ?? server.address,
        'insecure': settings['allowInsecure'] ?? false,
      },
    };
  }

  static Map<String, dynamic> _buildWireGuard(Map<String, dynamic> base, Server server) {
    final settings = server.protocolSettings;
    return {
      'type': 'wireguard',
      ...base,
      'private_key': settings['privateKey'],
      'peers': [
        {
          'public_key': settings['publicKey'],
          'pre_shared_key': settings['preSharedKey'],
          'allowed_ips': settings['allowedIPs'] ?? ['0.0.0.0/0'],
        }
      ],
      'mtu': settings['mtu'] ?? 1420,
    };
  }

  static Map<String, dynamic>? _buildTls(Map<String, dynamic> settings) {
    final security = settings['security'] as String?;
    if (security == null || security == 'none') return null;

    final tls = <String, dynamic>{
      'enabled': true,
      'server_name': settings['sni'] ?? '',
      'insecure': settings['allowInsecure'] ?? false,
    };

    if (security == 'reality') {
      final pbk = (settings['pbk'] ?? settings['publicKey'] ?? '') as String;
      final sid = (settings['sid'] ?? settings['shortId'] ?? '') as String;
      if (pbk.isNotEmpty) {
        tls['reality'] = {
          'enabled': true,
          'public_key': pbk,
          'short_id': sid,
        };
      }
    }

    tls['utls'] = {
      'enabled': true,
      'fingerprint': settings['fingerprint'] ?? 'chrome',
    };

    return tls;
  }

  static Map<String, dynamic>? _buildTransport(Map<String, dynamic> settings) {
    final network = settings['network'] as String? ?? 'tcp';
    if (network == 'tcp') return null;

    final transport = <String, dynamic>{'type': network};

    if (network == 'ws') {
      transport['path'] = settings['path'] ?? '/';
      transport['headers'] = {'Host': settings['host'] ?? ''};
    } else if (network == 'grpc') {
      transport['service_name'] = settings['serviceName'] ?? '';
    }

    return transport;
  }

  static Map<String, dynamic> _buildDirectOutbound() => {'type': 'direct', 'tag': 'direct'};

  static Map<String, dynamic> _buildRoute(SingBoxConfigOptions opts) {
    return {
      'rules': [
        {'inbound': 'mixed-in', 'action': 'sniff'},
        if (opts.tunEnabled) {'inbound': 'tun-in', 'action': 'sniff'},
        {'ip_is_private': true, 'outbound': 'direct'},
      ],
      'final': 'proxy',
      'auto_detect_interface': true,
    };
  }
}

class SingBoxConfigOptions {
  final String logLevel;
  final String listenAddress;
  final int mixedPort;
  final bool mixedEnabled;
  final bool tunEnabled;
  final bool systemProxy;
  final bool fakeDns;
  final String? apiSecret;

  const SingBoxConfigOptions({
    this.logLevel = 'warn',
    this.listenAddress = '127.0.0.1',
    this.mixedPort = 2080,
    this.mixedEnabled = true,
    this.tunEnabled = false,
    this.systemProxy = false,
    this.fakeDns = false,
    this.apiSecret,
  });
}