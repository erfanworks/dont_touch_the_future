import 'package:dont_touch_the_future/features/gameplay/game/systems/scoring_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScoringSystem', () {
    test('survival gives 10 points per second', () {
      final s = ScoringSystem();
      s.addSurvivalTime(2.5);
      expect(s.score, 25);
    });

    test('each shard gives 50 points', () {
      final s = ScoringSystem();
      s.collectShard();
      s.collectShard();
      expect(s.score, 100);
      expect(s.shardsCollected, 2);
    });

    test('score combines survival and shards', () {
      final s = ScoringSystem();
      s.addSurvivalTime(10);
      s.collectShard();
      expect(s.score, 150);
    });

    test('reports each milestone exactly once', () {
      final s = ScoringSystem();
      expect(s.addSurvivalTime(14.9), 0);
      expect(s.addSurvivalTime(0.2), 15);
      expect(s.addSurvivalTime(1), 0);
      expect(s.addSurvivalTime(15), 30);
    });

    test('ignores zero or negative time', () {
      final s = ScoringSystem();
      s.addSurvivalTime(0);
      s.addSurvivalTime(-5);
      expect(s.score, 0);
    });

    test('reset clears score, shards and milestones', () {
      final s = ScoringSystem();
      s.addSurvivalTime(20);
      s.collectShard();
      s.reset();
      expect(s.score, 0);
      expect(s.survivalSeconds, 0);
      expect(s.addSurvivalTime(15), 15);
    });
  });
}
