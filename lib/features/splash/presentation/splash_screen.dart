import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../app/app_scope.dart';
import '../../../core/constants/color_constants.dart';
import '../../../shared/widgets/echo_demo.dart' show paintGlowDot;

/// Maps [t] from [a]..[b] to 0..1 (clamped), through [curve].
double _iv(double t, double a, double b, [Curve curve = Curves.linear]) =>
    curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

// Timeline (fractions of the animation):
//   0.06-0.18  player appears        0.16-0.60  player travels the path
//   0.30-0.40  echo appears          echo replays the SAME path 0.14 later
//   0.74       echo catches player   0.74+      title letters reveal
//   0.90-1.00  tagline
const double _kPlayerStart = 0.16;
const double _kPlayerEnd = 0.60;
const double _kEchoDelay = 0.14;
const double _kCatch = _kPlayerEnd + _kEchoDelay;

double _playerU(double t) => Curves.easeInOut
    .transform(((t - _kPlayerStart) / (_kPlayerEnd - _kPlayerStart)).clamp(0.0, 1.0));

/// Splash that tells the game's story: your own path comes back to catch you.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  );

  bool _started = false;
  bool _navigated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    final reduced = MediaQuery.disableAnimationsOf(context) ||
        (AppScope.maybeOf(context)?.settings.reducedMotion ?? false);
    if (reduced) {
      _controller.value = 1; // show the finished frame, no motion
      Future<void>.delayed(const Duration(milliseconds: 900), _goHome);
    } else {
      _controller.forward().whenComplete(() {
        Future<void>.delayed(const Duration(milliseconds: 450), _goHome);
      });
    }
  }

  void _goHome() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _goHome, // tap anywhere to skip
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            return Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: _SplashPainter(t)),
                _Title(t: t),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- scene --

class _SplashPainter extends CustomPainter {
  _SplashPainter(this.t);

  final double t;

  /// Figure-eight path. Starts and ends at the centre point.
  Offset _path(double u, Size s) {
    final a = u * 2 * math.pi;
    return Offset(
      s.width / 2 + s.width * 0.30 * math.sin(a),
      s.height * 0.34 + s.height * 0.085 * math.sin(2 * a),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final unit = (size.width / 390).clamp(0.8, 1.5);
    final center = _path(0, size);

    // Soft purple atmosphere behind the path.
    final glowA = _iv(t, 0, 0.25);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.futureEcho.withValues(alpha: 0.10 * glowA),
            const Color(0x00000000),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.8)),
    );

    // Arena grid fades in.
    final grid = Paint()
      ..color = AppColors.border.withValues(alpha: 0.45 * _iv(t, 0, 0.14))
      ..strokeWidth = 1;
    final step = 40.0 * unit;
    for (var x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final pU = _playerU(t);
    final eU = _playerU(t - _kEchoDelay); // SAME path, delayed in time
    final playerPos = _path(pU, size);
    final echoPos = _path(eU, size);
    final echoAlpha = _iv(t, 0.30, 0.40) * (1 - _iv(t, _kCatch, _kCatch + 0.06));

    // Recorded path between echo and player.
    if (echoAlpha > 0 && pU > eU) {
      final path = Path()..moveTo(echoPos.dx, echoPos.dy);
      const n = 32;
      for (var i = 1; i <= n; i++) {
        final p = _path(eU + (pU - eU) * i / n, size);
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = AppColors.futureEcho.withValues(alpha: 0.32 * echoAlpha),
      );
    }

    if (echoAlpha > 0) {
      paintGlowDot(canvas, echoPos, 9 * unit, AppColors.futureEcho, 0.7 * echoAlpha);
    }

    // Player: pops in, and gives a little pulse when the echo catches it.
    final appear = _iv(t, 0.06, 0.18, Curves.easeOutBack);
    final playerAlpha = _iv(t, 0.06, 0.14);
    final bump = t > _kCatch ? 0.35 * (1 - _iv(t, _kCatch, _kCatch + 0.14, Curves.easeOut)) : 0.0;
    if (playerAlpha > 0) {
      paintGlowDot(
        canvas,
        playerPos,
        9 * unit * appear * (1 + bump),
        AppColors.player,
        playerAlpha,
      );
    }

    // Two shockwave rings at the moment of the catch.
    for (var k = 0; k < 2; k++) {
      final p = _iv(t, _kCatch + 0.04 * k, _kCatch + 0.22 + 0.04 * k, Curves.easeOut);
      if (p <= 0 || p >= 1) continue;
      canvas.drawCircle(
        center,
        14 * unit + 120 * unit * p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = (k == 0 ? AppColors.player : AppColors.futureEcho)
              .withValues(alpha: (1 - p) * 0.55),
      );
    }
  }

  @override
  bool shouldRepaint(_SplashPainter old) => old.t != t;
}

// ----------------------------------------------------------------- title --

class _Title extends StatelessWidget {
  const _Title({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final fontSize = (w * 0.125).clamp(38.0, 56.0);

    var index = 0;
    List<Widget> row(String text) => [
          for (final ch in text.split(''))
            _Letter(
              char: ch,
              t: t,
              start: _kCatch + (index++) * 0.013,
              fontSize: fontSize,
            ),
        ];

    return Align(
      alignment: const Alignment(0, 0.30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: row('PAST')),
          const SizedBox(height: 4),
          Row(mainAxisSize: MainAxisSize.min, children: row('TENSE')),
          const SizedBox(height: 22),
          Opacity(
            opacity: _iv(t, 0.90, 1.0),
            child: const Text(
              'YOUR PAST IS CHASING YOU.',
              style: TextStyle(
                color: AppColors.futureEcho,
                fontSize: 12,
                letterSpacing: 3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One letter: slides up and fades in, with a purple "echo" copy that starts
/// offset to the left and settles into a faint trace.
class _Letter extends StatelessWidget {
  const _Letter({
    required this.char,
    required this.t,
    required this.start,
    required this.fontSize,
  });

  final String char;
  final double t;
  final double start;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final p = _iv(t, start, start + 0.10, Curves.easeOutCubic);
    final g = _iv(t, start + 0.04, start + 0.26, Curves.easeOut);
    final style = TextStyle(
      fontSize: fontSize,
      height: 1.0,
      fontWeight: FontWeight.w800,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: fontSize * 0.07),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Transform.translate(
            offset: Offset(-(10 * (1 - g) + 3), 0),
            child: Opacity(
              opacity: p * (0.5 * (1 - g) + 0.14),
              child: Text(char, style: style.copyWith(color: AppColors.futureEcho)),
            ),
          ),
          Transform.translate(
            offset: Offset(0, 14 * (1 - p)),
            child: Opacity(
              opacity: p,
              child: Text(char, style: style.copyWith(color: AppColors.primaryText)),
            ),
          ),
        ],
      ),
    );
  }
}
