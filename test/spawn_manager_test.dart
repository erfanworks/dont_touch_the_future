import 'dart:math';

import 'package:dont_touch_the_future/features/gameplay/game/systems/spawn_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpawnManager.findPoint safety', () {
    test('every accepted point respects all safety rules', () {
      for (var seed = 0; seed < 300; seed++) {
        final m = SpawnManager(random: Random(seed));
        const others = [CircleBody(200, 400, 22), CircleBody(100, 300, 9)];
        final p = m.findPoint(
          radius: 22,
          minX: 14,
          minY: 14,
          maxX: 376,
          maxY: 830,
          playerX: 195,
          playerY: 500,
          minPlayerDistance: 150,
          echoActive: true,
          echoX: 300,
          echoY: 600,
          minEchoDistance: 90,
          others: others,
          gap: 40,
        );
        if (p == null) continue;
        expect(sqrt(pow(p.x - 195, 2) + pow(p.y - 500, 2)) >= 150, isTrue);
        expect(sqrt(pow(p.x - 300, 2) + pow(p.y - 600, 2)) >= 90, isTrue);
        for (final o in others) {
          final need = 22 + o.radius + 40;
          expect(sqrt(pow(p.x - o.x, 2) + pow(p.y - o.y, 2)) >= need, isTrue);
        }
        expect(p.x >= 14 + 22 && p.x <= 376 - 22, isTrue);
        expect(p.y >= 14 + 22 && p.y <= 830 - 22, isTrue);
      }
    });

    test('returns null when there is no legal spot', () {
      final m = SpawnManager(random: Random(1));
      final p = m.findPoint(
        radius: 22,
        minX: 0,
        minY: 0,
        maxX: 100,
        maxY: 100,
        playerX: 50,
        playerY: 50,
        minPlayerDistance: 500,
        echoActive: false,
        others: const [],
        gap: 40,
      );
      expect(p, isNull);
    });

    test('returns null when the arena is smaller than the body', () {
      final m = SpawnManager(random: Random(1));
      final p = m.findPoint(
        radius: 50,
        minX: 0,
        minY: 0,
        maxX: 60,
        maxY: 60,
        playerX: 0,
        playerY: 0,
        minPlayerDistance: 0,
        echoActive: false,
        others: const [],
        gap: 0,
      );
      expect(p, isNull);
    });
  });

  group('SpawnManager timing', () {
    SpawnRequest run(SpawnManager m, double from, double to) {
      var r = SpawnRequest.none;
      for (var t = from; t < to; t += 0.1) {
        r = m.update(0.1, t, staticCount: 0, movingCount: 0, shardCount: 0);
        if (r != SpawnRequest.none) return r;
      }
      return r;
    }

    test('nothing spawns in the first 15 seconds', () {
      final m = SpawnManager(random: Random(1));
      expect(run(m, 0, 14.9), SpawnRequest.none);
    });

    test('first static obstacle arrives right after 15s', () {
      final m = SpawnManager(random: Random(1));
      run(m, 0, 14.9);
      expect(run(m, 14.9, 16), SpawnRequest.staticObstacle);
    });

    test('a spawn resets the timer so spawns are spaced out', () {
      final m = SpawnManager(random: Random(1));
      run(m, 0, 14.9);
      expect(run(m, 14.9, 16), SpawnRequest.staticObstacle);
      m.notifySpawned(SpawnRequest.staticObstacle);
      final r = m.update(0.1, 16.1,
          staticCount: 1, movingCount: 0, shardCount: 1);
      expect(r, SpawnRequest.none);
    });

    test('no extra obstacles once the target is reached', () {
      final m = SpawnManager(random: Random(1));
      for (var t = 0.0; t < 25; t += 0.1) {
        final r = m.update(0.1, t,
            staticCount: 1, movingCount: 0, shardCount: 1);
        expect(r, SpawnRequest.none);
      }
    });
  });
}
