/// One recorded point of the player's trajectory.
///
/// [time] is gameplay-clock time in seconds (NOT wall-clock time), so pauses
/// and app backgrounding never distort the Future Echo timeline.
class MovementSample {
  const MovementSample({
    required this.time,
    required this.x,
    required this.y,
  });

  final double time;
  final double x;
  final double y;

  @override
  String toString() => 'MovementSample(t=$time, x=$x, y=$y)';

  @override
  bool operator ==(Object other) =>
      other is MovementSample &&
      other.time == time &&
      other.x == x &&
      other.y == y;

  @override
  int get hashCode => Object.hash(time, x, y);
}
