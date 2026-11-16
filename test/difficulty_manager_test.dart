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

    test('targets never decrease as time grows', () {
      var s = 0, m = 0, c = 0;
      for (var t = 0.0; t <= 300; t += 0.5) {
        final ns = d.targetStaticObstacles(t);
        final nm = d.targetMovingObstacles(t);
        final nc = d.targetShards(t);
        expect(ns >= s, isTrue);
        expect(nm >= m, isTrue);
        expect(nc >= c, isTrue);
        s = ns;
        m = nm;
        c = nc;
      }
    });

    test('difficulty is capped (always leaves room to survive)', () {
      expect(d.targetStaticObstacles(10000), 5);
      expect(d.targetMovingObstacles(10000), 4);
      expect(d.targetShards(10000), 2);
      expect(d.movingObstacleSpeed(10000), 130);
    });

    test('moving speed ramps smoothly from 70', () {
      expect(d.movingObstacleSpeed(60), 70);
      expect(d.movingObstacleSpeed(70) > 70, isTrue);
    });
  });
}
