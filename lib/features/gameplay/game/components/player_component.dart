import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../../../core/constants/color_constants.dart';
import '../game_session.dart';
import 'glow_sprite.dart';

/// The glowing white player circle with a subtle idle pulse.
class PlayerComponent extends Component {
  PlayerComponent(this.session) {
    priority = 40;
  }

  final GameSession session;
  double _t = 0;

  final GlowSprite _glow = GlowSprite(AppColors.player, peakAlpha: 0.45);
  final Paint _body = Paint()..color = AppColors.player;

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    final pulse = 1 + 0.04 * math.sin(_t * 4);
    final r = session.playerRadius * pulse;
    _glow.draw(canvas, session.player.x, session.player.y, r * 2.8);
    canvas.drawCircle(Offset(session.player.x, session.player.y), r, _body);
  }
}
