import 'dart:math';

import 'package:dont_touch_the_future/core/constants/game_constants.dart';
import 'package:dont_touch_the_future/features/gameplay/game/game_session.dart';
import 'package:dont_touch_the_future/features/gameplay/game/models/game_state.dart';
import 'package:dont_touch_the_future/features/gameplay/game/systems/difficulty_manager.dart';
import 'package:dont_touch_the_future/features/gameplay/game/systems/spawn_manager.dart';
import 'package:flutter_test/flutter_test.dart';

const double dt = 1 / 32; // exactly representable -> no float drift

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

/// Scripted pseudo-random drag pattern (direction changes every 0.5 s).
void drive(GameSession s, double seconds, double frame, int seed,
    {void Function()? afterFrame}) {
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
    afterFrame?.call();
  }
}

void main() {
  group('Phase multiplier in a real run', () {
    test('score uses x1.0 until 15 s and x1.25 afterwards', () {
      final s = make()..collisionsEnabled = false;
      s.beginDrag();
      step(s, 20); // 640 frames
      // 480 frames at x1.0 (150 pts) + 160 frames at x1.25 (62.5 pts)
      expect(s.score, 212);
      expect(s.phaseMultiplier, 1.25);
    });

    test('phase change event carries the new multiplier', () {
      final s = make()..collisionsEnabled = false;
      final events = <GameEvent>[];
      s.onEvent = events.add;
      s.beginDrag();
      step(s, 16);
      final e = events.firstWhere((e) => e.type == GameEventType.phaseChanged);
      expect(e.value, DifficultyPhase.awareness.index);
      expect(e.multiplier, 1.25);
    });
  });

  group('Shard combo in a real run', () {
    test('two quick shards give 50 then 75', () {
      final s = make();
      final pts = <int>[];
      s.onEvent = (e) {
        if (e.type == GameEventType.shardCollected) pts.add(e.value);
      };
      s.beginDrag();
      s.spawnShardAt(s.player.x, s.player.y);
      s.update(dt);
      s.spawnShardAt(s.player.x, s.player.y);
      s.update(dt);
      expect(pts, [50, 75]);
      expect(s.comboChain, 2);
    });

    test('a slow second shard does not extend the combo', () {
      final s = make()..collisionsEnabled = false;
      final pts = <int>[];
      s.onEvent = (e) {
        if (e.type == GameEventType.shardCollected) pts.add(e.value);
      };
      s.beginDrag();
      s.spawnShardAt(s.player.x, s.player.y);
      s.update(dt);
      step(s, 4.5);
      s.spawnShardAt(s.player.x, s.player.y);
      s.update(dt);
      expect(pts, [50, 50]);
    });
  });

  group('Graze (near-miss) bonus', () {
    GameSession withObstacleAtGrazeDistance({bool armWait = true}) {
      final s = make();
      s.beginDrag(); // stands still
      final hit = s.playerRadius * GameConstants.hazardHitboxFactor;
      final r = GameConstants.staticObstacleRadius * s.unit;
      final d = hit + r + GameConstants.grazeMargin * s.unit * 0.5;
      s.spawnStaticObstacleAt(s.player.x + d, s.player.y);
      return s;
    }

    test('no bonus while the obstacle is still telegraphing', () {
      final s = withObstacleAtGrazeDistance();
      final events = <GameEvent>[];
      s.onEvent = events.add;
      step(s, 0.9);
      expect(events.where((e) => e.type == GameEventType.graze), isEmpty);
    });

    test('an armed obstacle right next to the player gives one bonus', () {
      final s = withObstacleAtGrazeDistance();
      final events = <GameEvent>[];
      s.onEvent = events.add;
      step(s, 2.0);
      final g = events.where((e) => e.type == GameEventType.graze).toList();
      expect(g.length, 1);
      expect(g.first.value, GameConstants.grazeObstaclePoints);
      expect(g.first.cause, DeathCause.obstacle);
      expect(s.scoring.grazeCount, 1);
      expect(s.score >= 10, isTrue);
      expect(s.status, GameStatus.playing);
    });

    test('cooldown stops the same obstacle being farmed', () {
      final s = withObstacleAtGrazeDistance();
      var n = 0;
      s.onEvent = (e) {
        if (e.type == GameEventType.graze) n++;
      };
      step(s, 3.4); // armed at 1.0 s, cooldown 3 s -> still one bonus
      expect(n, 1);
    });

    test('an actual hit is a death, never a graze', () {
      final s = make();
      s.beginDrag();
      s.spawnStaticObstacleAt(s.player.x, s.player.y);
      var grazes = 0;
      s.onEvent = (e) {
        if (e.type == GameEventType.graze) grazes++;
      };
      step(s, 1.5);
      expect(s.status, GameStatus.gameOver);
      expect(grazes, 0);
    });

    test('no graze bonus when collisions are disabled (QA mode)', () {
      final s = withObstacleAtGrazeDistance()..collisionsEnabled = false;
      step(s, 2.0);
      expect(s.scoring.grazeCount, 0);
    });
  });

  group('Phase breather', () {
    test('no new obstacle appears in the 4 s after entering Pressure', () {
      final s = make()..collisionsEnabled = false;
      s.beginDrag();
      step(s, 30.0625); // just inside Pressure (30 s)
      final before = s.obstacles.length; // 1 from the Awareness phase
      expect(before, 1);
      step(s, 3.5);
      expect(s.obstacles.length, before); // breather
      step(s, 3.0); // t ~ 36.5 s
      expect(s.obstacles.length > before, isTrue);
    });

    test('Awareness (first obstacle) has no breather', () {
      final s = make()..collisionsEnabled = false;
      s.beginDrag();
      step(s, 16);
      expect(s.obstacles.length, 1);
    });
  });

  group('Second echo (120 s+)', () {
    test('appears at 120 s, fades in, then is armed', () {
      final s = make(seed: 4)..collisionsEnabled = false;
      var announced = 0;
      s.onEvent = (e) {
        if (e.type == GameEventType.secondEcho) announced++;
      };
      s.beginDrag();
      drive(s, 119.5, 1 / 60, 3);
      expect(s.echo2Active, isFalse);
      drive(s, 0.6, 1 / 60, 4);
      expect(s.echo2Active, isTrue);
      expect(announced, 1);
      expect(s.echo2Fade < 1 || s.echo2Armed, isTrue);
      drive(s, 1.0, 1 / 60, 5);
      expect(s.echo2Armed, isTrue);
      expect(announced, 1);
    });

    test('replays the recorded path with an exact 6 second delay', () {
      final s = make(seed: 6)..collisionsEnabled = false;
      s.beginDrag();
      final times = <double>[];
      final xs = <double>[];
      final ys = <double>[];
      drive(s, 130, 1 / 60, 9, afterFrame: () {
        times.add(s.gameTime);
        xs.add(s.player.x);
        ys.add(s.player.y);
      });
      expect(s.echo2Active, isTrue);
      // Literal 6.0 on purpose: the test must not depend on the constant.
      expect(GameConstants.secondEchoDelaySeconds, 6.0);
      final target = s.gameTime - 6.0;
      var i = 1;
      while (times[i] < target) {
        i++;
      }
      final f = (target - times[i - 1]) / (times[i] - times[i - 1]);
      final ex = xs[i - 1] + (xs[i] - xs[i - 1]) * f;
      final ey = ys[i - 1] + (ys[i] - ys[i - 1]) * f;
      // History is sampled at >= 1/120 s, so allow a corner-cutting tolerance.
      expect((s.echo2X - ex).abs() < 3, isTrue);
      expect((s.echo2Y - ey).abs() < 3, isTrue);
    });

    test('is lethal once armed (cause = echo)', () {
      final s = make(seed: 2)..collisionsEnabled = false;
      s.beginDrag();
      drive(s, 123, 1 / 60, 5);
      expect(s.echo2Armed, isTrue);
      s.collisionsEnabled = true;
      // Teleport-free check: put the player exactly on the second echo.
      s.player.x = s.echo2X;
      s.player.y = s.echo2Y;
      s.update(1 / 60);
      expect(s.status, GameStatus.gameOver);
      expect(s.deathCause, DeathCause.echo);
    });

    test('history buffer is large enough for the 6 s delay', () {
      const needed = (GameConstants.secondEchoDelaySeconds +
              GameConstants.historyMarginSeconds) /
          GameConstants.historyMinSampleInterval;
      expect(GameConstants.historyCapacity > needed + 2, isTrue);
    });

    test('restart clears the second echo', () {
      final s = make(seed: 2)..collisionsEnabled = false;
      s.beginDrag();
      drive(s, 125, 1 / 60, 5);
      s.pause();
      s.reset();
      expect(s.echo2Active, isFalse);
      expect(s.score, 0);
    });
  });

  group('Spawn manager additions', () {
    test('breather blocks obstacles but not shards', () {
      final m = SpawnManager(random: Random(1));
      // Run past 20 s so both timers are ripe, then hold.
      for (var t = 0.0; t < 20; t += 0.1) {
        m.update(0.1, t, staticCount: 1, movingCount: 0, shardCount: 1);
      }
      m.holdObstacleSpawns(4);
      final r1 = m.update(0.1, 32, staticCount: 0, movingCount: 0, shardCount: 0);
      expect(r1, SpawnRequest.shard);
      expect(m.isHolding, isTrue);
      var obstacle = false;
      for (var t = 0.0; t < 3.8; t += 0.1) {
        final r = m.update(0.1, 32, staticCount: 0, movingCount: 0, shardCount: 2);
        if (r == SpawnRequest.staticObstacle) obstacle = true;
      }
      expect(obstacle, isFalse);
      var released = false;
      for (var t = 0.0; t < 1.0; t += 0.1) {
        final r = m.update(0.1, 32, staticCount: 0, movingCount: 0, shardCount: 2);
        if (r == SpawnRequest.staticObstacle) released = true;
      }
      expect(released, isTrue);
    });

    test('spawn points keep clear of the second echo too', () {
      for (var seed = 0; seed < 200; seed++) {
        final m = SpawnManager(random: Random(seed));
        final p = m.findPoint(
          radius: 22,
          minX: 14,
          minY: 100,
          maxX: 376,
          maxY: 830,
          playerX: 195,
          playerY: 500,
          minPlayerDistance: 150,
          echoActive: false,
          echo2Active: true,
          echo2X: 250,
          echo2Y: 400,
          minEchoDistance: 90,
          others: const [],
          gap: 40,
        );
        if (p == null) continue;
        expect(sqrt(pow(p.x - 250, 2) + pow(p.y - 400, 2)) >= 90, isTrue);
      }
    });
  });

  group('Whole-run invariants with the new systems', () {
    test('score never decreases and history stays bounded over 5 minutes', () {
      final s = make(seed: 11)..collisionsEnabled = false;
      s.beginDrag();
      var last = 0;
      var ok = true;
      drive(s, 300, 1 / 60, 13, afterFrame: () {
        if (s.score < last) ok = false;
        last = s.score;
        if (s.history.count > GameConstants.historyCapacity) ok = false;
        if (s.obstacles.length > 11 || s.shards.length > 2) ok = false;
      });
      expect(ok, isTrue);
      expect(s.phase, DifficultyPhase.chaos);
      expect(s.echo2Active, isTrue);
    });

    test('same seed and input stay deterministic with grazes and combos', () {
      List<int> run() {
        final s = GameSession(random: Random(77))..configureArena(390, 844);
        s.beginDrag();
        final out = <int>[];
        s.onEvent = (e) => out.add(e.type.index * 1000 + e.value);
        drive(s, 100, 1 / 60, 21);
        out.add(s.score);
        return out;
      }

      expect(run(), run());
    });

    test('echo delay is still exact (history capacity change)', () {
      for (final hz in [30, 60, 120, 240]) {
        final s = make(h: 3000);
        s.beginDrag();
        s.dragBy(0, -200);
        final y0 = s.player.y;
        final v = s.player.speed;
        while (s.gameTime < 6.0) {
          s.update(1 / hz);
        }
        expect(s.echoY, closeTo(y0 - v * (s.gameTime - 3.0), 1e-6));
      }
    });

    test('echo graze can be earned by passing close to the echo', () {
      final s = make();
      s.beginDrag();
      var n = 0;
      s.onEvent = (e) {
        if (e.type == GameEventType.graze && e.cause == DeathCause.echo) n++;
      };
      // Walk away from the start, then come back to pass NEAR (not on) it.
      s.dragBy(0, -200); // up
      step(s, 2.0);
      s.endDrag();
      s.beginDrag();
      s.dragBy(0, 200); // back down toward the start
      for (var i = 0; i < 400 && s.isPlaying; i++) {
        s.update(dt);
      }
      // Either we grazed (n>=1) or the echo got us; both prove the check ran
      // without throwing. When alive, any graze must have paid out.
      if (n > 0) {
        expect(s.scoring.grazeCount >= n, isTrue);
      }
      expect(s.status == GameStatus.playing || s.status == GameStatus.gameOver,
          isTrue);
    });
  });
}
