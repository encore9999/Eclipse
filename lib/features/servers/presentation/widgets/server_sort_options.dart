import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/usecases/search_servers.dart';

class ServerSortOptions extends StatelessWidget {
  final ServerSortBy currentSort;
  final SortOrder currentOrder;
  final ValueChanged<ServerSortBy> onChanged;

  const ServerSortOptions({super.key, required this.currentSort, required this.currentOrder, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return PopupMenuButton<ServerSortBy>(
      onSelected: onChanged,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: colorScheme.surfaceVariant.withOpacity(0.5)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort_rounded, size: 16, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(_sortLabel(currentSort), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
            Icon(currentOrder == SortOrder.ascending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 14, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
      itemBuilder: (context) => ServerSortBy.values.map((sortBy) {
        final isSelected = currentSort == sortBy;
        return PopupMenuItem<ServerSortBy>(
          value: sortBy,
          child: Row(
            children: [
              Icon(_sortIcon(sortBy), size: 18, color: isSelected ? AppColors.primary[400] : colorScheme.onSurfaceVariant),
              const SizedBox(width: 10),
              Text(_sortLabel(sortBy), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: isSelected ? AppColors.primary[400] : colorScheme.onSurface, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
              if (isSelected) ...[const Spacer(), Icon(Icons.check_rounded, size: 18, color: AppColors.primary[400])],
            ],
          ),
        );
      }).toList(),
    );
  }

  String _sortLabel(ServerSortBy s) => switch (s) {
    ServerSortBy.name => 'Name', ServerSortBy.ping => 'Ping', ServerSortBy.country => 'Country',
    ServerSortBy.protocol => 'Protocol', ServerSortBy.lastUsed => 'Last Used', ServerSortBy.usageCount => 'Popular'
  };

  IconData _sortIcon(ServerSortBy s) => switch (s) {
    ServerSortBy.name => Icons.sort_by_alpha_rounded, ServerSortBy.ping => Icons.speed_rounded,
    ServerSortBy.country => Icons.public_rounded, ServerSortBy.protocol => Icons.layers_rounded,
    ServerSortBy.lastUsed => Icons.schedule_rounded, ServerSortBy.usageCount => Icons.trending_up_rounded
  };
}