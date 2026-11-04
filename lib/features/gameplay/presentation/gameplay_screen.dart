import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/color_constants.dart';
import '../game/future_game.dart';

/// Hosts the Flame game. Pause / Game Over overlays arrive in Phase 3.
class GameplayScreen extends StatefulWidget {
  const GameplayScreen({super.key});

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  // Created once so rebuilds never create a second game instance.
  late final FutureGame _game = FutureGame();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: GameWidget<FutureGame>(game: _game)),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: AppColors.secondaryText,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
