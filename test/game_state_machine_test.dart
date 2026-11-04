import 'package:dont_touch_the_future/features/gameplay/game/models/game_state.dart';
import 'package:dont_touch_the_future/features/gameplay/game/systems/game_state_machine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameStateMachine', () {
    test('starts in initializing', () {
      expect(GameStateMachine().status, GameStatus.initializing);
    });

    test('follows the full happy path', () {
      final m = GameStateMachine();
      expect(m.transitionTo(GameStatus.ready), isTrue);
      expect(m.transitionTo(GameStatus.playing), isTrue);
      expect(m.transitionTo(GameStatus.paused), isTrue);
      expect(m.transitionTo(GameStatus.playing), isTrue);
      expect(m.transitionTo(GameStatus.gameOver), isTrue);
      expect(m.transitionTo(GameStatus.ready), isTrue);
    });

    test('rejects invalid transitions and keeps the old state', () {
      final m = GameStateMachine();
      expect(m.transitionTo(GameStatus.playing), isFalse); // init -> playing
      expect(m.status, GameStatus.initializing);

      m.transitionTo(GameStatus.ready);
      expect(m.transitionTo(GameStatus.paused), isFalse); // ready -> paused
      expect(m.transitionTo(GameStatus.gameOver), isFalse);
      expect(m.status, GameStatus.ready);
    });

    test('gameOver cannot resume or pause', () {
      final m = GameStateMachine(initial: GameStatus.gameOver);
      expect(m.transitionTo(GameStatus.playing), isFalse);
      expect(m.transitionTo(GameStatus.paused), isFalse);
      expect(m.status, GameStatus.gameOver);
    });

    test('paused can go back to ready (restart / home)', () {
      final m = GameStateMachine(initial: GameStatus.paused);
      expect(m.transitionTo(GameStatus.ready), isTrue);
    });

    test('isPlaying is true only while playing', () {
      final m = GameStateMachine(initial: GameStatus.ready);
      expect(m.isPlaying, isFalse);
      m.transitionTo(GameStatus.playing);
      expect(m.isPlaying, isTrue);
      m.transitionTo(GameStatus.paused);
      expect(m.isPlaying, isFalse);
    });
  });
}
