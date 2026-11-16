import 'package:dont_touch_the_future/core/constants/game_constants.dart';
import 'package:dont_touch_the_future/features/gameplay/game/systems/movement_history.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MovementHistory', () {
    test('empty buffer reports no sample', () {
      final h = MovementHistory();
      expect(h.sampleAt(1, MutablePoint()), isFalse);
      expect(h.isEmpty, isTrue);
    });

    test('returns the exact recorded position', () {
      final h = MovementHistory(minSampleInterval: 0.01);
      h.record(0, 10, 20);
      h.record(1, 30, 60);
      final p = MutablePoint();
      expect(h.sampleAt(1, p), isTrue);
      expect(p.x, 30);
      expect(p.y, 60);
    });

    test('interpolates linearly between two samples', () {
      final h = MovementHistory(minSampleInterval: 0.01);
      h.record(0, 0, 0);
      h.record(1, 100, 200);
      final p = MutablePoint();
      h.sampleAt(0.25, p);
      expect(p.x, closeTo(25, 1e-9));
      expect(p.y, closeTo(50, 1e-9));
    });

    test('clamps times outside the stored range', () {
      final h = MovementHistory(minSampleInterval: 0.01);
      h.record(1, 5, 5);
      h.record(2, 9, 9);
      final p = MutablePoint();
      h.sampleAt(-10, p);
      expect(p.x, 5);
      h.sampleAt(99, p);
      expect(p.x, 9);
    });

    test('skips samples that are too close in time', () {
      final h = MovementHistory(minSampleInterval: 0.01);
      expect(h.record(0, 0, 0), isTrue);
      expect(h.record(0.005, 1, 1), isFalse);
      expect(h.record(0.01, 2, 2), isTrue);
      expect(h.count, 2);
    });

    test('ring buffer never grows and keeps the newest samples', () {
      final h = MovementHistory(capacity: 4, minSampleInterval: 0.01);
      for (var i = 0; i < 10; i++) {
        h.record(i.toDouble(), i.toDouble(), 0);
      }
      expect(h.count, 4);
      expect(h.oldestTime, 6);
      expect(h.newestTime, 9);
      final p = MutablePoint();
      h.sampleAt(7.5, p);
      expect(p.x, closeTo(7.5, 1e-9));
      // A time that was already overwritten clamps to the oldest sample.
      h.sampleAt(2, p);
      expect(p.x, 6);
    });

    test('clear forgets everything', () {
      final h = MovementHistory(minSampleInterval: 0.01);
      h.record(0, 1, 1);
      h.clear();
      expect(h.isEmpty, isTrue);
      expect(h.sampleAt(0, MutablePoint()), isFalse);
    });

    test('default capacity covers delay + margin even at the sample cap', () {
      const needed = (GameConstants.echoDelaySeconds +
              GameConstants.historyMarginSeconds) /
          GameConstants.historyMinSampleInterval;
      expect(GameConstants.historyCapacity > needed + 2, isTrue);
    });

    test('3-second lookup stays exact under variable frame times', () {
      // Player moves at constant velocity; the sample from exactly 3.0s ago
      // must match the analytic position no matter how irregular the frames.
      final h = MovementHistory();
      const vx = 120.0;
      const x0 = 50.0;
      var t = 0.0;
      var seed = 7;
      double nextDt() {
        seed = (seed * 1103515245 + 12345) & 0x7fffffff;
        return 0.004 + (seed % 1000) / 1000 * 0.046; // 4ms .. 50ms
      }

      h.record(0, x0, 0);
      final p = MutablePoint();
      var checked = 0;
      while (t < 12) {
        t += nextDt();
        h.record(t, x0 + vx * t, 0);
        if (t >= 3.0) {
          expect(h.sampleAt(t - 3.0, p), isTrue);
          expect(p.x, closeTo(x0 + vx * (t - 3.0), 1e-6));
          checked++;
        }
      }
      expect(checked > 100, isTrue);
    });
  });
}
