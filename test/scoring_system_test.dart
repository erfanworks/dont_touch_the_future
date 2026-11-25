import 'package:dont_touch_the_future/features/gameplay/game/systems/scoring_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScoringSystem basics', () {
    test('survival gives 10 points per second at x1.0', () {
      final s = ScoringSystem();
      s.addSurvivalTime(2.5);
      expect(s.score, 25);
    });

    test('phase multiplier scales survival points', () {
      final s = ScoringSystem();
      s.addSurvivalTime(10, multiplier: 2.0);
      expect(s.score, 200);
      expect(s.survivalSeconds, 10);
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
  });

  group('Shard combo', () {
    test('first shard is worth 50', () {
      final s = ScoringSystem();
      expect(s.collectShard(1.0), 50);
      expect(s.score, 50);
      expect(s.shardsCollected, 1);
    });

    test('chained shards climb the multiplier ladder and cap at x3', () {
      final s = ScoringSystem();
      final pts = <int>[];
      for (var i = 0; i < 7; i++) {
        pts.add(s.collectShard(i * 2.0)); // 2 s apart, inside the 4 s window
      }
      expect(pts, [50, 75, 100, 125, 150, 150, 150]);
      expect(s.bestChain, 7);
    });

    test('combo breaks when the window is missed', () {
      final s = ScoringSystem();
      s.collectShard(0);
      s.collectShard(2);
      expect(s.collectShard(6.5), 50); // 4.5 s gap -> chain restarts
    });

    test('combo exactly at the window edge still counts', () {
      final s = ScoringSystem();
      s.collectShard(0);
      expect(s.collectShard(4.0), 75);
    });

    test('display helpers reflect a running and an expired combo', () {
      final s = ScoringSystem();
      expect(s.comboChainAt(0), 0);
      s.collectShard(10);
      s.collectShard(11);
      expect(s.comboChainAt(12), 2);
      expect(s.nextComboMultiplierAt(12), 2.0);
      expect(s.comboTimeLeftAt(12) > 2.9, isTrue);
      expect(s.comboChainAt(20), 0);
      expect(s.nextComboMultiplierAt(20), 1.0);
      expect(s.comboTimeLeftAt(20), 0);
    });
  });

  group('Graze and reset', () {
    test('graze adds a bonus and counts', () {
      final s = ScoringSystem();
      s.addGraze(10);
      s.addGraze(20);
      expect(s.score, 30);
      expect(s.grazeCount, 2);
    });

    test('non-positive graze is ignored', () {
      final s = ScoringSystem();
      s.addGraze(0);
      expect(s.grazeCount, 0);
    });

    test('all score parts add up', () {
      final s = ScoringSystem();
      s.addSurvivalTime(10); // 100
      s.collectShard(5); // 50
      s.addGraze(20); // 20
      expect(s.score, 170);
    });

    test('reset clears score, combo, grazes and milestones', () {
      final s = ScoringSystem();
      s.addSurvivalTime(20);
      s.collectShard(1);
      s.collectShard(2);
      s.addGraze(10);
      s.reset();
      expect(s.score, 0);
      expect(s.grazeCount, 0);
      expect(s.bestChain, 0);
      expect(s.comboChainAt(2), 0);
      expect(s.addSurvivalTime(15), 15);
    });
  });
}
