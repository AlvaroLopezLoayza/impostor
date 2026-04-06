import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Animated dark background with slowly drifting gradient orbs.
class AnimatedGradientBg extends StatefulWidget {
  const AnimatedGradientBg({super.key});

  @override
  State<AnimatedGradientBg> createState() => _AnimatedGradientBgState();
}

class _AnimatedGradientBgState extends State<AnimatedGradientBg>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final t = _controller.value;
        final angle = t * 2 * math.pi;
        return SizedBox.expand(
          child: CustomPaint(
            painter: _GradientPainter(angle),
          ),
        );
      },
    );
  }
}

class _GradientPainter extends CustomPainter {
  final double angle;
  _GradientPainter(this.angle);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint..color = AppTheme.background,
    );

    // Orb 1 — top left violet
    final x1 = size.width * 0.3 + math.cos(angle) * size.width * 0.1;
    final y1 = size.height * 0.2 + math.sin(angle) * size.height * 0.08;
    canvas.drawCircle(
      Offset(x1, y1),
      size.width * 0.6,
      paint
        ..shader = RadialGradient(
          colors: [
            AppTheme.primary.withAlpha(70),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(x1, y1),
          radius: size.width * 0.6,
        )),
    );

    // Orb 2 — bottom right amber
    final x2 = size.width * 0.8 + math.cos(angle + math.pi) * size.width * 0.08;
    final y2 = size.height * 0.75 + math.sin(angle + math.pi) * size.height * 0.06;
    canvas.drawCircle(
      Offset(x2, y2),
      size.width * 0.45,
      paint
        ..shader = RadialGradient(
          colors: [
            AppTheme.accent.withAlpha(45),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(x2, y2),
          radius: size.width * 0.45,
        )),
    );
  }

  @override
  bool shouldRepaint(_GradientPainter old) => old.angle != angle;
}
