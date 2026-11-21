import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../../../../core/constants/color_constants.dart';
import '../../game/future_game.dart';

/// In-game HUD: score, best score, pause button, banner and a short hint.
///
/// The top block has a FIXED height (explicit line heights, text scaling off),
/// always smaller than GameConstants.hudReservedHeight, so it can never touch
/// the arena border on any device or font-size setting.
/// Only the pause button can receive touches; everything else lets drags pass.
class HudOverlay extends StatelessWidget {
  const HudOverlay({super.key, required this.game});

  final FutureGame game;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: SafeArea(
        child: Stack(
          children: [
            // Score (40) + gap (4) + best (11) + top padding (8) = 63 px.
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
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
                            fontSize: 40,
                            height: 1.0,
                            fontWeight: FontWeight.w800,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'BEST ${game.bestScore}',
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 11,
                            height: 1.0,
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
            // Achievement banner: sits at y 70..82, still inside the HUD band.
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 70),
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
                          height: 1.0,
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
      ),
    );
  }
}
