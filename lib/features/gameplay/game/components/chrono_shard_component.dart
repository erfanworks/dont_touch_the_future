import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../../../core/constants/color_constants.dart';
import '../game_session.dart';
import 'glow_sprite.dart';

/// Draws all Chrono Shards: floating, rotating diamonds with a soft glow.
class ChronoShardComponent extends Component {
  ChronoShardComponent(this.session) {
    priority = 10;
  }

  final GameSession session;
  double _t = 0;

  final GlowSprite _glow = GlowSprite(AppColors.chronoShard, peakAlpha: 0.5);
  final Paint _body = Paint()..color = AppColors.chronoShard;

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    final list = session.shards;
    for (var i = 0; i < list.length; i++) {
      final s = list[i];
      final bob = math.sin(_t * 3 + i) * 2.5 * session.unit;
      final pulse = 1 + 0.08 * math.sin(_t * 5 + i);
      canvas.save();
      canvas.translate(s.x, s.y + bob);
      canvas.rotate(_t * 1.5 + i);
      _glow.draw(canvas, 0, 0, s.radius * 3.2 * pulse);
      final h = s.radius * 0.95;
      canvas.drawRect(Rect.fromLTRB(-h, -h, h, h), _body);
      canvas.restore();
    }
  }
}
