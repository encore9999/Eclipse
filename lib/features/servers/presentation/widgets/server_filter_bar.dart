import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../vpn_engine/domain/entities/vpn_protocol.dart';
import '../providers/servers_provider.dart';

/// Панель фильтров серверов
class ServerFilterBar extends ConsumerWidget {
  const ServerFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(serversProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Все
          _FilterChip(
            label: 'All',
            isSelected: state.filterProtocol == null &&
                state.filterCountry == null &&
                !state.onlyFavorites &&
                !state.onlyOnline,
            onTap: () {
              ref.read(serversProvider.notifier).clearFilters();
            },
          ),
          const SizedBox(width: 8),

          // Избранное
          _FilterChip(
            label: '⭐ Favorites',
            isSelected: state.onlyFavorites,
            onTap: () {
              ref.read(serversProvider.notifier).toggleOnlyFavorites();
            },
          ),
          const SizedBox(width: 8),

          // Онлайн
          _FilterChip(
            label: '🟢 Online',
            isSelected: state.onlyOnline,
            onTap: () {
              ref.read(serversProvider.notifier).toggleOnlyOnline();
            },
          ),
          const SizedBox(width: 8),

          // Протоколы
          ...VpnProtocol.values.map((protocol) {
            final isSelected = state.filterProtocol == protocol.name;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: protocol.displayName,
                isSelected: isSelected,
                color: AppColors.getProtocolColor(protocol.name),
                onTap: () {
                  ref.read(serversProvider.notifier).setProtocolFilter(
                        isSelected ? null : protocol.name,
                      );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipColor = color ?? AppColors.primary[500]!;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? chipColor.withOpacity(isDark ? 0.25 : 0.15)
              : (isDark ? AppColors.darkCard : AppColors.lightSurfaceVariant),
          border: Border.all(
            color: isSelected ? chipColor.withOpacity(0.5) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? chipColor
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
      ),
    );
  }
}