import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'reduced_motion_loop.dart';
import '../../core/constants/color_constants.dart';

/// Glowing dot used by the animated demos.
void paintGlowDot(
  Canvas canvas,
  Offset center,
  double radius,
  Color color,
  double alpha,
) {
  canvas.drawCircle(
    center,
    radius * 1.9,
    Paint()
      ..color = color.withValues(alpha: alpha * 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
  );
  canvas.drawCircle(
    center,
    radius,
    Paint()..color = color.withValues(alpha: alpha),
  );
}

/// Looping illustration of the core mechanic: the white player moves along a
/// path and the purple echo replays the same path [delay] seconds later.
class EchoDemo extends StatefulWidget {
  const EchoDemo({super.key, this.period = 8, this.delay = 3});

  final double period;
  final double delay;

  @override
  State<EchoDemo> createState() => _EchoDemoState();
}

class _EchoDemoState extends State<EchoDemo>
    with SingleTickerProviderStateMixin, ReducedMotionLoop {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (widget.period * 1000).round()),
  );

  @override
  AnimationController get loopController => _controller;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _EchoDemoPainter(_controller, widget.period, widget.delay),
    );
  }
}

class _EchoDemoPainter extends CustomPainter {
  _EchoDemoPainter(this.animation, this.period, this.delay)
      : super(repaint: animation);

  final Animation<double> animation;
  final double period;
  final double delay;

  Offset _pos(double t, Size s) {
    final u = t / period * 2 * math.pi;
    return Offset(
      s.width / 2 + s.width * 0.34 * math.sin(u),
      s.height / 2 + s.height * 0.30 * math.sin(2 * u),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value * period;
    final player = _pos(t, size);
    final echo = _pos(t - delay, size);

    // Faint line = the path the echo is about to walk.
    final path = Path()..moveTo(echo.dx, echo.dy);
    const steps = 48;
    for (var i = 1; i <= steps; i++) {
      final p = _pos(t - delay + delay * i / steps, size);
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = AppColors.futureEcho.withValues(alpha: 0.22),
    );

    paintGlowDot(canvas, echo, 13, AppColors.futureEcho, 0.55);
    paintGlowDot(canvas, player, 13, AppColors.player, 1);
  }

  @override
  bool shouldRepaint(_EchoDemoPainter old) =>
      old.period != period || old.delay != delay;
}
