import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ConnectionButton extends StatefulWidget {
  final bool isConnected;
  final bool isConnecting;
  final VoidCallback onTap;
  final Animation<double> rippleAnimation;

  const ConnectionButton({
    super.key,
    required this.isConnected,
    required this.isConnecting,
    required this.onTap,
    required this.rippleAnimation,
  });

  @override
  State<ConnectionButton> createState() => _ConnectionButtonState();
}

class _ConnectionButtonState extends State<ConnectionButton> with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _pressAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _pressAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(CurvedAnimation(parent: _pressController, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _pressController.dispose(); super.dispose(); }

  void _onTapDown(TapDownDetails d) { setState(() => _isPressed = true); _pressController.forward(); }
  void _onTapUp(TapUpDetails d) { setState(() => _isPressed = false); _pressController.reverse(); widget.onTap(); }
  void _onTapCancel() { setState(() => _isPressed = false); _pressController.reverse(); }

  @override
  Widget build(BuildContext context) {
    final gradientColors = widget.isConnected
        ? AppColors.connectedGradient
        : widget.isConnecting
            ? [AppColors.warning, AppColors.connecting]
            : [AppColors.primary[600]!, AppColors.primary[400]!];

    final outerGlow = widget.isConnected
        ? AppColors.primary.withOpacity(0.6)
        : widget.isConnecting
            ? AppColors.warning.withOpacity(0.5)
            : AppColors.primary.withOpacity(0.3);

    return Center(
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedBuilder(
          animation: Listenable.merge([_pressAnimation, widget.rippleAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: _pressAnimation.value,
              child: Container(
                width: 160, height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                  boxShadow: [
                    BoxShadow(color: outerGlow, blurRadius: 30 + (widget.rippleAnimation.value * 20), spreadRadius: 5),
                    if (_isPressed) BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, spreadRadius: -5),
                  ],
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: widget.isConnecting
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                        : Icon(Icons.power_settings_new, key: ValueKey(widget.isConnected), size: 52, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      widget.isConnected ? 'DISCONNECT' : widget.isConnecting ? 'CONNECTING...' : 'CONNECT',
                      key: ValueKey(widget.isConnected),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 1.5),
                    ),
                  ),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }
}