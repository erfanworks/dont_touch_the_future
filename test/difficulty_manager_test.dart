import 'package:dont_touch_the_future/core/constants/game_constants.dart';
import 'package:dont_touch_the_future/features/gameplay/game/systems/difficulty_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const d = DifficultyManager();

  group('DifficultyManager', () {
    test('phase boundaries follow the design brief', () {
      expect(d.phaseAt(0), DifficultyPhase.awakening);
      expect(d.phaseAt(14.99), DifficultyPhase.awakening);
      expect(d.phaseAt(15), DifficultyPhase.awareness);
      expect(d.phaseAt(30), DifficultyPhase.pressure);
      expect(d.phaseAt(60), DifficultyPhase.survival);
      expect(d.phaseAt(90), DifficultyPhase.chaos);
    });

    test('phase 1: only the echo is active', () {
      expect(d.targetStaticObstacles(10), 0);
      expect(d.targetMovingObstacles(10), 0);
      expect(d.targetShards(10), 0);
    });

    test('phase 2: first static obstacle and shards appear', () {
      expect(d.targetStaticObstacles(15), 1);
      expect(d.targetShards(15), 1);
      expect(d.targetMovingObstacles(20), 0);
    });

    test('moving obstacles are introduced only from 60s', () {
      expect(d.targetMovingObstacles(59.9), 0);
      expect(d.targetMovingObstacles(60), 1);
    });

    test('obstacle counts climb in clear steps', () {
      expect(d.targetStaticObstacles(30), 2);
      expect(d.targetStaticObstacles(45), 3);
      expect(d.targetStaticObstacles(80), 4);
      expect(d.targetStaticObstacles(90), 4);
      expect(d.targetStaticObstacles(120), 5);
      expect(d.targetStaticObstacles(150), 6);
      expect(d.targetMovingObstacles(75), 2);
      expect(d.targetMovingObstacles(110), 3);
      expect(d.targetMovingObstacles(130), 4);
      expect(d.targetMovingObstacles(150), 5);
    });

    test('every difficulty value never decreases as time grows', () {
      var s = 0, m = 0, c = 0;
      var sp = 0.0;
      var iv = 99.0; // spawn interval should only shrink
      for (var t = 0.0; t <= 900; t += 0.5) {
        final ns = d.targetStaticObstacles(t);
        final nm = d.targetMovingObstacles(t);
        final nc = d.targetShards(t);
        final nsp = d.movingObstacleSpeed(t);
        final niv = d.obstacleSpawnInterval(t);
        expect(ns >= s, isTrue);
        expect(nm >= m, isTrue);
        expect(nc >= c, isTrue);
        expect(nsp >= sp, isTrue);
        expect(niv <= iv, isTrue);
        s = ns;
        m = nm;
        c = nc;
        sp = nsp;
        iv = niv;
      }
    });

    test('difficulty keeps growing after 90s (no plateau at 2 minutes)', () {
      expect(d.targetStaticObstacles(150) > d.targetStaticObstacles(100), isTrue);
      expect(d.movingObstacleSpeed(250) > d.movingObstacleSpeed(135), isTrue);
      expect(d.obstacleSpawnInterval(160) < d.obstacleSpawnInterval(100), isTrue);
    });

    test('caps keep the arena survivable', () {
      expect(d.targetStaticObstacles(10000), 6);
      expect(d.targetMovingObstacles(10000), 5);
      expect(d.targetShards(10000), 2);
    });

    test('moving obstacles can always be outrun by the player', () {
      expect(d.movingObstacleSpeed(10000) < GameConstants.playerSpeed, isTrue);
      expect(d.movingObstacleSpeed(10000), 190);
    });

    test('moving speed ramps smoothly from 70', () {
      expect(d.movingObstacleSpeed(60), 70);
      expect(d.movingObstacleSpeed(70) > 70, isTrue);
    });

    test('the second echo only joins at 120s', () {
      expect(d.secondEchoActiveAt(119.9), isFalse);
      expect(d.secondEchoActiveAt(120), isTrue);
    });

    test('phase score multipliers rise with the phase', () {
      final m = GameConstants.phaseScoreMultipliers;
      expect(m.length, DifficultyPhase.values.length);
      expect(m.first, 1.0);
      for (var i = 1; i < m.length; i++) {
        expect(m[i] > m[i - 1], isTrue);
      }
    });
  });
}
