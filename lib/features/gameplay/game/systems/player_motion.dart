import 'dart:math' as math;

/// Player movement driven by a "floating joystick" drag.
///
/// Finger movement is accumulated into an offset that is capped at
/// [followRadius]. The player always moves at constant [speed] in the
/// direction of that offset (once past [deadZone]), so control is smooth,
/// consistent and independent of how far the finger travelled.
class PlayerMotion {
  double x = 0;
  double y = 0;

  double radius = 14;
  double speed = 240;
  double followRadius = 56;
  double deadZone = 6;

  double minX = 0;
  double minY = 0;
  double maxX = 0;
  double maxY = 0;

  bool _dragging = false;
  double _offX = 0;
  double _offY = 0;

  bool get isDragging => _dragging;

  void configure({
    required double radius,
    required double speed,
    required double followRadius,
    required double deadZone,
    required double minX,
    required double minY,
    required double maxX,
    required double maxY,
  }) {
    this.radius = radius;
    this.speed = speed;
    this.followRadius = followRadius;
    this.deadZone = deadZone;
    this.minX = minX;
    this.minY = minY;
    this.maxX = maxX;
    this.maxY = maxY;
  }

  void reset(double startX, double startY) {
    x = startX;
    y = startY;
    dragEnd();
  }

  void dragStart() {
    _dragging = true;
    _offX = 0;
    _offY = 0;
  }

  void dragUpdate(double dx, double dy) {
    if (!_dragging) return;
    _offX += dx;
    _offY += dy;
    final len = math.sqrt(_offX * _offX + _offY * _offY);
    if (len > followRadius) {
      final f = followRadius / len;
      _offX *= f;
      _offY *= f;
    }
  }

  void dragEnd() {
    _dragging = false;
    _offX = 0;
    _offY = 0;
  }

  void update(double dt) {
    if (!_dragging || dt <= 0) return;
    final len = math.sqrt(_offX * _offX + _offY * _offY);
    if (len < deadZone) return;
    x += _offX / len * speed * dt;
    y += _offY / len * speed * dt;
    x = x < minX ? minX : (x > maxX ? maxX : x);
    y = y < minY ? minY : (y > maxY ? maxY : y);
  }
}
