import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../../../core/constants/color_constants.dart';
import '../game_session.dart';

/// The glowing white player circle with a subtle idle pulse.
class PlayerComponent extends Component {
  PlayerComponent(this.session) {
    priority = 40;
  }

  final GameSession session;
  double _t = 0;

  final Paint _glow = Paint()
    ..color = AppColors.player.withValues(alpha: 0.35)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
  final Paint _body = Paint()..color = AppColors.player;

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    final pulse = 1 + 0.04 * math.sin(_t * 4);
    final r = session.playerRadius * pulse;
    final c = Offset(session.player.x, session.player.y);
    canvas.drawCircle(c, r * 1.7, _glow);
    canvas.drawCircle(c, r, _body);
  }
}
