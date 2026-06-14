import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Карточка с информацией о соединении (длительность, трафик, пинг, IP)
class ConnectionInfoCard extends StatelessWidget {
  final String duration;
  final String totalTraffic;
  final int? ping;
  final String? publicIp;

  const ConnectionInfoCard({
    super.key,
    required this.duration,
    required this.totalTraffic,
    this.ping,
    this.publicIp,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        border: Border.all(
          color: isDark ? AppColors.darkDivider : Colors.transparent,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildInfoTile(
                context,
                icon: Icons.timer_outlined,
                label: 'Duration',
                value: duration,
              ),
              _buildDivider(context),
              _buildInfoTile(
                context,
                icon: Icons.data_usage_outlined,
                label: 'Traffic',
                value: totalTraffic,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoTile(
                context,
                icon: Icons.speed_outlined,
                label: 'Ping',
                value: ping != null ? '$ping ms' : 'N/A',
                valueColor: _pingColor(ping),
              ),
              _buildDivider(context),
              _buildInfoTile(
                context,
                icon: Icons.language_outlined,
                label: 'Public IP',
                value: publicIp ?? 'N/A',
                isMono: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isMono = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.primary[400]),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                  fontFamily: isMono ? 'JetBrainsMono' : null,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 50,
      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
    );
  }

  Color _pingColor(int? ping) {
    if (ping == null) return Colors.grey;
    if (ping < 50) return AppColors.connected;
    if (ping < 150) return AppColors.connecting;
    if (ping < 300) return AppColors.warning;
    return AppColors.error;
  }
}