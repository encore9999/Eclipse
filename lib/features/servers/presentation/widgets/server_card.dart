import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/server.dart';
import '../../domain/usecases/test_server.dart';
import 'server_test_result_widget.dart';

class ServerCard extends StatelessWidget {
  final Server server;
  final bool isTesting;
  final ServerTestResult? testResult;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onTest;

  const ServerCard({
    super.key,
    required this.server,
    this.isTesting = false,
    this.testResult,
    required this.onTap,
    required this.onFavorite,
    required this.onTest,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final protocolColor = AppColors.getProtocolColor(server.protocol.name);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? AppColors.darkCard : AppColors.lightSurface,
          border: Border.all(
            color: server.isFavorite
                ? AppColors.primary[500]!.withOpacity(0.3)
                : (isDark ? AppColors.darkDivider : Colors.transparent),
            width: server.isFavorite ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    protocolColor.withOpacity(0.8),
                    protocolColor.withOpacity(0.4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  server.protocol.displayName.substring(0, 1),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          server.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: onFavorite,
                        child: Icon(
                          server.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 20,
                          color: server.isFavorite ? AppColors.warning : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(server.location, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: protocolColor.withOpacity(0.15),
                        ),
                        child: Text(server.protocol.displayName,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: protocolColor, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ServerTestResultWidget(ping: server.ping, isTesting: isTesting, testResult: testResult, onTest: onTest),
          ],
        ),
      ),
    );
  }
}