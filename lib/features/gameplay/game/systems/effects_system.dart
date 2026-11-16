import 'dart:math' as math;
import 'dart:typed_data';

/// Palette slots; the renderer maps each one to a design-token color.
enum EffectColor { white, shard, echo, danger }

/// Reusable floating label (e.g. "+50"). Lives in a fixed pool.
class FloatingText {
  bool active = false;
  double x = 0;
  double y = 0;
  double age = 0;
  double duration = 1;
  double scale = 1;
  String text = '';
  EffectColor color = EffectColor.white;

  /// 0 -> 1 over its lifetime.
  double get progress => duration <= 0 ? 1 : (age / duration).clamp(0.0, 1.0);
}

/// Pure-Dart visual effects model: pooled particles, screen shake,
/// impact flash and floating texts. No Flutter/Flame imports, so it is unit
/// testable. Everything lives in fixed-size pools (no per-frame allocation).
class EffectsSystem {
  EffectsSystem({
    this.particleCapacity = 160,
    this.textCapacity = 6,
    int seed = 20240607,
  })  : _seed = seed & 0x7fffffff,
        _px = Float64List(particleCapacity),
        _py = Float64List(particleCapacity),
        _vx = Float64List(particleCapacity),
        _vy = Float64List(particleCapacity),
        _life = Float64List(particleCapacity),
        _maxLife = Float64List(particleCapacity),
        _size = Float64List(particleCapacity),
        _color = List<EffectColor>.filled(particleCapacity, EffectColor.white),
        texts = List<FloatingText>.generate(textCapacity, (_) => FloatingText());

  final int particleCapacity;
  final int textCapacity;

  /// When true: no shake, softer flash, fewer particles, no trail.
  bool reducedMotion = false;

  final List<FloatingText> texts;

  final Float64List _px;
  final Float64List _py;
  final Float64List _vx;
  final Float64List _vy;
  final Float64List _life;
  final Float64List _maxLife;
  final Float64List _size;
  final List<EffectColor> _color;
  int _count = 0;

  int _seed;
  double _shakeTime = 0;
  double _shakeDuration = 1;
  double _shakeAmplitude = 0;
  double _trailTimer = 0;

  double shakeX = 0;
  double shakeY = 0;

  /// 0..1 full-screen impact flash strength.
  double flash = 0;

  int get activeParticles => _count;

  // ---- particle read access for the renderer ----
  double particleX(int i) => _px[i];
  double particleY(int i) => _py[i];
  double particleSize(int i) => _size[i];
  EffectColor particleColor(int i) => _color[i];

  /// 1 = just born, 0 = about to vanish.
  double particleLife(int i) => _maxLife[i] <= 0 ? 0 : _life[i] / _maxLife[i];

  double _next() {
    _seed = (_seed * 1103515245 + 12345) & 0x7fffffff;
    return _seed / 0x7fffffff;
  }

  /// Spawns up to [count] particles; extras are dropped when the pool is full.
  /// [ring] spaces them evenly (a shockwave) instead of randomly.
  void burst(
    double x,
    double y, {
    required int count,
    required double speed,
    required EffectColor color,
    double size = 3,
    double life = 0.6,
    bool ring = false,
  }) {
    final n = reducedMotion ? count ~/ 3 : count;
    for (var i = 0; i < n && _count < particleCapacity; i++) {
      final angle = ring ? (i / n) * math.pi * 2 : _next() * math.pi * 2;
      final sp = ring ? speed : speed * (0.4 + 0.6 * _next());
      final l = life * (0.7 + 0.6 * _next());
      final k = _count++;
      _px[k] = x;
      _py[k] = y;
      _vx[k] = math.cos(angle) * sp;
      _vy[k] = math.sin(angle) * sp;
      _life[k] = l;
      _maxLife[k] = l;
      _size[k] = size;
      _color[k] = color;
    }
  }

  /// Soft purple dust behind the Future Echo (skipped in reduced motion).
  void emitTrail(double x, double y, double dt) {
    if (reducedMotion) return;
    _trailTimer += dt;
    if (_trailTimer < 0.035) return;
    _trailTimer = 0;
    if (_count >= particleCapacity) return;
    final k = _count++;
    _px[k] = x + (_next() - 0.5) * 6;
    _py[k] = y + (_next() - 0.5) * 6;
    _vx[k] = (_next() - 0.5) * 14;
    _vy[k] = (_next() - 0.5) * 14;
    _life[k] = 0.55;
    _maxLife[k] = 0.55;
    _size[k] = 2.2;
    _color[k] = EffectColor.echo;
  }

  void shake({required double amplitude, double duration = 0.3}) {
    if (reducedMotion) return;
    _shakeAmplitude = amplitude;
    _shakeDuration = duration <= 0 ? 0.01 : duration;
    _shakeTime = duration;
  }

  void impactFlash([double strength = 0.45]) {
    flash = reducedMotion ? math.min(strength, 0.12) : strength;
  }

  void spawnText(
    double x,
    double y,
    String text, {
    EffectColor color = EffectColor.white,
    double scale = 1,
    double duration = 0.9,
  }) {
    FloatingText? slot;
    for (final t in texts) {
      if (!t.active) {
        slot = t;
        break;
      }
    }
    // Pool full: recycle the oldest one so feedback is never lost.
    slot ??= texts.reduce((a, b) => a.age >= b.age ? a : b);
    slot
      ..active = true
      ..x = x
      ..y = y
      ..age = 0
      ..duration = duration
      ..scale = scale
      ..text = text
      ..color = color;
  }

  void update(double dt) {
    if (dt <= 0) return;

    var i = 0;
    final damp = math.max(0.0, 1 - 2.2 * dt);
    while (i < _count) {
      _life[i] -= dt;
      if (_life[i] <= 0) {
        _count--;
        if (i != _count) {
          final last = _count;
          _px[i] = _px[last];
          _py[i] = _py[last];
          _vx[i] = _vx[last];
          _vy[i] = _vy[last];
          _life[i] = _life[last];
          _maxLife[i] = _maxLife[last];
          _size[i] = _size[last];
          _color[i] = _color[last];
        }
        continue;
      }
      _px[i] += _vx[i] * dt;
      _py[i] += _vy[i] * dt;
      _vx[i] *= damp;
      _vy[i] *= damp;
      i++;
    }

    for (final t in texts) {
      if (!t.active) continue;
      t.age += dt;
      t.y -= 38 * dt;
      if (t.age >= t.duration) t.active = false;
    }

    if (_shakeTime > 0) {
      _shakeTime -= dt;
      final f = _shakeTime <= 0 ? 0.0 : _shakeTime / _shakeDuration;
      final a = _shakeAmplitude * f;
      shakeX = (_next() * 2 - 1) * a;
      shakeY = (_next() * 2 - 1) * a;
    } else {
      shakeX = 0;
      shakeY = 0;
    }

    if (flash > 0) {
      flash -= dt * 2.6;
      if (flash < 0) flash = 0;
    }
  }

  /// Clears every effect (new run).
  void reset() {
    _count = 0;
    _shakeTime = 0;
    _trailTimer = 0;
    shakeX = 0;
    shakeY = 0;
    flash = 0;
    for (final t in texts) {
      t.active = false;
    }
  }
}
