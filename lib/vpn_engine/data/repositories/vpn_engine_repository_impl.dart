import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/repositories/vpn_engine_repository.dart';
import '../../domain/entities/connection_status.dart';
import '../../domain/entities/traffic_stats.dart';
import '../datasources/singbox_api_datasource.dart';
import '../datasources/singbox_process_manager.dart';
import '../models/singbox_config.dart';
import '../../../../features/servers/domain/entities/server.dart';
import '../../../../core/utils/ping_utils.dart';

class VpnEngineRepositoryImpl implements VpnEngineRepository {
  final SingBoxApiDataSource _apiDataSource;
  final SingBoxProcessManager _processManager;
  final FlutterSecureStorage _secureStorage;

  ConnectionStatus _currentStatus = ConnectionStatus.disconnected();
  TrafficStats _currentTraffic = TrafficStats.zero();
  final StreamController<ConnectionStatus> _statusController =
      StreamController<ConnectionStatus>.broadcast();
  final StreamController<TrafficStats> _trafficController =
      StreamController<TrafficStats>.broadcast();
  Timer? _statsPollingTimer;

  bool _killSwitchEnabled = false;
  bool _dnsProtection = false;
  bool _ipv6Protection = false;

  VpnEngineRepositoryImpl({
    required SingBoxApiDataSource apiDataSource,
    required SingBoxProcessManager processManager,
    required FlutterSecureStorage secureStorage,
  })  : _apiDataSource = apiDataSource,
        _processManager = processManager,
        _secureStorage = secureStorage {
    _processManager.stateStream.listen((s) => print('[VPN] State: $s'));
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    _killSwitchEnabled = await _secureStorage.read(key: 'kill_switch') == 'true';
    _dnsProtection = await _secureStorage.read(key: 'dns_protection') == 'true';
    _ipv6Protection = await _secureStorage.read(key: 'ipv6_protection') == 'true';
  }

  String _findSingBox() {
    final exeDir = Platform.resolvedExecutable.substring(
        0, Platform.resolvedExecutable.lastIndexOf('\\'));
    final localPath = '$exeDir\\sing-box.exe';
    if (File(localPath).existsSync()) return localPath;

    final devPath = '${Directory.current.path}\\build\\windows\\sing-box.exe';
    if (File(devPath).existsSync()) return devPath;

    const installPath = r'C:\Program Files (x86)\Eclipse\sing-box.exe';
    if (File(installPath).existsSync()) return installPath;

    return localPath;
  }

  Future<void> _setProxy(bool enable) async {
    final v = enable ? '1' : '0';
    await Process.run('reg', [
      'add', r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
      '/v', 'ProxyEnable', '/t', 'REG_DWORD', '/d', v, '/f'
    ]);
    if (enable) {
      await Process.run('reg', [
        'add', r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
        '/v', 'ProxyServer', '/t', 'REG_SZ', '/d', '127.0.0.1:2080', '/f'
      ]);
    }
    print('[VPN] Proxy ${enable ? "ON" : "OFF"}');
  }

  // ── Kill Switch ──
  Future<void> _enableKillSwitch() async {
    await Process.run('netsh', [
      'advfirewall', 'firewall', 'add', 'rule',
      'name=Eclipse_KS', 'dir=out', 'action=block', 'protocol=any'
    ]);
    await Process.run('netsh', [
      'advfirewall', 'firewall', 'add', 'rule',
      'name=Eclipse_VPN', 'dir=out', 'action=allow', 'protocol=any',
      'remoteport=2053,443,8388,51820,2080,9090'
    ]);
    print('[KillSwitch] ON');
  }

  Future<void> _disableKillSwitch() async {
    await Process.run('netsh', [
      'advfirewall', 'firewall', 'delete', 'rule', 'name=Eclipse_KS'
    ]);
    await Process.run('netsh', [
      'advfirewall', 'firewall', 'delete', 'rule', 'name=Eclipse_VPN'
    ]);
    print('[KillSwitch] OFF');
  }

  // ── DNS Protection ──
  Future<void> _applyDns() async {
    for (final iface in ['Ethernet', 'Wi-Fi', 'Ethernet0']) {
      await Process.run('netsh', [
        'interface', 'ipv4', 'set', 'dnsservers', iface, 'static', '1.1.1.1'
      ]);
      await Process.run('netsh', [
        'interface', 'ipv4', 'add', 'dnsservers', iface, '1.0.0.1'
      ]);
    }
    print('[DNS] Protection ON');
  }

  Future<void> _revertDns() async {
    for (final iface in ['Ethernet', 'Wi-Fi', 'Ethernet0']) {
      await Process.run('netsh', [
        'interface', 'ipv4', 'set', 'dnsservers', iface, 'dhcp'
      ]);
    }
    print('[DNS] Protection OFF');
  }

  // ── IPv6 Protection ──
  Future<void> _blockIpv6() async {
    await Process.run('netsh', ['interface', 'teredo', 'set', 'state', 'disabled']);
    await Process.run('netsh', ['interface', '6to4', 'set', 'state', 'disabled']);
    final psCmd = r'Get-NetAdapterBinding -ComponentID ms_tcpip6 | Where-Object {$_.Name -ne "Loopback"} | Disable-NetAdapterBinding -ComponentID ms_tcpip6 -PassThru';
    await Process.run('powershell', ['-Command', psCmd]);
    print('[IPv6] Protection ON');
  }

  Future<void> _unblockIpv6() async {
    await Process.run('netsh', ['interface', 'teredo', 'set', 'state', 'default']);
    await Process.run('netsh', ['interface', '6to4', 'set', 'state', 'default']);
    final psCmd = r'Get-NetAdapterBinding -ComponentID ms_tcpip6 | Where-Object {$_.Name -ne "Loopback"} | Enable-NetAdapterBinding -ComponentID ms_tcpip6 -PassThru';
    await Process.run('powershell', ['-Command', psCmd]);
    print('[IPv6] Protection OFF');
  }

  @override
  Future<void> setKillSwitch(bool e) async {
    _killSwitchEnabled = e;
    await _secureStorage.write(key: 'kill_switch', value: e.toString());
    if (_currentStatus.isConnected) {
      e ? await _enableKillSwitch() : await _disableKillSwitch();
    }
  }

  @override
  Future<void> setDnsLeakProtection(bool e) async {
    _dnsProtection = e;
    await _secureStorage.write(key: 'dns_protection', value: e.toString());
    if (_currentStatus.isConnected) {
      e ? await _applyDns() : await _revertDns();
    }
  }

  @override
  Future<void> setIpv6Protection(bool e) async {
    _ipv6Protection = e;
    await _secureStorage.write(key: 'ipv6_protection', value: e.toString());
    if (_currentStatus.isConnected) {
      e ? await _blockIpv6() : await _unblockIpv6();
    }
  }

  String get _exeDir => Platform.resolvedExecutable.substring(0, Platform.resolvedExecutable.lastIndexOf('\\'));

  /// Проверка прав администратора
  Future<bool> _isAdmin() async {
    try {
      final result = await Process.run('net', ['session']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Ждём, пока порт 2080 перестанет слушаться (LISTENING)
  Future<void> _waitForPortFree() async {
    for (int i = 0; i < 10; i++) {
      final check = await Process.run('cmd', ['/c', 'netstat -ano | findstr LISTENING | findstr :2080']);
      if (check.stdout.toString().trim().isEmpty) {
        print('[VPN] Port 2080 is free');
        return;
      }
      print('[VPN] Waiting for port 2080...');
      await Future.delayed(const Duration(milliseconds: 500));
    }
    print('[VPN] Warning: port 2080 may still be occupied, trying anyway');
  }

  @override
  Future<void> connect(Server server) async {
    try {
      _updateStatus(ConnectionStatus.connecting(
          serverName: server.name, serverAddress: server.address,
          protocol: server.protocol.displayName));

      // Проверяем права админа и решаем, включать ли TUN
      final isAdmin = await _isAdmin();
      final tunEnabled = isAdmin;   // TUN только если есть права
      if (!isAdmin) {
        print('[VPN] Not running as admin – TUN will be disabled');
      }

      final config = SingBoxConfig.fromServer(server,
          options: SingBoxConfigOptions(tunEnabled: tunEnabled));
      final configPath = '$_exeDir\\config.json';
      await File(configPath).writeAsString(config.toJson());

      // Убиваем старый процесс и активно ждём освобождения порта
      await Process.run('taskkill', ['/F', '/IM', 'sing-box.exe']);
      await _waitForPortFree();

      final binaryPath = _findSingBox();
      print('[VPN] Launching: $binaryPath run -c $configPath');

      final process = await Process.start(
        binaryPath,
        ['run', '-c', configPath],
        environment: {
          ...Platform.environment,
          'ENABLE_DEPRECATED_LEGACY_DNS_SERVERS': 'true',
          'ENABLE_DEPRECATED_OUTBOUND_DNS_RULE_ITEM': 'true',
          'ENABLE_DEPRECATED_MISSING_DOMAIN_RESOLVER': 'true',
        },
      );

      process.stdout.transform(utf8.decoder).listen((data) {
        print('[sing-box] $data');
      });
      process.stderr.transform(utf8.decoder).listen((data) {
        print('[sing-box ERR] $data');
      });

      // Ждём 3 секунды и проверяем, жив ли процесс
      await Future.delayed(const Duration(seconds: 3));
      final alive = await process.exitCode.timeout(
        const Duration(milliseconds: 500),
        onTimeout: () => -1,
      );
      if (alive != -1) {
        print('[VPN] sing-box exited with code $alive');
        throw Exception('sing-box failed to start (exit code $alive)');
      }

      print('[VPN] sing-box appears to be running');
      await _setProxy(true);

      final pingMs = await PingUtils.ping(server.address);
      _updateStatus(ConnectionStatus.connected(
        serverId: server.id, serverName: server.name,
        serverAddress: server.address, protocol: server.protocol.displayName,
        country: server.country, city: server.city,
        publicIp: server.address, ping: pingMs ?? 0,
      ));
      _startStatsPolling();
    } catch (e) {
      print('[VPN] Error: $e');
      _updateStatus(ConnectionStatus.error(e.toString()));
    }
  }

  @override
  Future<void> disconnect() async {
    if (_killSwitchEnabled) await _disableKillSwitch();
    if (_dnsProtection) await _revertDns();
    if (_ipv6Protection) await _unblockIpv6();
    await _setProxy(false);
    _stopStatsPolling();
    await _processManager.stop();
    await Process.run('taskkill', ['/F', '/IM', 'sing-box.exe']);
    _updateStatus(ConnectionStatus.disconnected());
  }

  void _updateStatus(ConnectionStatus s) {
    _currentStatus = s;
    if (!_statusController.isClosed) _statusController.add(s);
  }

  void _startStatsPolling() {
    _statsPollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _currentTraffic = _currentTraffic.updateSpeeds(100000, 50000);
      _trafficController.add(_currentTraffic);
    });
  }

  void _stopStatsPolling() {
    _statsPollingTimer?.cancel();
    _statsPollingTimer = null;
  }

  @override
  Stream<ConnectionStatus> get connectionStatusStream => _statusController.stream;
  @override
  Future<ConnectionStatus> get currentStatus async => _currentStatus;
  @override
  Stream<TrafficStats> get trafficStatsStream => _trafficController.stream;
  @override
  Future<TrafficStats> get currentTrafficStats async => _currentTraffic;
  @override
  Future<bool> isXrayRunning() async => _processManager.isRunning;
  @override
  Future<bool> testServer(Server s) async => true;
  @override
  Future<int?> pingServer(String h) async => PingUtils.ping(h);
  @override
  Future<void> reconnect() async {}
  @override
  Future<void> quickConnect() async {}
  @override
  Future<void> setSplitTunneling({List<String>? apps, List<String>? domains}) async {}
  @override
  Future<void> updateConfig(Map<String, dynamic> p) async {}
  @override
  Future<String> get configPath async => '$_exeDir\\config.json';
  @override
  Future<String> get binaryPath async => _findSingBox();
  @override
  Future<String> get xrayVersion async => 'sing-box';
  @override
  Future<void> clearLogs() async {}
  @override
  void dispose() {
    if (_killSwitchEnabled) _disableKillSwitch();
    if (_dnsProtection) _revertDns();
    if (_ipv6Protection) _unblockIpv6();
    _setProxy(false);
    _stopStatsPolling();
    _statusController.close();
    _trafficController.close();
  }
}