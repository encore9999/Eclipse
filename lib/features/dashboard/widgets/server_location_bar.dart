import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Плашка с информацией о текущем сервере
class ServerLocationBar extends StatelessWidget {
  final String? serverName;
  final String? country;
  final String? city;
  final String? protocol;
  final String? publicIp;

  const ServerLocationBar({
    super.key,
    this.serverName,
    this.country,
    this.city,
    this.protocol,
    this.publicIp,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? AppColors.darkCard.withOpacity(0.8) : AppColors.lightSurface,
        border: Border.all(
          color: AppColors.primary[600]!.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Флаг (упрощённый)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  AppColors.primary[500]!,
                  AppColors.primary[700]!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.public_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),

          // Информация
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  serverName ?? 'Unknown Server',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (city != null) city,
                    if (country != null) country,
                    if (protocol != null) protocol,
                  ].join(' • '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),

          // IP адрес
          if (publicIp != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.primary[600]!.withOpacity(0.1),
              ),
              child: Text(
                publicIp!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.primary[400],
                      fontWeight: FontWeight.w600,
                      fontFamily: 'JetBrainsMono',
                    ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          Icon(
            Icons.chevron_right_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}