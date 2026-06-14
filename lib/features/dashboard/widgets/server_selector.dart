import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/servers/presentation/providers/servers_provider.dart';
import '../../../features/servers/domain/entities/server.dart';

class ServerSelector extends ConsumerWidget {
  final String? currentServer;
  final Function(Server)? onServerSelected;

  const ServerSelector({super.key, this.currentServer, this.onServerSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final servers = ref.watch(filteredServersProvider);

    return GestureDetector(
      onTap: () => _showServerPicker(context, servers),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? AppColors.darkCard.withOpacity(0.6) : AppColors.lightSurface,
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(children: [
          Icon(Icons.dns_outlined, color: AppColors.primary[400], size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(
            currentServer ?? 'Select server...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
            overflow: TextOverflow.ellipsis,
          )),
          Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ]),
      ),
    );
  }

  void _showServerPicker(BuildContext context, List<Server> servers) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: 400,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: Colors.grey[400]),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Select Server', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ),
            Expanded(
              child: servers.isEmpty
                  ? Center(child: Text('No servers available', style: Theme.of(context).textTheme.bodyMedium))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: servers.length,
                      itemBuilder: (context, index) {
                        final server = servers[index];
                        final isSelected = server.name == currentServer;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.pop(ctx);
                                onServerSelected?.call(server);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36, height: 36,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: AppColors.getProtocolColor(server.protocol.name).withOpacity(0.2),
                                      ),
                                      child: Center(
                                        child: Text(
                                          server.protocol.displayName[0],
                                          style: TextStyle(color: AppColors.getProtocolColor(server.protocol.name), fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(server.name, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                          Text('${server.location} • ${server.formattedPing}', style: Theme.of(context).textTheme.labelSmall),
                                        ],
                                      ),
                                    ),
                                    if (isSelected) Icon(Icons.check_circle, color: AppColors.primary[400]),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}