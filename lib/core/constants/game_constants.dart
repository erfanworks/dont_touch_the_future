/// Pure Dart game tuning values. No Flutter/Flame imports on purpose,
/// so every system that uses these can be unit tested without a device.
///
/// Distances/speeds are expressed in "design units" for a 390 px wide
/// screen. The game multiplies them by a per-device `unit` factor.
class GameConstants {
  const GameConstants._();

  // --- World scaling ---
  static const double designWidth = 390;
  static const double minWorldUnit = 0.8;
  static const double maxWorldUnit = 1.6;
  static const double arenaPadding = 14;

  /// Logical px reserved under the status bar for the HUD (score + pause).
  static const double hudReservedHeight = 92;

  // --- Future Echo ---
  /// The ghost replays the player's path exactly this many seconds later.
  static const double echoDelaySeconds = 3.0;

  /// A SECOND, older echo joins in the Chaos phase and replays 6 s later.
  static const double secondEchoDelaySeconds = 6.0;
  static const double secondEchoStartSeconds = 120;

  /// Extra history kept beyond the longest delay so interpolation never runs dry.
  static const double historyMarginSeconds = 0.5;

  /// Echo stays harmless for this long after appearing (fair-play fade-in).
  static const double echoSpawnGraceSeconds = 0.5;

  // --- Movement history ring buffer ---
  /// Minimum gap between recorded samples (caps memory at high refresh rates).
  static const double historyMinSampleInterval = 1 / 120;

  /// (6.0 + 0.5) / (1/120) = 780 samples needed; 1024 leaves safe slack.
  static const int historyCapacity = 1024;

  // --- Frame safety ---
  /// Any frame longer than this is clamped (e.g. after a lag spike).
  static const double maxFrameDeltaSeconds = 1 / 20;

  // --- Player ---
  static const double playerRadius = 14;
  static const double playerSpeed = 240;
  static const double dragFollowRadius = 56;
  static const double dragDeadZone = 6;
  static const double playerStartYFraction = 0.62;

  /// Hazards use a slightly smaller player hitbox so deaths feel fair.
  static const double hazardHitboxFactor = 0.85;

  // --- Echo / obstacles / shards ---
  static const double echoRadius = 14;
  static const double shardRadius = 9;
  static const double staticObstacleRadius = 22;
  static const double movingObstacleRadius = 16;

  /// Obstacles are harmless (telegraphed) for this long after appearing.
  static const double obstacleArmSeconds = 1.0;

  // --- Spawn safety distances (design units) ---
  static const double spawnMinPlayerDistance = 150;
  static const double spawnMinEchoDistance = 90;
  static const double spawnGap = 40;
  static const double spawnRetryBackoffSeconds = 0.25;
  static const double shardSpawnIntervalSeconds = 2.0;

  /// After entering Pressure / Survival / Chaos, no NEW obstacles spawn for
  /// this long: a short breather so the player can read the new phase.
  static const double phaseBreatherSeconds = 4.0;

  // --- Scoring ---
  static const int survivalPointsPerSecond = 10;
  static const int shardPoints = 50;
  static const List<int> milestoneSeconds = [15, 30, 60, 90, 120];

  /// Survival-point multiplier per phase (index = DifficultyPhase.index).
  static const List<double> phaseScoreMultipliers = [1.0, 1.25, 1.5, 1.75, 2.0];

  /// Shards collected within this many seconds of each other build a combo.
  static const double comboWindowSeconds = 4.0;

  /// Shard point multiplier for chain length 1, 2, 3, 4, 5+.
  static const List<double> comboMultipliers = [1.0, 1.5, 2.0, 2.5, 3.0];

  // --- Graze (near-miss) bonuses ---
  /// How far beyond actual contact still counts as a near miss.
  static const double grazeMargin = 16;
  static const int grazeObstaclePoints = 10;
  static const int grazeEchoPoints = 20;

  /// Per-hazard cooldown, so hovering next to something cannot be farmed.
  static const double grazeCooldownSeconds = 3.0;

  // --- Difficulty phase start times (seconds survived) ---
  static const double phaseAwarenessStart = 15;
  static const double phasePressureStart = 30;
  static const double phaseSurvivalStart = 60;
  static const double phaseChaosStart = 90;
}
