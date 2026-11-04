/// Pure Dart game tuning values. No Flutter/Flame imports on purpose,
/// so every system that uses these can be unit tested without a device.
class GameConstants {
  const GameConstants._();

  // --- Future Echo ---
  /// The ghost replays the player's path exactly this many seconds later.
  static const double echoDelaySeconds = 3.0;

  /// Extra history kept beyond the delay so interpolation never runs dry.
  static const double historyMarginSeconds = 0.5;

  /// Echo stays harmless for this long after appearing (fair-play fade-in).
  static const double echoSpawnGraceSeconds = 0.5;

  // --- Frame safety ---
  /// Any frame longer than this is clamped (e.g. after a lag spike).
  static const double maxFrameDeltaSeconds = 1 / 20;

  // --- Player / entities (logical units relative to arena) ---
  static const double playerRadius = 14;
  static const double echoRadius = 14;
  static const double shardRadius = 9;

  // --- Scoring ---
  static const int survivalPointsPerSecond = 10;
  static const int shardPoints = 50;

  // --- Difficulty phase start times (seconds survived) ---
  static const double phaseAwarenessStart = 15;
  static const double phasePressureStart = 30;
  static const double phaseSurvivalStart = 60;
  static const double phaseChaosStart = 90;
}
