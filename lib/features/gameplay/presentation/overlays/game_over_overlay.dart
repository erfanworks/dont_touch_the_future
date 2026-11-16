import 'package:flutter/material.dart';

import '../../../../core/constants/color_constants.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/secondary_button.dart';
import '../../../../utils/format.dart';
import '../../../statistics/models/run_summary.dart';
import '../../game/future_game.dart';

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({super.key, required this.game});

  final FutureGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RunSummary?>(
      valueListenable: game.lastRun,
      builder: (context, run, _) {
        if (run == null) return const SizedBox.shrink();
        final reduced = game.settings.reducedMotion;
        return ColoredBox(
          color: AppColors.background.withValues(alpha: 0.9),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'GAME OVER',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 28),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: run.score.toDouble()),
                  duration:
                      reduced ? Duration.zero : const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (_, value, __) => Text(
                    '${value.round()}',
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 64,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 34,
                  child: run.isNewBestScore
                      ? _RecordBadge(animate: !reduced)
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 18),
                _Stat(label: 'BEST', value: '${run.bestScore}'),
                _Stat(
                  label: 'SURVIVED',
                  value: formatSurvivalTime(run.survivalSeconds),
                ),
                _Stat(label: 'SHARDS', value: '${run.shards}'),
                const SizedBox(height: 36),
                PrimaryButton(label: 'PLAY AGAIN', onPressed: game.restartGame),
                const SizedBox(height: 12),
                SecondaryButton(
                  label: 'HOME',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// "NEW RECORD" badge with a gently pulsing glow.
class _RecordBadge extends StatefulWidget {
  const _RecordBadge({required this.animate});

  final bool animate;

  @override
  State<_RecordBadge> createState() => _RecordBadgeState();
}

class _RecordBadgeState extends State<_RecordBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 1;
    }
  }

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
        final glow = 0.15 + 0.35 * _controller.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.chronoShard.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.chronoShard.withValues(alpha: glow),
                blurRadius: 18,
              ),
            ],
          ),
          child: const Text(
            'NEW RECORD',
            style: TextStyle(
              color: AppColors.chronoShard,
              fontSize: 12,
              letterSpacing: 4,
              fontWeight: FontWeight.w800,
            ),
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        width: 220,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
