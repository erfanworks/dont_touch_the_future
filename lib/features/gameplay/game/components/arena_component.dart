import 'dart:ui';

import 'package:flame/components.dart';

import '../../../../core/constants/color_constants.dart';
import '../game_session.dart';

/// Arena border and a subtle grid. Purely visual.
class ArenaComponent extends Component {
  ArenaComponent(this.session) {
    priority = 0;
  }

  final GameSession session;

  final Paint _grid = Paint()
    ..color = AppColors.border.withValues(alpha: 0.35)
    ..strokeWidth = 1;
  final Paint _border = Paint()
    ..color = AppColors.border
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  @override
  void render(Canvas canvas) {
    final l = session.arenaLeft;
    final t = session.arenaTop;
    final r = session.arenaRight;
    final b = session.arenaBottom;
    if (r <= l || b <= t) return;

    final step = 40.0 * session.unit;
    for (var x = l + step; x < r; x += step) {
      canvas.drawLine(Offset(x, t), Offset(x, b), _grid);
    }
    for (var y = t + step; y < b; y += step) {
      canvas.drawLine(Offset(l, y), Offset(r, y), _grid);
    }
    canvas.drawRRect(
      RRect.fromLTRBR(l, t, r, b, const Radius.circular(18)),
      _border,
    );
  }
}
