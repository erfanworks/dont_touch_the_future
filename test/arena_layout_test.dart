import 'package:dont_touch_the_future/core/constants/game_constants.dart';
import 'package:dont_touch_the_future/features/gameplay/game/game_session.dart';
import 'package:dont_touch_the_future/features/gameplay/game/models/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  layoutDuringRunTests();
  group('Arena layout and safe areas', () {
    test('arena starts below the HUD band', () {
      final s = GameSession()..configureArena(390, 844);
      expect(s.arenaTop, GameConstants.hudReservedHeight);
    });

    test('status-bar / notch inset pushes the arena down', () {
      final s = GameSession()..configureArena(390, 844, insetTop: 47);
      expect(s.arenaTop, 47 + GameConstants.hudReservedHeight);
    });

    test('bottom gesture bar and side cutouts shrink the arena', () {
      final s = GameSession()
        ..configureArena(390, 844,
            insetBottom: 34, insetLeft: 20, insetRight: 20);
      final pad = GameConstants.arenaPadding * s.unit;
      expect(s.arenaBottom, 844 - pad - 34);
      expect(s.arenaLeft, pad + 20);
      expect(s.arenaRight, 390 - pad - 20);
    });

    test('player starts inside the arena on several screen sizes', () {
      const sizes = [
        [320.0, 568.0],
        [360.0, 640.0],
        [390.0, 844.0],
        [430.0, 932.0],
        [412.0, 915.0],
        [600.0, 1024.0],
      ];
      for (final sz in sizes) {
        final s = GameSession()
          ..configureArena(sz[0], sz[1], insetTop: 40, insetBottom: 30);
        expect(s.player.x >= s.arenaLeft && s.player.x <= s.arenaRight, isTrue);
        expect(s.player.y >= s.arenaTop && s.player.y <= s.arenaBottom, isTrue);
        expect(s.arenaBottom > s.arenaTop, isTrue);
      }
    });

    test('insets arriving after the first size re-layout the ready arena', () {
      final s = GameSession()..configureArena(390, 844);
      final before = s.arenaTop;
      s.configureArena(390, 844, insetTop: 50);
      expect(s.status, GameStatus.ready);
      expect(s.arenaTop, before + 50);
    });

    test('layout changes are ignored while a run is in progress', () {
      final s = GameSession()..configureArena(390, 844);
      s.beginDrag();
      final top = s.arenaTop;
      s.configureArena(390, 844, insetTop: 99);
      expect(s.arenaTop, top);
    });
  });
}

void layoutDuringRunTests() {
  group('Layout changes during a run', () {
    test('a resize in Game Over never wipes the final scene', () {
      final s = GameSession()..configureArena(390, 844);
      s.beginDrag(); // stands still -> echo kills the player
      for (var i = 0; i < 160; i++) {
        s.update(1 / 32);
      }
      expect(s.status, GameStatus.gameOver);
      final run = s.runId;
      final score = s.score;
      s.configureArena(390, 844, insetTop: 60);
      expect(s.status, GameStatus.gameOver);
      expect(s.runId, run);
      expect(s.score, score);
    });

    test('the remembered layout is applied on restart', () {
      final s = GameSession()..configureArena(390, 844);
      s.beginDrag();
      s.configureArena(390, 844, insetTop: 60); // arrives mid-run
      final before = s.arenaTop;
      s.pause();
      s.reset();
      expect(s.arenaTop, before + 60);
      expect(s.player.y >= s.arenaTop, isTrue);
    });
  });
}
