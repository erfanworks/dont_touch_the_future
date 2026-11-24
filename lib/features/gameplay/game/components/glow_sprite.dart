import 'dart:ui';

import 'package:flutter/painting.dart';

/// A soft glow drawn with a pre-built radial gradient. Much cheaper than
/// `MaskFilter.blur`, because no blur pass runs on the GPU each frame.
/// The gradient is created once (radius 1) and scaled when drawn.
class GlowSprite {
  GlowSprite(Color color, {double peakAlpha = 0.5})
      : _paint = Paint()
          ..shader = RadialGradient(
            colors: <Color>[
              color.withValues(alpha: peakAlpha),
              color.withValues(alpha: peakAlpha * 0.4),
              color.withValues(alpha: 0),
            ],
            stops: const <double>[0, 0.35, 1],
          ).createShader(const Rect.fromLTRB(-1, -1, 1, 1));

  final Paint _paint;

  void draw(Canvas canvas, double x, double y, double radius) {
    canvas.save();
    canvas.translate(x, y);
    canvas.scale(radius);
    canvas.drawCircle(Offset.zero, 1, _paint);
    canvas.restore();
  }
}
