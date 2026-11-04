import 'package:dont_touch_the_future/core/constants/game_constants.dart';
import 'package:dont_touch_the_future/features/gameplay/game/models/movement_sample.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MovementSample value equality', () {
    const a = MovementSample(time: 1, x: 2, y: 3);
    const b = MovementSample(time: 1, x: 2, y: 3);
    const c = MovementSample(time: 1, x: 2, y: 4);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a == c, isFalse);
  });

  test('Echo delay is exactly 3 seconds (brief requirement)', () {
    expect(GameConstants.echoDelaySeconds, 3.0);
  });
}
