import 'dart:math';

import 'package:dont_touch_the_future/core/constants/game_constants.dart';
import 'package:dont_touch_the_future/features/gameplay/game/game_session.dart';
import 'package:flutter_test/flutter_test.dart';

/// Drives a session with a scripted pseudo-random drag pattern.
void drive(GameSession s, double seconds, double frame, int seed) {
  var r = seed;
  final frames = (seconds / frame).round();
  final every = (0.5 / frame).round();
  for (var i = 0; i < frames; i++) {
    if (i % every == 0) {
      r = (r * 1103515245 + 12345) & 0x7fffffff;
      final a = (r % 628) / 100;
      s.endDrag();
      s.beginDrag();
      s.dragBy(cos(a) * 80, sin(a) * 80);
    }
    s.update(frame);
  }
}

void main() {
  group('Long-session soak and determinism', () {
    test('10 simulated minutes stay bounded, finite and consistent', () {
      final s = GameSession(random: Random(9))
        ..configureArena(390, 844, insetTop: 47, insetBottom: 34)
        ..collisionsEnabled = false;
      s.beginDrag();
      for (var minute = 0; minute < 10; minute++) {
        drive(s, 60, 1 / 60, minute + 1);
        expect(s.history.count <= GameConstants.historyCapacity, isTrue);
        expect(s.obstacles.length <= 9, isTrue);
        expect(s.shards.length <= 2, isTrue);
        expect(s.player.x.isFinite && s.player.y.isFinite, isTrue);
        for (final o in s.obstacles) {
          expect(o.x >= s.arenaLeft && o.x <= s.arenaRight, isTrue);
          expect(o.y >= s.arenaTop && o.y <= s.arenaBottom, isTrue);
        }
      }
      expect(s.gameTime > 599, isTrue);
      expect(s.score > 6000, isTrue);
    });

    test('same seed and same input give an identical run (deterministic)', () {
      GameSession run() {
        final s = GameSession(random: Random(42))
          ..configureArena(390, 844)
          ..collisionsEnabled = false;
        s.beginDrag();
        drive(s, 120, 1 / 60, 5);
        return s;
      }

      final a = run();
      final b = run();
      expect(a.score, b.score);
      expect(a.obstacles.length, b.obstacles.length);
      for (var i = 0; i < a.obstacles.length; i++) {
        expect(a.obstacles[i].x, b.obstacles[i].x);
        expect(a.obstacles[i].y, b.obstacles[i].y);
      }
      expect(a.player.x, b.player.x);
      expect(a.echoX, b.echoX);
    });

    test('echo delay is exact at 30, 60, 120 and 240 Hz', () {
      for (final hz in [30, 60, 120, 240]) {
        final s = GameSession()..configureArena(390, 3000);
        s.beginDrag();
        s.dragBy(0, -200);
        final y0 = s.player.y;
        final v = s.player.speed;
        final frame = 1 / hz;
        while (s.gameTime < 6.0) {
          s.update(frame);
        }
        expect(s.echoActive, isTrue);
        expect(s.echoY, closeTo(y0 - v * (s.gameTime - 3.0), 1e-6));
      }
    });

    test('history stays bounded at 240 Hz for a full minute', () {
      final s = GameSession()
        ..configureArena(390, 844)
        ..collisionsEnabled = false;
      s.beginDrag();
      drive(s, 60, 1 / 240, 3);
      expect(s.history.count <= GameConstants.historyCapacity, isTrue);
      expect(s.echoActive, isTrue);
    });

    test('a small 320x568 phone runs 2 minutes without problems', () {
      final s = GameSession(random: Random(3))
        ..configureArena(320, 568, insetTop: 24, insetBottom: 16)
        ..collisionsEnabled = false;
      s.beginDrag();
      drive(s, 120, 1 / 60, 8);
      for (final o in s.obstacles) {
        expect(o.x.isFinite && o.y.isFinite, isTrue);
        expect(o.x >= s.arenaLeft && o.x <= s.arenaRight, isTrue);
      }
      expect(s.gameTime > 119, isTrue);
    });
  });
}
