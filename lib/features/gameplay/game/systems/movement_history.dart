import 'dart:typed_data';

import '../../../../core/constants/game_constants.dart';

/// Reusable output holder so lookups never allocate.
class MutablePoint {
  double x = 0;
  double y = 0;
}

/// Fixed-size, timestamp-based rolling buffer of the player's trajectory.
///
/// * Times are gameplay-clock seconds (strictly increasing).
/// * The buffer never grows: the oldest sample is overwritten when full.
/// * [sampleAt] does a binary search + linear interpolation, so the Future
///   Echo stays exact and smooth at any frame rate.
class MovementHistory {
  MovementHistory({
    int capacity = GameConstants.historyCapacity,
    double minSampleInterval = GameConstants.historyMinSampleInterval,
  })  : assert(capacity >= 2),
        _capacity = capacity,
        _minInterval = minSampleInterval,
        _times = Float64List(capacity),
        _xs = Float64List(capacity),
        _ys = Float64List(capacity);

  final int _capacity;
  final double _minInterval;
  final Float64List _times;
  final Float64List _xs;
  final Float64List _ys;

  int _start = 0; // physical index of the oldest sample
  int _count = 0;

  int get count => _count;
  int get capacity => _capacity;
  bool get isEmpty => _count == 0;

  double? get oldestTime => _count == 0 ? null : _times[_start];
  double? get newestTime => _count == 0 ? null : _times[_phys(_count - 1)];

  int _phys(int logical) => (_start + logical) % _capacity;

  /// Forgets everything. Called on every new game so no history can leak.
  void clear() {
    _start = 0;
    _count = 0;
  }

  /// Records a sample. Returns false if it was skipped because it is too
  /// close in time to the previous one (or not newer than it).
  bool record(double time, double x, double y) {
    if (_count > 0 && time - _times[_phys(_count - 1)] < _minInterval) {
      return false;
    }
    final int index;
    if (_count == _capacity) {
      index = _start; // overwrite oldest
      _start = (_start + 1) % _capacity;
    } else {
      index = _phys(_count);
      _count++;
    }
    _times[index] = time;
    _xs[index] = x;
    _ys[index] = y;
    return true;
  }

  /// Writes the interpolated position at [time] into [out].
  /// Times outside the stored range are clamped to the nearest end.
  /// Returns false only when the buffer is empty.
  bool sampleAt(double time, MutablePoint out) {
    if (_count == 0) return false;

    final first = _start;
    if (time <= _times[first]) {
      out.x = _xs[first];
      out.y = _ys[first];
      return true;
    }
    final last = _phys(_count - 1);
    if (time >= _times[last]) {
      out.x = _xs[last];
      out.y = _ys[last];
      return true;
    }

    // Invariant: time(lo) < time < time(hi)
    var lo = 0;
    var hi = _count - 1;
    while (hi - lo > 1) {
      final mid = (lo + hi) >> 1;
      if (_times[_phys(mid)] <= time) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    final a = _phys(lo);
    final b = _phys(hi);
    final span = _times[b] - _times[a];
    final f = span <= 0 ? 0.0 : (time - _times[a]) / span;
    out.x = _xs[a] + (_xs[b] - _xs[a]) * f;
    out.y = _ys[a] + (_ys[b] - _ys[a]) * f;
    return true;
  }
}
