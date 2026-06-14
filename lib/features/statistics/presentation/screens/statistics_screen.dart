import 'package:easy_localization/easy_localization.dart';
import '../../../../vpn_engine/domain/entities/traffic_stats.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/statistics_provider.dart';

/// Экран статистики трафика
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(statisticsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark ? AppColors.backgroundGradient : [const Color(0xFFF8F7FF), const Color(0xFFF0EEFF)],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                title: Text(
                  'statistics'.tr(),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () {
                      ref.read(statisticsProvider.notifier).resetToday();
                    },
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Текущая скорость
                    _CurrentSpeedCard(stats: state.currentStats),
                    const SizedBox(height: 20),

                    // График скорости
                    _SpeedChart(history: state.speedHistory),
                    const SizedBox(height: 20),

                    // Статистика по периодам
                    _PeriodStats(
                      label: 'Today',
                      download: state.totalDownloadToday,
                      upload: state.totalUploadToday,
                    ),
                    const SizedBox(height: 12),
                    _PeriodStats(
                      label: 'This Month',
                      download: state.totalDownloadMonth,
                      upload: state.totalUploadMonth,
                    ),
                    const SizedBox(height: 12),
                    _PeriodStats(
                      label: 'All Time',
                      download: state.totalDownloadAll,
                      upload: state.totalUploadAll,
                    ),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Карточка текущей скорости
class _CurrentSpeedCard extends StatelessWidget {
  final TrafficStats stats;

  const _CurrentSpeedCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: AppColors.connectedGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SpeedItem(
            icon: Icons.arrow_downward_rounded,
            label: 'Download',
            speed: stats.formattedDownloadSpeed,
          ),
          Container(
            width: 1,
            height: 48,
            color: Colors.white.withOpacity(0.2),
          ),
          _SpeedItem(
            icon: Icons.arrow_upward_rounded,
            label: 'Upload',
            speed: stats.formattedUploadSpeed,
          ),
        ],
      ),
    );
  }
}

class _SpeedItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String speed;

  const _SpeedItem({required this.icon, required this.label, required this.speed});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          speed,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
        ),
      ],
    );
  }
}

/// График скорости
class _SpeedChart extends StatelessWidget {
  final List<TrafficSnapshot> history;

  const _SpeedChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Speed History',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: history.isEmpty
                ? Center(
                    child: Text(
                      'No data yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  )
                : _buildChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final downloadSpots = <FlSpot>[];
    final uploadSpots = <FlSpot>[];

    final displayData = history.length > 60 ? history.sublist(history.length - 60) : history;

    for (var i = 0; i < displayData.length; i++) {
      final mbDown = displayData[i].downloadSpeed / 1024 / 1024;
      final mbUp = displayData[i].uploadSpeed / 1024 / 1024;
      downloadSpots.add(FlSpot(i.toDouble(), mbDown));
      uploadSpots.add(FlSpot(i.toDouble(), mbUp));
    }

    return LineChart(
      LineChartData(
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.darkDivider.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: false,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toStringAsFixed(0)} MB/s',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: downloadSpots,
            isCurved: true,
            color: AppColors.primary[400]!,
            barWidth: 2,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary[400]!.withOpacity(0.3),
                  AppColors.primary[400]!.withOpacity(0.0),
                ],
              ),
            ),
          ),
          LineChartBarData(
            spots: uploadSpots,
            isCurved: true,
            color: AppColors.secondary[400]!,
            barWidth: 2,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.secondary[400]!.withOpacity(0.3),
                  AppColors.secondary[400]!.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 300),
    );
  }
}

/// Статистика за период
class _PeriodStats extends StatelessWidget {
  final String label;
  final int download;
  final int upload;

  const _PeriodStats({
    required this.label,
    required this.download,
    required this.upload,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(Icons.arrow_downward_rounded, size: 14, color: AppColors.connected),
                  const SizedBox(width: 4),
                  Text(
                    _formatBytes(download),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.arrow_upward_rounded, size: 14, color: AppColors.warning),
                  const SizedBox(width: 4),
                  Text(
                    _formatBytes(upload),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}