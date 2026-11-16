import 'package:dont_touch_the_future/features/gameplay/game/systems/player_motion.dart';
import 'package:flutter_test/flutter_test.dart';

PlayerMotion make() {
  final m = PlayerMotion();
  m.configure(
    radius: 14,
    speed: 200,
    followRadius: 50,
    deadZone: 6,
    minX: 0,
    minY: 0,
    maxX: 1000,
    maxY: 1000,
  );
  m.reset(500, 500);
  return m;
}

void main() {
  group('PlayerMotion', () {
    test('does not move without a drag', () {
      final m = make();
      m.update(1);
      expect(m.x, 500);
      expect(m.y, 500);
    });

    test('moves at constant speed in the drag direction', () {
      final m = make();
      m.dragStart();
      m.dragUpdate(30, 0);
      m.update(0.5);
      expect(m.x, closeTo(600, 1e-9)); // 200 px/s * 0.5s
      expect(m.y, 500);
    });

    test('speed does not depend on how far the finger moved', () {
      final a = make()..dragStart();
      final b = make()..dragStart();
      a.dragUpdate(10, 0);
      b.dragUpdate(500, 0);
      a.update(0.1);
      b.update(0.1);
      expect(a.x, closeTo(b.x, 1e-9));
    });

    test('dead zone ignores tiny finger movement', () {
      final m = make();
      m.dragStart();
      m.dragUpdate(2, 2);
      m.update(1);
      expect(m.x, 500);
    });

    test('same distance for one big step and many small steps', () {
      final one = make()..dragStart();
      final many = make()..dragStart();
      one.dragUpdate(40, 0);
      many.dragUpdate(40, 0);
      one.update(0.5);
      for (var i = 0; i < 50; i++) {
        many.update(0.01);
      }
      expect(many.x, closeTo(one.x, 1e-6));
    });

    test('cannot leave the arena', () {
      final m = make();
      m.dragStart();
      m.dragUpdate(50, -50);
      m.update(100);
      expect(m.x, 1000);
      expect(m.y, 0);
    });

    test('direction can reverse quickly after a long drag', () {
      final m = make();
      m.dragStart();
      m.dragUpdate(1000, 0); // offset saturates at followRadius (50)
      m.dragUpdate(-80, 0); // 50 - 80 = -30 -> now pointing left
      m.update(0.1);
      expect(m.x < 500, isTrue);
    });

    test('dragEnd stops movement', () {
      final m = make();
      m.dragStart();
      m.dragUpdate(40, 0);
      m.dragEnd();
      m.update(1);
      expect(m.x, 500);
    });
  });
}
