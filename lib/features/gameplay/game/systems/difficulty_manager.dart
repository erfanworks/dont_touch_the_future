import '../../../../core/constants/game_constants.dart';

enum DifficultyPhase { awakening, awareness, pressure, survival, chaos }

/// Difficulty is a pure function of survival time: no random jumps.
/// Values only ever stay equal or grow as time increases.
class DifficultyManager {
  const DifficultyManager();

  DifficultyPhase phaseAt(double t) {
    if (t < GameConstants.phaseAwarenessStart) return DifficultyPhase.awakening;
    if (t < GameConstants.phasePressureStart) return DifficultyPhase.awareness;
    if (t < GameConstants.phaseSurvivalStart) return DifficultyPhase.pressure;
    if (t < GameConstants.phaseChaosStart) return DifficultyPhase.survival;
    return DifficultyPhase.chaos;
  }

  /// 0 -> 1 (first obstacle at 15s) -> 2..3 -> 3 -> 4..5.
  int targetStaticObstacles(double t) {
    switch (phaseAt(t)) {
      case DifficultyPhase.awakening:
        return 0;
      case DifficultyPhase.awareness:
        return 1;
      case DifficultyPhase.pressure:
        return 2 + ((t - GameConstants.phasePressureStart) ~/ 15);
      case DifficultyPhase.survival:
        return 3;
      case DifficultyPhase.chaos:
        final v = 4 + ((t - GameConstants.phaseChaosStart) ~/ 30);
        return v > 5 ? 5 : v;
    }
  }

  /// Moving obstacles only appear from the Survival phase (60s+).
  int targetMovingObstacles(double t) {
    switch (phaseAt(t)) {
      case DifficultyPhase.awakening:
      case DifficultyPhase.awareness:
      case DifficultyPhase.pressure:
        return 0;
      case DifficultyPhase.survival:
        return 1 + ((t - GameConstants.phaseSurvivalStart) ~/ 15);
      case DifficultyPhase.chaos:
        final v = 2 + ((t - GameConstants.phaseChaosStart) ~/ 20);
        return v > 4 ? 4 : v;
    }
  }

  /// Chrono Shards are introduced together with the first obstacle (15s).
  int targetShards(double t) {
    if (t < GameConstants.phaseAwarenessStart) return 0;
    if (t < GameConstants.phaseSurvivalStart) return 1;
    return 2;
  }

  /// Design units / second.
  double movingObstacleSpeed(double t) {
    final extra = (t - GameConstants.phaseSurvivalStart) * 0.8;
    final clamped = extra < 0 ? 0.0 : (extra > 60 ? 60.0 : extra);
    return 70 + clamped;
  }

  /// Seconds between obstacle spawns.
  double obstacleSpawnInterval(double t) =>
      t < GameConstants.phaseChaosStart ? 4.0 : 3.0;

  /// Later shards are placed farther from the player (more risk to reach).
  double shardMinPlayerDistance(double t) =>
      t < GameConstants.phasePressureStart ? 80 : 140;
}
