import 'dart:ui';

import 'package:flame/game.dart';

import '../../../core/constants/color_constants.dart';
import 'models/game_state.dart';
import 'systems/game_state_machine.dart';

/// Phase 1 skeleton: an empty dark arena that proves Flame is wired up.
/// Player, Future Echo, obstacles and scoring are added in Phase 2.
class FutureGame extends FlameGame {
  FutureGame() : _stateMachine = GameStateMachine();

  final GameStateMachine _stateMachine;

  GameStatus get status => _stateMachine.status;

  @override
  Color backgroundColor() => AppColors.background;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _stateMachine.transitionTo(GameStatus.ready);
  }
}
