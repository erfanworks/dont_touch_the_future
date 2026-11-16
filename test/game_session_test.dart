import 'dart:math';

import 'package:dont_touch_the_future/core/constants/game_constants.dart';
import 'package:dont_touch_the_future/features/gameplay/game/game_session.dart';
import 'package:dont_touch_the_future/features/gameplay/game/models/game_state.dart';
import 'package:dont_touch_the_future/features/gameplay/game/systems/difficulty_manager.dart';
import 'package:flutter_test/flutter_test.dart';

/// 1/32 is exactly representable in binary, so time sums have no drift.
const double dt = 1 / 32;

GameSession make({int seed = 1, double w = 390, double h = 844}) {
  final s = GameSession(random: Random(seed));
  s.configureArena(w, h);
  return s;
}

void step(GameSession s, double seconds, {double stepDt = dt}) {
  final n = (seconds / stepDt).round();
  for (var i = 0; i < n; i++) {
    s.update(stepDt);
  }
}

void main() {
  group('Setup and state', () {
    test('starts in initializing and becomes ready once sized', () {
      final s = GameSession();
      expect(s.status, GameStatus.initializing);
      s.configureArena(0, 0);
      expect(s.status, GameStatus.initializing);
      s.configureArena(390, 844);
      expect(s.status, GameStatus.ready);
    });

    test('the first drag starts the run', () {
      final s = make();
      s.beginDrag();
      expect(s.status, GameStatus.playing);
    });

    test('nothing advances while ready', () {
      final s = make();
      step(s, 2);
      expect(s.gameTime, 0);
      expect(s.score, 0);
    });

    test('a huge frame is clamped to protect the timeline', () {
      final s = make();
      s.beginDrag();
      s.update(5.0);
      expect(s.gameTime, GameConstants.maxFrameDeltaSeconds);
    });
  });

  group('Player movement', () {
    test('player moves while dragging and stays inside the arena', () {
      final s = make();
      s.beginDrag();
      s.dragBy(80, -80);
      final startX = s.player.x;
      step(s, 0.5);
      expect(s.player.x > startX, isTrue);
      step(s, 30);
      expect(s.player.x <= s.arenaRight - s.playerRadius + 1e-9, isTrue);
      expect(s.player.y >= s.arenaTop + s.playerRadius - 1e-9, isTrue);
    });
  });

  group('Future Echo', () {
    test('is inactive before 3s and appears exactly at 3s', () {
      final s = make()..collisionsEnabled = false;
      s.beginDrag();
      final sx = s.player.x;
      final sy = s.player.y;
      step(s, 2.96875); // 95 frames
      expect(s.echoActive, isFalse);
      step(s, dt);
      expect(s.echoActive, isTrue);
      // Player never moved, so the echo spawns on the starting point.
      expect(s.echoX, closeTo(sx, 1e-9));
      expect(s.echoY, closeTo(sy, 1e-9));
    });

    test('replays the path with an exact 3 second delay (variable FPS)', () {
      final s = make(h: 3000);
      s.beginDrag();
      s.dragBy(0, -200); // straight up at constant speed
      final y0 = s.player.y;
      final v = s.player.speed;
      var seed = 11;
      var checked = 0;
      while (s.gameTime < 6.5) {
        seed = (seed * 1103515245 + 12345) & 0x7fffffff;
        s.update(0.004 + (seed % 1000) / 1000 * 0.046);
        if (s.gameTime >= 3.0) {
          expect(s.echoActive, isTrue);
          expect(s.echoX, closeTo(s.player.x, 1e-9));
          expect(s.echoY, closeTo(y0 - v * (s.gameTime - 3.0), 1e-6));
          checked++;
        }
      }
      expect(s.isPlaying, isTrue);
      expect(checked > 50, isTrue);
    });

    test('is harmless during its fade-in, deadly right after', () {
      final s = make();
      s.beginDrag(); // player stays still on the start point
      step(s, 3.40625); // echo is 0.406s old (< 0.5s grace)
      expect(s.echoActive, isTrue);
      expect(s.echoArmed, isFalse);
      expect(s.status, GameStatus.playing);

      step(s, 0.5);
      expect(s.status, GameStatus.gameOver);
      expect(s.deathCause, DeathCause.echo);
    });

    test('can be disabled for QA with collisionsEnabled=false', () {
      final s = make()..collisionsEnabled = false;
      s.beginDrag();
      step(s, 6);
      expect(s.status, GameStatus.playing);
    });
  });

  group('Chrono Shards and obstacles', () {
    test('collecting a shard adds 50 points and removes it', () {
      final s = make();
      final events = <GameEvent>[];
      s.onEvent = events.add;
      s.beginDrag();
      s.spawnShardAt(s.player.x, s.player.y);
      s.update(dt);
      expect(s.shards, isEmpty);
      expect(s.scoring.shardsCollected, 1);
      expect(s.score >= 50, isTrue);
      expect(
        events.any((e) => e.type == GameEventType.shardCollected),
        isTrue,
      );
    });

    test('obstacle is harmless while telegraphing, then deadly', () {
      final s = make();
      s.beginDrag();
      s.spawnStaticObstacleAt(s.player.x, s.player.y);
      step(s, 0.96875); // 31 frames, age < 1.0s
      expect(s.status, GameStatus.playing);
      step(s, 0.0625);
      expect(s.status, GameStatus.gameOver);
      expect(s.deathCause, DeathCause.obstacle);
    });

    test('moving obstacles bounce and never leave the arena', () {
      final s = make()..collisionsEnabled = false;
      s.beginDrag();
      s.spawnMovingObstacleAt(195, 300, 310, 170);
      for (var i = 0; i < 960; i++) {
        s.update(dt);
        final o = s.obstacles.first;
        expect(o.x >= s.arenaLeft && o.x <= s.arenaRight, isTrue);
        expect(o.y >= s.arenaTop && o.y <= s.arenaBottom, isTrue);
      }
    });
  });

  group('Scoring in session', () {
    test('survival gives exactly 10 points per second', () {
      final s = make()..collisionsEnabled = false;
      s.beginDrag();
      step(s, 3); // 96 frames
      expect(s.score, 30);
    });

    test('milestone event fires at 15 seconds', () {
      final s = make()..collisionsEnabled = false;
      final events = <GameEvent>[];
      s.onEvent = events.add;
      s.beginDrag();
      step(s, 16);
      final m = events.where((e) => e.type == GameEventType.milestone);
      expect(m.length, 1);
      expect(m.first.value, 15);
    });
  });

  group('Pause and resume', () {
    test('pause freezes the whole simulation', () {
      final s = make(h: 3000);
      s.beginDrag();
      s.dragBy(0, -100);
      step(s, 4);
      expect(s.pause(), isTrue);

      final t = s.gameTime;
      final y = s.player.y;
      final ey = s.echoY;
      final score = s.score;
      for (var i = 0; i < 200; i++) {
        s.update(0.05);
      }
      expect(s.status, GameStatus.paused);
      expect(s.gameTime, t);
      expect(s.player.y, y);
      expect(s.echoY, ey);
      expect(s.score, score);
    });

    test('resume continues from the exact previous state', () {
      final s = make(h: 3000);
      s.beginDrag();
      s.dragBy(0, -100);
      step(s, 4);
      s.pause();
      final t = s.gameTime;
      s.update(10);
      expect(s.resume(), isTrue);
      expect(s.gameTime, t);
      s.dragBy(0, -100); // pause ended the drag; start a new one
      s.beginDrag();
      s.dragBy(0, -100);
      s.update(dt);
      expect(s.gameTime, t + dt);
      // The echo is still exactly 3 seconds behind after resuming.
      expect(s.echoActive, isTrue);
    });

    test('cannot pause when not playing', () {
      final s = make();
      expect(s.pause(), isFalse);
    });
  });

  group('Restart', () {
    test('reset clears everything', () {
      final s = make();
      s.beginDrag();
      step(s, 4); // dies to the echo
      expect(s.status, GameStatus.gameOver);
      final oldRun = s.runId;

      expect(s.reset(), isTrue);
      expect(s.status, GameStatus.ready);
      expect(s.gameTime, 0);
      expect(s.score, 0);
      expect(s.history.isEmpty, isTrue);
      expect(s.obstacles, isEmpty);
      expect(s.shards, isEmpty);
      expect(s.echoActive, isFalse);
      expect(s.deathCause, isNull);
      expect(s.runId > oldRun, isTrue);
    });

    test('old movement history cannot leak into a new run', () {
      final s = make(h: 3000);
      s.beginDrag();
      s.dragBy(0, -200);
      step(s, 5); // run 1: travel far upwards
      s.pause();
      s.reset();

      s.beginDrag(); // run 2: stand still on the start point
      final sx = s.player.x;
      final sy = s.player.y;
      step(s, 3.03125);
      expect(s.echoActive, isTrue);
      expect(s.echoX, closeTo(sx, 1e-9));
      expect(s.echoY, closeTo(sy, 1e-9));
    });

    test('cannot reset while a run is playing', () {
      final s = make();
      s.beginDrag();
      expect(s.reset(), isFalse);
      expect(s.status, GameStatus.playing);
    });
  });

  group('Difficulty and fairness over a long run', () {
    test('obstacles appear on schedule and always spawn fairly', () {
      final s = make(seed: 5)..collisionsEnabled = false;
      s.beginDrag();
      var seed = 3;
      const frame = 1 / 60;
      var maxStatic = 0;
      var maxMoving = 0;
      var sawBefore15 = false;

      for (var i = 0; i < 60 * 140; i++) {
        if (i % 30 == 0) {
          seed = (seed * 1103515245 + 12345) & 0x7fffffff;
          final a = (seed % 628) / 100;
          s.endDrag();
          s.beginDrag();
          s.dragBy(cos(a) * 80, sin(a) * 80);
        }
        s.update(frame);

        if (s.gameTime < 14.9 &&
            (s.obstacles.isNotEmpty || s.shards.isNotEmpty)) {
          sawBefore15 = true;
        }

        // Fairness: just-spawned hazards must be far from the player.
        for (final o in s.obstacles) {
          if (o.age < frame * 1.5) {
            final d = sqrt(pow(o.x - s.player.x, 2) + pow(o.y - s.player.y, 2));
            expect(d >= GameConstants.spawnMinPlayerDistance * s.unit - 1e-6,
                isTrue);
          }
          expect(o.x.isFinite && o.y.isFinite, isTrue);
        }

        final statics = s.obstacles.where((o) => !o.isMoving).length;
        final moving = s.obstacles.where((o) => o.isMoving).length;
        if (statics > maxStatic) maxStatic = statics;
        if (moving > maxMoving) maxMoving = moving;
      }

      expect(sawBefore15, isFalse);
      expect(maxStatic <= 5, isTrue);
      expect(maxMoving <= 4, isTrue);
      expect(maxStatic >= 4, isTrue);
      expect(maxMoving >= 3, isTrue);
      expect(s.phase, DifficultyPhase.chaos);
    });
  });
}
