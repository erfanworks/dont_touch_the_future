import '../models/game_state.dart';

/// Guards every game state change so invalid jumps are impossible.
///
/// Allowed transitions:
///   initializing -> ready
///   ready        -> playing
///   playing      -> paused | gameOver
///   paused       -> playing | ready   (ready = restart / go home)
///   gameOver     -> ready
class GameStateMachine {
  GameStateMachine({GameStatus initial = GameStatus.initializing})
      : _status = initial;

  static const Map<GameStatus, Set<GameStatus>> _allowed = {
    GameStatus.initializing: {GameStatus.ready},
    GameStatus.ready: {GameStatus.playing},
    GameStatus.playing: {GameStatus.paused, GameStatus.gameOver},
    GameStatus.paused: {GameStatus.playing, GameStatus.ready},
    GameStatus.gameOver: {GameStatus.ready},
  };

  GameStatus _status;

  GameStatus get status => _status;

  bool get isPlaying => _status == GameStatus.playing;

  bool canTransitionTo(GameStatus next) =>
      _allowed[_status]?.contains(next) ?? false;

  /// Moves to [next] and returns true, or returns false (state unchanged)
  /// if the transition is not allowed.
  bool transitionTo(GameStatus next) {
    if (!canTransitionTo(next)) return false;
    _status = next;
    return true;
  }
}
