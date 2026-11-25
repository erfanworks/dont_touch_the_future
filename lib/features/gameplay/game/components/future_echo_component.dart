import 'dart:ui';

import 'package:flame/components.dart';

import '../../../../core/constants/color_constants.dart';
import '../game_session.dart';
import 'glow_sprite.dart';

/// Draws the first Future Echo and, from 120 s, the older second echo.
/// It only draws what the session computed from recorded history.
class FutureEchoComponent extends Component {
  FutureEchoComponent(this.session) {
    priority = 30;
  }

  final GameSession session;

  final GlowSprite _glow = GlowSprite(AppColors.futureEcho, peakAlpha: 0.5);
  final Paint _body = Paint();
  final Paint _ring = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  @override
  void render(Canvas canvas) {
    if (session.echoActive) {
      _draw(canvas, session.echoX, session.echoY, session.echoFade, 1.0, false);
    }
    if (session.echo2Active) {
      _draw(canvas, session.echo2X, session.echo2Y, session.echo2Fade, 0.65, true);
    }
  }

  void _draw(
    Canvas canvas,
    double x,
    double y,
    double fade, // 0..1, harmless until 1
    double strength,
    bool older,
  ) {
    final c = Offset(x, y);
    final r = session.echoRadius;

    _glow.draw(canvas, x, y, r * 2.6 * (0.5 + 0.5 * fade) * (older ? 0.85 : 1));
    _body.color =
        AppColors.futureEcho.withValues(alpha: (0.25 + 0.4 * fade) * strength);
    canvas.drawCircle(c, r, _body);

    // The older echo has a thin outer ring so it is instantly recognisable.
    if (older) {
      _ring.color = AppColors.futureEcho.withValues(alpha: 0.55 * fade);
      canvas.drawCircle(c, r * 1.35, _ring);
    }

    if (fade < 1) {
      // Fade-in telegraph: a shrinking ring says "I am about to become real".
      _ring.color = AppColors.futureEcho.withValues(alpha: 0.7 * (1 - fade));
      canvas.drawCircle(c, r * (1 + (1 - fade) * 1.4), _ring);
    }
  }
}
