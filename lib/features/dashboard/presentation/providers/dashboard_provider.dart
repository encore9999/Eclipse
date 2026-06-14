import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/result.dart';
import '../../../../vpn_engine/domain/entities/connection_status.dart';
import '../../../../vpn_engine/domain/entities/traffic_stats.dart';
import '../../../../vpn_engine/domain/repositories/vpn_engine_repository.dart';
import '../../../../vpn_engine/domain/usecases/connect_vpn.dart';
import '../../../../features/servers/domain/entities/server.dart';
import '../../../../features/servers/presentation/providers/servers_provider.dart';
import '../../../../injection_container.dart';

class DashboardState {
  final ConnectionStatus connectionStatus;
  final TrafficStats trafficStats;
  final bool isQuickConnecting;

  const DashboardState({
    this.connectionStatus = const ConnectionStatus(),
    this.trafficStats = const TrafficStats(),
    this.isQuickConnecting = false,
  });

  bool get isConnected => connectionStatus.isConnected;
  bool get isConnecting => connectionStatus.isConnecting || isQuickConnecting;

  DashboardState copyWith({ConnectionStatus? connectionStatus, TrafficStats? trafficStats, bool? isQuickConnecting}) {
    return DashboardState(
      connectionStatus: connectionStatus ?? this.connectionStatus,
      trafficStats: trafficStats ?? this.trafficStats,
      isQuickConnecting: isQuickConnecting ?? this.isQuickConnecting,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final VpnEngineRepository _vpnRepository;
  final ConnectVpn _connectVpn;
  final Ref _ref;

  StreamSubscription<ConnectionStatus>? _statusSub;
  StreamSubscription<TrafficStats>? _trafficSub;

  DashboardNotifier({
    required VpnEngineRepository vpnRepository,
    required ConnectVpn connectVpn,
    required Ref ref,
  })  : _vpnRepository = vpnRepository,
        _connectVpn = connectVpn,
        _ref = ref,
        super(const DashboardState()) {
    _init();
  }

  void _init() {
    _statusSub = _vpnRepository.connectionStatusStream.listen((status) {
      print('[Dashboard] Status update: ${status.state}');
      state = state.copyWith(connectionStatus: status, isQuickConnecting: false);
    });
    _trafficSub = _vpnRepository.trafficStatsStream.listen((stats) {
      state = state.copyWith(trafficStats: stats);
    });
  }

  Future<void> quickConnect() async {
    print('[Dashboard] quickConnect called, isConnected: ${state.isConnected}');

    if (state.isConnected) {
      await disconnect();
      return;
    }

    state = state.copyWith(isQuickConnecting: true);

    try {
      final serversState = _ref.read(serversProvider);
      final servers = serversState.servers;

      print('[Dashboard] Servers from provider: ${servers.length}');

      if (servers.isEmpty) {
        print('[Dashboard] No servers in provider!');
        state = state.copyWith(
          isQuickConnecting: false,
          connectionStatus: ConnectionStatus.error('No servers available'),
        );
        return;
      }

      final sorted = List<Server>.from(servers);
      sorted.sort((a, b) => (a.ping ?? 9999).compareTo(b.ping ?? 9999));
      final bestServer = sorted.first;

      print('[Dashboard] Best server: ${bestServer.name}');

      print('[Dashboard] Connecting to ${bestServer.name}...');
      final result = await _connectVpn(bestServer);

      if (result is FailureResult) {
        final f = result as FailureResult;
        print('[Dashboard] Connection failed: ${f.failure.message}');
        state = state.copyWith(
          isQuickConnecting: false,
          connectionStatus: ConnectionStatus.error(f.failure.message),
        );
      } else {
        print('[Dashboard] Connection successful!');
      }
    } catch (e) {
      print('[Dashboard] Error: $e');
      state = state.copyWith(
        isQuickConnecting: false,
        connectionStatus: ConnectionStatus.error(e.toString()),
      );
    }
  }

  Future<void> disconnect() async {
    print('[Dashboard] Disconnecting...');
    await _vpnRepository.disconnect();
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _trafficSub?.cancel();
    super.dispose();
  }
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(
    vpnRepository: sl.get<VpnEngineRepository>(),
    connectVpn: sl.get<ConnectVpn>(),
    ref: ref,
  );
});

final connectionDurationProvider = StreamProvider<String>((ref) {
  final dashboard = ref.watch(dashboardProvider);
  final connectedSince = dashboard.connectionStatus.connectedSince;
  if (connectedSince == null) return Stream.value('00:00:00');
  return Stream.periodic(const Duration(seconds: 1), (_) {
    final duration = DateTime.now().difference(connectedSince);
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  });
});