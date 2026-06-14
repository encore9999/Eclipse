import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/usecases/test_server.dart';

class ServerTestResultWidget extends StatelessWidget {
  final int? ping;
  final bool isTesting;
  final ServerTestResult? testResult;
  final VoidCallback onTest;

  const ServerTestResultWidget({super.key, this.ping, this.isTesting = false, this.testResult, required this.onTest});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTest,
      child: Container(
        width: 56, height: 44,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: _backgroundColor(context)),
        child: isTesting
            ? const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary))))
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(_displayValue, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: _textColor, fontSize: 11)),
                if (testResult != null) Text(testResult!.statusText, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: _statusColor, fontSize: 8, fontWeight: FontWeight.w600)),
              ]),
      ),
    );
  }

  String get _displayValue {
    if (testResult != null && testResult!.isReachable) return '${testResult!.ping ?? ping ?? "?"}ms';
    if (ping != null) return '${ping}ms';
    return 'Test';
  }

  Color get _textColor {
    if (ping == null) return Colors.grey;
    if (ping! < 100) return AppColors.connected;
    if (ping! < 300) return AppColors.warning;
    return AppColors.error;
  }

  Color get _statusColor {
    if (testResult == null) return Colors.grey;
    return switch (testResult!.statusText) {
      'Excellent' => AppColors.connected, 'Good' => AppColors.connected.withOpacity(0.7),
      'Fair' => AppColors.warning, 'Slow' => AppColors.error, _ => Colors.grey
    };
  }

  Color _backgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (ping == null) return isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant;
    return _textColor.withOpacity(isDark ? 0.15 : 0.1);
  }
}