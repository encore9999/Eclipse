import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_colors.dart';

class PingDisplay extends StatelessWidget {
  final int? ping;
  const PingDisplay({super.key, this.ping});

  @override
  Widget build(BuildContext context) {
    final color = ping == null ? Colors.grey : ping! < 100 ? AppColors.connected : ping! < 300 ? AppColors.warning : AppColors.error;
    final text = ping == null ? '--' : '$ping ms';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: color.withOpacity(0.1)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.speed_rounded, size: 16, color: color),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16, fontFamily: 'JetBrainsMono')),
        const SizedBox(width: 4),
        Text('ping'.tr(), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
      ]),
    );
  }
}