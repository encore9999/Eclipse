import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../vpn_engine/domain/usecases/connect_vpn.dart';
import '../../../../injection_container.dart';
import '../providers/dashboard_provider.dart';
import '../../widgets/connection_button.dart';
import '../../widgets/server_list_panel.dart';
import '../../../servers/domain/entities/server.dart';
import '../../../subscriptions/presentation/providers/subscriptions_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with TickerProviderStateMixin {
  late AnimationController _rippleController;
  late Animation<double> _rippleAnimation;
  late AnimationController _waveController;

  @override void initState() {
    super.initState();
    _rippleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _rippleController, curve: Curves.easeInOut));
    _waveController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat();
  }

  @override void dispose() {
    _rippleController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _connectToServer(Server server) async {
    final c = sl.get<ConnectVpn>();
    await c(server);
  }

  void _showAddDialog() {
    final urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('add_subscription'.tr()),
        content: TextField(controller: urlController, decoration: const InputDecoration(labelText: 'URL', hintText: 'https://...'), keyboardType: TextInputType.url),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr())),
          FilledButton(onPressed: () {
            final url = urlController.text.trim();
            if (url.isNotEmpty) {
              ref.read(subscriptionsProvider.notifier).addSubscription(name: '', url: url);
              Navigator.pop(ctx);
            }
          }, child: Text('add'.tr())),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _waveController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: isDark ? AppColors.backgroundGradient : [const Color(0xFFF8F7FF), const Color(0xFFF0EEFF)]),
            ),
            child: CustomPaint(
              painter: _WaveLinesPainter(animationValue: _waveController.value),
              child: child,
            ),
          );
        },
        child: SafeArea(child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(20, 12, 8, 0), child: Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), gradient: const LinearGradient(colors: AppColors.connectedGradient, begin: Alignment.topLeft, end: Alignment.bottomRight)), child: const Icon(Icons.shield_moon_rounded, color: Colors.white, size: 20)),
            const SizedBox(width: 12),
            Text('Eclipse', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
            const Spacer(),
            if (state.isConnected) Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: AppColors.connected.withOpacity(0.15)), child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.connected)), const SizedBox(width: 6), Text('connected'.tr(), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.connected, fontWeight: FontWeight.w600))])),
            IconButton(icon: Icon(Icons.add_circle_outline_rounded, color: Theme.of(context).colorScheme.onSurface, size: 28), onPressed: _showAddDialog),
          ])),
          ConnectionButton(isConnected: state.isConnected, isConnecting: state.isConnecting, onTap: () => ref.read(dashboardProvider.notifier).quickConnect(), rippleAnimation: _rippleAnimation),
          const SizedBox(height: 16),
          if (state.isConnected) Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _InfoChip(icon: Icons.timer_outlined, label: 'duration'.tr(), value: ref.watch(connectionDurationProvider).value ?? '00:00:00'),
            const SizedBox(width: 16),
            _InfoChip(icon: Icons.speed_rounded, label: 'ping'.tr(), value: state.connectionStatus.ping != null && state.connectionStatus.ping! > 0 ? '${state.connectionStatus.ping} ms' : 'N/A'),
          ]),
          const SizedBox(height: 16),
          Expanded(child: ServerListPanel(currentServer: state.connectionStatus.serverName, onServerSelected: _connectToServer)),
        ])),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoChip({required this.icon, required this.label, required this.value});
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : AppColors.lightSurface), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: AppColors.primary[400]), const SizedBox(width: 6), Text(value, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)), const SizedBox(width: 4), Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))]));
}

class _WaveLinesPainter extends CustomPainter {
  final double animationValue;
  _WaveLinesPainter({required this.animationValue});

  @override void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.primary.withOpacity(0.06)..strokeWidth = 2.0..style = PaintingStyle.stroke;
    final lineCount = 10;
    final spacing = size.height / lineCount;

    for (int i = 0; i < lineCount; i++) {
      final phase = i * 0.5;
      final path = Path();
      final baseY = i * spacing + spacing / 2;
      path.moveTo(0, baseY);
      for (double x = 0; x <= size.width; x += 3) {
        final waveY = sin((x / size.width * 2 * pi) + animationValue * 2 * pi + phase) * 12.0;
        path.lineTo(x, baseY + waveY);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override bool shouldRepaint(covariant _WaveLinesPainter old) => old.animationValue != animationValue;
}