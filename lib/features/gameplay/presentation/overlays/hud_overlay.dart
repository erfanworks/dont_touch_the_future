import 'package:flutter/material.dart';

import '../../../../core/constants/color_constants.dart';
import '../../game/future_game.dart';

/// In-game HUD: score, best score, pause button and a short hint.
/// Only the pause button can receive touches; everything else lets drags pass.
class HudOverlay extends StatelessWidget {
  const HudOverlay({super.key, required this.game});

  final FutureGame game;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: IgnorePointer(
                child: ValueListenableBuilder<int>(
                  valueListenable: game.score,
                  builder: (_, score, __) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$score',
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        'BEST ${game.bestScore}',
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 11,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 92),
              child: IgnorePointer(
                child: ValueListenableBuilder<String>(
                  valueListenable: game.banner,
                  builder: (_, text, __) => AnimatedOpacity(
                    opacity: text.isEmpty ? 0 : 1,
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      text,
                      style: const TextStyle(
                        color: AppColors.chronoShard,
                        fontSize: 12,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              iconSize: 28,
              color: AppColors.secondaryText,
              icon: const Icon(Icons.pause_rounded),
              onPressed: game.pauseGame,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: IgnorePointer(
                child: ValueListenableBuilder<String>(
                  valueListenable: game.hint,
                  builder: (_, text, __) => AnimatedOpacity(
                    opacity: text.isEmpty ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      text,
                      style: const TextStyle(
                        color: AppColors.futureEcho,
                        fontSize: 12,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
