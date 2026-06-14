import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../vpn_engine/domain/entities/traffic_stats.dart';
import '../../../../vpn_engine/domain/repositories/vpn_engine_repository.dart';
import '../../../../injection_container.dart';

/// Состояние экрана статистики
class StatisticsState {
  final TrafficStats currentStats;
  final int totalDownloadToday;
  final int totalUploadToday;
  final int totalDownloadMonth;
  final int totalUploadMonth;
  final int totalDownloadAll;
  final int totalUploadAll;
  final List<TrafficSnapshot> speedHistory;
  final bool isLoading;

  const StatisticsState({
    this.currentStats = const TrafficStats(),
    this.totalDownloadToday = 0,
    this.totalUploadToday = 0,
    this.totalDownloadMonth = 0,
    this.totalUploadMonth = 0,
    this.totalDownloadAll = 0,
    this.totalUploadAll = 0,
    this.speedHistory = const [],
    this.isLoading = true,
  });

  int get totalToday => totalDownloadToday + totalUploadToday;
  int get totalMonth => totalDownloadMonth + totalUploadMonth;
  int get totalAll => totalDownloadAll + totalUploadAll;

  StatisticsState copyWith({
    TrafficStats? currentStats,
    int? totalDownloadToday,
    int? totalUploadToday,
    int? totalDownloadMonth,
    int? totalUploadMonth,
    int? totalDownloadAll,
    int? totalUploadAll,
    List<TrafficSnapshot>? speedHistory,
    bool? isLoading,
  }) {
    return StatisticsState(
      currentStats: currentStats ?? this.currentStats,
      totalDownloadToday: totalDownloadToday ?? this.totalDownloadToday,
      totalUploadToday: totalUploadToday ?? this.totalUploadToday,
      totalDownloadMonth: totalDownloadMonth ?? this.totalDownloadMonth,
      totalUploadMonth: totalUploadMonth ?? this.totalUploadMonth,
      totalDownloadAll: totalDownloadAll ?? this.totalDownloadAll,
      totalUploadAll: totalUploadAll ?? this.totalUploadAll,
      speedHistory: speedHistory ?? this.speedHistory,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Провайдер статистики
class StatisticsNotifier extends StateNotifier<StatisticsState> {
  final VpnEngineRepository _vpnRepository;
  StreamSubscription<TrafficStats>? _statsSub;

  StatisticsNotifier({required VpnEngineRepository vpnRepository})
      : _vpnRepository = vpnRepository,
        super(const StatisticsState()) {
    _init();
  }

  void _init() {
    _statsSub = _vpnRepository.trafficStatsStream.listen((stats) {
      state = state.copyWith(
        currentStats: stats,
        speedHistory: stats.history,
        totalDownloadToday: state.totalDownloadToday + (stats.downloadSpeed * 2),
        totalUploadToday: state.totalUploadToday + (stats.uploadSpeed * 2),
        isLoading: false,
      );
    });
  }

  /// Сбросить дневную статистику
  void resetToday() {
    state = state.copyWith(totalDownloadToday: 0, totalUploadToday: 0);
  }

  @override
  void dispose() {
    _statsSub?.cancel();
    super.dispose();
  }
}

// ━━━━━━━ Провайдеры ━━━━━━━

final statisticsProvider = StateNotifierProvider<StatisticsNotifier, StatisticsState>((ref) {
  return StatisticsNotifier(vpnRepository: sl.get<VpnEngineRepository>());
});