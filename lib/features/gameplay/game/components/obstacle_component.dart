import 'dart:ui';

import 'package:flame/components.dart';

import '../../../../core/constants/color_constants.dart';
import '../game_session.dart';

/// Draws every obstacle in one pass (no per-obstacle component churn).
/// While telegraphing it is a faint ring; once armed it is solid red.
class ObstacleComponent extends Component {
  ObstacleComponent(this.session) {
    priority = 20;
  }

  final GameSession session;

  final Paint _glow = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  final Paint _body = Paint();
  final Paint _ring = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  @override
  void render(Canvas canvas) {
    final list = session.obstacles;
    for (var i = 0; i < list.length; i++) {
      final o = list[i];
      final c = Offset(o.x, o.y);
      if (o.isArmed) {
        _glow.color = AppColors.danger.withValues(alpha: 0.4);
        _body.color = AppColors.danger.withValues(alpha: 0.92);
        canvas.drawCircle(c, o.radius * 1.5, _glow);
        canvas.drawCircle(c, o.radius, _body);
      } else {
        final p = o.armProgress;
        _ring.color = AppColors.danger.withValues(alpha: 0.25 + 0.5 * p);
        _body.color = AppColors.danger.withValues(alpha: 0.12 + 0.25 * p);
        canvas.drawCircle(c, o.radius, _body);
        canvas.drawCircle(c, o.radius, _ring);
      }
    }
  }
}
