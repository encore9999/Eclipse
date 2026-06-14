import 'dart:async';
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
  final StreamController<ConnectionStatus> _statusController = StreamController<ConnectionStatus>.broadcast();
  final StreamController<TrafficStats> _trafficController = StreamController<TrafficStats>.broadcast();
  Timer? _statsPollingTimer;
  bool _killSwitchEnabled = false;

  VpnEngineRepositoryImpl({required SingBoxApiDataSource apiDataSource, required SingBoxProcessManager processManager, required FlutterSecureStorage secureStorage})
      : _apiDataSource = apiDataSource, _processManager = processManager, _secureStorage = secureStorage {
    _processManager.stateStream.listen((s) => print('[VPN] State: $s'));
  }

  Future<void> _setProxy(bool enable) async {
    final v = enable ? '1' : '0';
    await Process.run('reg', ['add', r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings', '/v', 'ProxyEnable', '/t', 'REG_DWORD', '/d', v, '/f']);
    if (enable) await Process.run('reg', ['add', r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings', '/v', 'ProxyServer', '/t', 'REG_SZ', '/d', '127.0.0.1:2080', '/f']);
    print('[VPN] Proxy ${enable ? "ON" : "OFF"}');
  }

  String get _exeDir => Platform.resolvedExecutable.substring(0, Platform.resolvedExecutable.lastIndexOf('\\'));

  @override
  Future<void> connect(Server server) async {
    try {
      _updateStatus(ConnectionStatus.connecting(serverName: server.name, serverAddress: server.address, protocol: server.protocol.displayName));
      final config = SingBoxConfig.fromServer(server, options: const SingBoxConfigOptions(tunEnabled: true));
      final configPath = '$_exeDir\\config.json';
      await File(configPath).writeAsString(config.toJson());
      await Process.run('taskkill', ['/F', '/IM', 'sing-box.exe']);
      await Future.delayed(const Duration(milliseconds: 500));
      String binaryPath = '$_exeDir\\sing-box.exe';
      if (!File(binaryPath).existsSync()) binaryPath = '${Directory.current.path}/build/windows/sing-box.exe';
      await _processManager.start(binaryPath: binaryPath, configPath: configPath);
      await Future.delayed(const Duration(seconds: 2));
      await _setProxy(true);
      if (_killSwitchEnabled) await _enableKillSwitch();
      final pingMs = await PingUtils.ping(server.address) ?? 0;

    _updateStatus(ConnectionStatus.connected(serverId: server.id, serverName: server.name, serverAddress: server.address, protocol: server.protocol.displayName, country: server.country, city: server.city, publicIp: server.address, ping: pingMs ?? server.ping ?? 0));
      _startStatsPolling();
    } catch (e) { _updateStatus(ConnectionStatus.error(e.toString())); }
  }

  @override
  Future<void> disconnect() async { await _disableKillSwitch();
      await _setProxy(false); _stopStatsPolling(); await _processManager.stop(); _updateStatus(ConnectionStatus.disconnected()); }
  Future<void> _enableKillSwitch() async {
  await Process.run('netsh', ['advfirewall', 'firewall', 'add', 'rule', 'name=Eclipse KillSwitch', 'dir=out', 'action=block', 'protocol=any']);
  await Process.run('netsh', ['advfirewall', 'firewall', 'add', 'rule', 'name=Eclipse VPN', 'dir=out', 'action=allow', 'protocol=any', 'remoteport=2053,443,8388,51820,2080,9090']);
  print('[KillSwitch] Enabled');
}
  Future<void> _disableKillSwitch() async {
  await Process.run('netsh', ['advfirewall', 'firewall', 'delete', 'rule', 'name=Eclipse KillSwitch']);
  await Process.run('netsh', ['advfirewall', 'firewall', 'delete', 'rule', 'name=Eclipse VPN']);
  print('[KillSwitch] Disabled');
}
  void _updateStatus(ConnectionStatus s) { _currentStatus = s; if (!_statusController.isClosed) _statusController.add(s); }
  void _startStatsPolling() { _statsPollingTimer = Timer.periodic(const Duration(seconds: 2), (_) { _currentTraffic = _currentTraffic.updateSpeeds(100000, 50000); _trafficController.add(_currentTraffic); }); }
  void _stopStatsPolling() { _statsPollingTimer?.cancel(); _statsPollingTimer = null; }
  @override Stream<ConnectionStatus> get connectionStatusStream => _statusController.stream;
  @override Future<ConnectionStatus> get currentStatus async => _currentStatus;
  @override Stream<TrafficStats> get trafficStatsStream => _trafficController.stream;
  @override Future<TrafficStats> get currentTrafficStats async => _currentTraffic;
  @override Future<bool> isXrayRunning() async => _processManager.isRunning;
  @override Future<bool> testServer(Server s) async => true;
  @override Future<int?> pingServer(String h) async => PingUtils.ping(h);
  @override Future<void> reconnect() async {}
  @override Future<void> quickConnect() async {}
  @override Future<void> setKillSwitch(bool e) async { _killSwitchEnabled = e; if (e && _currentStatus.isConnected) await _enableKillSwitch(); else if (!e) await _disableKillSwitch(); }
  @override Future<void> setDnsLeakProtection(bool e) async { if (e) { await Process.run('netsh', ['interface', 'ipv4', 'set', 'dnsservers', 'name=Ethernet', 'source=static', 'address=1.1.1.1']); } else { await Process.run('netsh', ['interface', 'ipv4', 'set', 'dnsservers', 'name=Ethernet', 'source=dhcp']); } }
  @override Future<void> setIpv6Protection(bool e) async { if (e) { await Process.run('netsh', ['interface', 'ipv6', 'set', 'privacy', 'state=disabled']); } }
  @override Future<void> setSplitTunneling({List<String>? apps, List<String>? domains}) async {}
  @override Future<void> updateConfig(Map<String, dynamic> p) async {}
  @override Future<String> get configPath async => '$_exeDir\\config.json';
  @override Future<String> get binaryPath async => '$_exeDir\\sing-box.exe';
  @override Future<String> get xrayVersion async => 'sing-box';
  @override Future<void> clearLogs() async {}
  @override
  void dispose() {
    _setProxy(false);
    _stopStatsPolling();
    _processManager.stop();
    Process.run('taskkill', ['/F', '/IM', 'sing-box.exe']);
    _statusController.close();
    _trafficController.close();
  }
}