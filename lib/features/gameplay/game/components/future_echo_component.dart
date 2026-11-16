import 'dart:ui';

import 'package:flame/components.dart';

import '../../../../core/constants/color_constants.dart';
import '../game_session.dart';

/// The translucent purple ghost. It only draws what the session computed
/// from recorded history: no logic, no AI.
class FutureEchoComponent extends Component {
  FutureEchoComponent(this.session) {
    priority = 30;
  }

  final GameSession session;

  final Paint _glow = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
  final Paint _body = Paint();
  final Paint _ring = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  @override
  void render(Canvas canvas) {
    if (!session.echoActive) return;
    final fade = session.echoFade; // 0..1, harmless until 1
    final c = Offset(session.echoX, session.echoY);
    final r = session.echoRadius;

    _glow.color = AppColors.futureEcho.withValues(alpha: 0.18 + 0.27 * fade);
    _body.color = AppColors.futureEcho.withValues(alpha: 0.25 + 0.4 * fade);
    canvas.drawCircle(c, r * 1.8, _glow);
    canvas.drawCircle(c, r, _body);

    if (fade < 1) {
      // Fade-in telegraph: a shrinking ring says "I am about to become real".
      _ring.color = AppColors.futureEcho.withValues(alpha: 0.7 * (1 - fade));
      canvas.drawCircle(c, r * (1 + (1 - fade) * 1.4), _ring);
    }
  }
}
