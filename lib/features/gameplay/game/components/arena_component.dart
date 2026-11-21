import 'dart:ui';

import 'package:flame/components.dart';

import '../../../../core/constants/color_constants.dart';
import '../game_session.dart';

/// Arena border and a subtle grid. The static artwork is recorded once into
/// a [Picture] and replayed each frame (rebuilt only if the layout changes).
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

  Picture? _picture;
  double _l = -1;
  double _t = -1;
  double _r = -1;
  double _b = -1;
  double _unit = -1;

  @override
  void render(Canvas canvas) {
    final l = session.arenaLeft;
    final t = session.arenaTop;
    final r = session.arenaRight;
    final b = session.arenaBottom;
    if (r <= l || b <= t) return;

    if (_picture == null ||
        l != _l ||
        t != _t ||
        r != _r ||
        b != _b ||
        session.unit != _unit) {
      _rebuild(l, t, r, b, session.unit);
    }
    canvas.drawPicture(_picture!);
  }

  void _rebuild(double l, double t, double r, double b, double unit) {
    final recorder = PictureRecorder();
    final c = Canvas(recorder);

    final step = 40.0 * unit;
    for (var x = l + step; x < r; x += step) {
      c.drawLine(Offset(x, t), Offset(x, b), _grid);
    }
    for (var y = t + step; y < b; y += step) {
      c.drawLine(Offset(l, y), Offset(r, y), _grid);
    }
    c.drawRRect(
      RRect.fromLTRBR(l, t, r, b, const Radius.circular(18)),
      _border,
    );

    _picture?.dispose();
    _picture = recorder.endRecording();
    _l = l;
    _t = t;
    _r = r;
    _b = b;
    _unit = unit;
  }

  @override
  void onRemove() {
    _picture?.dispose();
    _picture = null;
    super.onRemove();
  }
}
