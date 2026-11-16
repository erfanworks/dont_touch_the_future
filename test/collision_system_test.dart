import 'package:dont_touch_the_future/features/gameplay/game/systems/collision_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CollisionSystem.circlesOverlap', () {
    test('overlapping circles collide', () {
      expect(CollisionSystem.circlesOverlap(0, 0, 10, 15, 0, 10), isTrue);
    });
    test('separated circles do not collide', () {
      expect(CollisionSystem.circlesOverlap(0, 0, 10, 30, 0, 10), isFalse);
    });
    test('exactly touching circles do not collide', () {
      expect(CollisionSystem.circlesOverlap(0, 0, 10, 20, 0, 10), isFalse);
    });
    test('identical position collides', () {
      expect(CollisionSystem.circlesOverlap(5, 5, 1, 5, 5, 1), isTrue);
    });
    test('diagonal distance is handled correctly', () {
      // distance = sqrt(18) ~ 4.24
      expect(CollisionSystem.circlesOverlap(0, 0, 2.5, 3, 3, 2.5), isTrue);
      expect(CollisionSystem.circlesOverlap(0, 0, 2, 3, 3, 2), isFalse);
    });
  });
}
