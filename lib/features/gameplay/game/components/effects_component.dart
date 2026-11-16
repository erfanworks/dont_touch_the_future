import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../../../core/constants/color_constants.dart';
import '../game_session.dart';
import '../systems/effects_system.dart';

/// Draws particles, floating texts and the impact flash on top of the arena.
class EffectsComponent extends Component {
  EffectsComponent({required this.effects, required this.session}) {
    priority = 60;
  }

  final EffectsSystem effects;
  final GameSession session;

  final Paint _paint = Paint();
  late final List<TextPainter> _painters = List<TextPainter>.generate(
    effects.texts.length,
    (_) => TextPainter(textDirection: TextDirection.ltr),
  );

  static Color _colorOf(EffectColor c) => switch (c) {
        EffectColor.white => AppColors.player,
        EffectColor.shard => AppColors.chronoShard,
        EffectColor.echo => AppColors.futureEcho,
        EffectColor.danger => AppColors.danger,
      };

  @override
  void render(Canvas canvas) {
    final unit = session.unit;

    for (var i = 0; i < effects.activeParticles; i++) {
      final life = effects.particleLife(i);
      _paint.color = _colorOf(effects.particleColor(i))
          .withValues(alpha: (life * 0.9).clamp(0.0, 1.0));
      canvas.drawCircle(
        Offset(effects.particleX(i), effects.particleY(i)),
        effects.particleSize(i) * unit * (0.4 + 0.6 * life),
        _paint,
      );
    }

    for (var i = 0; i < effects.texts.length; i++) {
      final t = effects.texts[i];
      if (!t.active) continue;
      final alpha = (1 - t.progress * t.progress).clamp(0.0, 1.0);
      final p = _painters[i];
      p.text = TextSpan(
        text: t.text,
        style: TextStyle(
          color: _colorOf(t.color).withValues(alpha: alpha),
          fontSize: 15 * t.scale * unit,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      );
      p.layout();
      p.paint(canvas, Offset(t.x - p.width / 2, t.y - p.height / 2));
    }

    if (effects.flash > 0) {
      _paint.color =
          AppColors.danger.withValues(alpha: (effects.flash * 0.5).clamp(0.0, 1.0));
      canvas.drawRect(
        Rect.fromLTWH(0, 0, session.arenaWidth, session.arenaHeight),
        _paint,
      );
    }
  }
}
