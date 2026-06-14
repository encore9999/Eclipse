import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/server_group.dart';

class ServerGroupHeader extends StatefulWidget {
  final ServerGroup group;
  final int serverCount;
  const ServerGroupHeader({super.key, required this.group, required this.serverCount});
  @override
  State<ServerGroupHeader> createState() => _ServerGroupHeaderState();
}

class _ServerGroupHeaderState extends State<ServerGroupHeader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _arrowAnimation;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.group.isExpanded;
    _controller = AnimationController(duration: const Duration(milliseconds: 250), vsync: this, value: _isExpanded ? 1.0 : 0.0);
    _arrowAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  void _toggle() {
    setState(() { _isExpanded = !_isExpanded; _isExpanded ? _controller.forward() : _controller.reverse(); });
  }

  Color _getGroupColor() => switch (widget.group.type) {
    GroupType.subscription => AppColors.primary[400]!, GroupType.country => AppColors.secondary[400]!,
    GroupType.protocol => AppColors.vlessColor, GroupType.favorites => AppColors.warning,
    GroupType.recent => AppColors.connected, GroupType.custom => AppColors.tuicColor
  };

  IconData _getGroupIcon() => switch (widget.group.type) {
    GroupType.subscription => Icons.rss_feed_rounded, GroupType.country => Icons.flag_rounded,
    GroupType.protocol => Icons.layers_rounded, GroupType.favorites => Icons.star_rounded,
    GroupType.recent => Icons.history_rounded, GroupType.custom => Icons.folder_rounded
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: _toggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: _getGroupColor().withOpacity(isDark ? 0.2 : 0.1)), child: Icon(_getGroupIcon(), size: 16, color: _getGroupColor())),
          const SizedBox(width: 10),
          Expanded(child: Text(widget.group.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: _getGroupColor().withOpacity(isDark ? 0.2 : 0.1)), child: Text('${widget.serverCount}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: _getGroupColor(), fontWeight: FontWeight.w700))),
          const SizedBox(width: 8),
          RotationTransition(turns: _arrowAnimation, child: Icon(Icons.chevron_right_rounded, size: 20, color: colorScheme.onSurfaceVariant)),
        ]),
      ),
    );
  }
}