import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../statistics/services/stats_repository.dart';
import '../game/future_game.dart';
import '../game/models/game_state.dart';
import 'overlays/game_over_overlay.dart';
import 'overlays/hud_overlay.dart';
import 'overlays/pause_overlay.dart';

/// Hosts the Flame game and its Flutter overlays.
class GameplayScreen extends StatefulWidget {
  const GameplayScreen({super.key});

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  // Created once (on first build) so rebuilds never create a second game.
  late final FutureGame _game = _createGame();

  FutureGame _createGame() {
    final scope = AppScope.of(context);
    return FutureGame(
      statsRepository: StatsRepository(scope.storage),
      haptics: scope.haptics,
      audio: scope.audio,
      settings: scope.settings,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final insets = MediaQuery.viewPaddingOf(context);
    _game.setSafeInsets(
      top: insets.top,
      bottom: insets.bottom,
      left: insets.left,
      right: insets.right,
    );
    _game.systemReducedMotion = MediaQuery.disableAnimationsOf(context);
  }

  @override
  Widget build(BuildContext context) {
    // Android back button: pause while playing, otherwise leave.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_game.session.status == GameStatus.playing) {
          _game.pauseGame();
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: GameWidget<FutureGame>(
          game: _game,
          initialActiveOverlays: const [FutureGame.hudOverlay],
          overlayBuilderMap: {
            FutureGame.hudOverlay: (_, g) => HudOverlay(game: g),
            FutureGame.pauseOverlay: (_, g) => PauseOverlay(game: g),
            FutureGame.gameOverOverlay: (_, g) => GameOverOverlay(game: g),
          },
        ),
      ),
    );
  }
}
