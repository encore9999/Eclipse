import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../vpn_engine/domain/entities/traffic_stats.dart';

/// Виджет отображения скорости с графиком
class SpeedDisplay extends StatelessWidget {
  final int downloadSpeed;
  final int uploadSpeed;
  final List<TrafficSnapshot> history;

  const SpeedDisplay({
    super.key,
    required this.downloadSpeed,
    required this.uploadSpeed,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        border: Border.all(
          color: isDark ? AppColors.darkDivider : Colors.transparent,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Заголовок
          Row(
            children: [
              Icon(Icons.speed_rounded, color: AppColors.primary[400], size: 20),
              const SizedBox(width: 8),
              Text(
                'Real-time Speed',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Текущие скорости
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSpeedItem(
                context,
                icon: Icons.arrow_downward_rounded,
                label: 'Download',
                speed: downloadSpeed,
                color: AppColors.primary[400]!,
              ),
              Container(
                width: 1,
                height: 40,
                color: colorScheme.outline.withOpacity(0.3),
              ),
              _buildSpeedItem(
                context,
                icon: Icons.arrow_upward_rounded,
                label: 'Upload',
                speed: uploadSpeed,
                color: AppColors.secondary[400]!,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // График
          SizedBox(
            height: 100,
            child: _buildChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int speed,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              _formatSpeed(speed),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 1,
              ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    if (history.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final spots = history.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        (entry.value.downloadSpeed / 1024 / 1024).toDouble(),
      );
    }).toList();

    // Берём последние 60 точек
    final displaySpots = spots.length > 60
        ? spots.sublist(spots.length - 60)
        : spots;

    return LineChart(
      LineChartData(
        minY: 0,
        gridData: FlGridData(
          show: false,
        ),
        titlesData: FlTitlesData(
          show: false,
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: displaySpots,
            isCurved: true,
            color: AppColors.primary[400]!,
            barWidth: 2,
            isStrokeCapRound: true,
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
        ],
      ),
      duration: const Duration(milliseconds: 300),
    );
  }

  String _formatSpeed(int bytesPerSecond) {
    if (bytesPerSecond < 1024) return '$bytesPerSecond B/s';
    if (bytesPerSecond < 1024 * 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }
}