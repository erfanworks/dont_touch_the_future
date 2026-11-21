import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/color_constants.dart';
import '../../../shared/widgets/echo_demo.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/reduced_motion_loop.dart';

enum _DemoKind { drag, avoid }

class _Step {
  const _Step(this.title, this.body);
  final String title;
  final String body;
}

/// Three short, animated steps. Never forced: SKIP is always available.
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen>
    with SingleTickerProviderStateMixin, ReducedMotionLoop {
  static const List<_Step> _steps = [
    _Step('DRAG TO MOVE',
        'Touch and drag anywhere. Your circle follows your finger.'),
    _Step('YOUR PAST RETURNS IN 3 SECONDS',
        'Every move is recorded. 3 seconds later your Future Echo replays it exactly.'),
    _Step("DON'T TOUCH YOUR ECHO",
        'Keep moving, collect shards, avoid obstacles and survive as long as you can.'),
  ];

  final PageController _pages = PageController();
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  int _index = 0;

  bool get _isLast => _index == _steps.length - 1;

  @override
  AnimationController get loopController => _loop;

  @override
  double get restValue => 0.5;

  @override
  void dispose() {
    _loop.dispose();
    _pages.dispose();
    super.dispose();
  }

  void _start() => Navigator.of(context).pop(true);

  void _next() => _pages.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );

  Widget _demoFor(int i) {
    switch (i) {
      case 0:
        return CustomPaint(
          size: Size.infinite,
          painter: _DemoPainter(_DemoKind.drag, _loop),
        );
      case 1:
        return const EchoDemo();
      default:
        return CustomPaint(
          size: Size.infinite,
          painter: _DemoPainter(_DemoKind.avoid, _loop),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _start,
                child: const Text(
                  'SKIP',
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: _steps.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => _StepPage(step: _steps[i], demo: _demoFor(i)),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _steps.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _index ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _index ? AppColors.player : AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: _isLast ? 'START PLAYING' : 'NEXT',
              onPressed: _isLast ? _start : _next,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _StepPage extends StatelessWidget {
  const _StepPage({required this.step, required this.demo});

  final _Step step;
  final Widget demo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.secondaryBackground,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: demo,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.primaryText,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            step.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _DemoPainter extends CustomPainter {
  _DemoPainter(this.kind, this.animation) : super(repaint: animation);

  final _DemoKind kind;
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final v = animation.value;
    switch (kind) {
      case _DemoKind.drag:
        final c = size.center(Offset.zero);
        final r = size.shortestSide * 0.28;
        final u = v * 2 * math.pi;
        final finger = c + Offset(math.cos(u), math.sin(u)) * r;
        final player =
            c + Offset(math.cos(u - 0.7), math.sin(u - 0.7)) * (r * 0.75);
        canvas.drawCircle(
          c,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..color = AppColors.player.withValues(alpha: 0.06),
        );
        canvas.drawCircle(
          finger,
          24,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = AppColors.player.withValues(alpha: 0.35),
        );
        canvas.drawCircle(
          finger,
          8,
          Paint()..color = AppColors.player.withValues(alpha: 0.25),
        );
        paintGlowDot(canvas, player, 13, AppColors.player, 1);
      case _DemoKind.avoid:
        final player = Offset(size.width * 0.62, size.height * 0.5);
        final start = Offset(size.width * 0.15, size.height * 0.5);
        final k = Curves.easeInOut.transform((v / 0.7).clamp(0.0, 1.0));
        final echo = Offset.lerp(start, player - const Offset(26, 0), k)!;
        paintGlowDot(canvas, echo, 13, AppColors.futureEcho, 0.6);
        paintGlowDot(canvas, player, 13, AppColors.player, 1);
        if (v > 0.7) {
          final t = (v - 0.7) / 0.3;
          canvas.drawCircle(
            player,
            20 + 50 * t,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = AppColors.danger.withValues(alpha: 1 - t),
          );
        }
    }
  }

  @override
  bool shouldRepaint(_DemoPainter old) => old.kind != kind;
}
