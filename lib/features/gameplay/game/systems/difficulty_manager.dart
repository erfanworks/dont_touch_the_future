import '../../../../core/constants/game_constants.dart';

enum DifficultyPhase { awakening, awareness, pressure, survival, chaos }

/// Difficulty is a pure function of survival time: no random jumps.
/// Every value only ever stays equal or grows as time increases, and keeps
/// growing slowly in Chaos so the game never plateaus.
class DifficultyManager {
  const DifficultyManager();

  DifficultyPhase phaseAt(double t) {
    if (t < GameConstants.phaseAwarenessStart) return DifficultyPhase.awakening;
    if (t < GameConstants.phasePressureStart) return DifficultyPhase.awareness;
    if (t < GameConstants.phaseSurvivalStart) return DifficultyPhase.pressure;
    if (t < GameConstants.phaseChaosStart) return DifficultyPhase.survival;
    return DifficultyPhase.chaos;
  }

  /// 0 -> 1 (15s) -> 2..3 (30-60s) -> 3..4 (60-90s) -> 4..6 (90s+).
  int targetStaticObstacles(double t) {
    switch (phaseAt(t)) {
      case DifficultyPhase.awakening:
        return 0;
      case DifficultyPhase.awareness:
        return 1;
      case DifficultyPhase.pressure:
        return 2 + ((t - GameConstants.phasePressureStart) ~/ 15);
      case DifficultyPhase.survival:
        return 3 + ((t - GameConstants.phaseSurvivalStart) ~/ 20);
      case DifficultyPhase.chaos:
        final v = 4 + ((t - GameConstants.phaseChaosStart) ~/ 30);
        return v > 6 ? 6 : v;
    }
  }

  /// Moving obstacles appear from the Survival phase (60s+), up to 5.
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
        return v > 5 ? 5 : v;
    }
  }

  /// Chrono Shards are introduced together with the first obstacle (15s).
  int targetShards(double t) {
    if (t < GameConstants.phaseAwarenessStart) return 0;
    if (t < GameConstants.phaseSurvivalStart) return 1;
    return 2;
  }

  /// Design units / second. Ramps 70 -> 130 (60-135s), then slowly to 190.
  /// Always below the player's own speed (240), so it can be outrun.
  double movingObstacleSpeed(double t) {
    final first = ((t - GameConstants.phaseSurvivalStart) * 0.8).clamp(0.0, 60.0);
    final late = ((t - 135) * 0.25).clamp(0.0, 60.0);
    return 70 + first + late;
  }

  /// Seconds between obstacle spawns: 4.0 -> 3.0 (90s) -> 2.5 (150s).
  double obstacleSpawnInterval(double t) {
    if (t < GameConstants.phaseChaosStart) return 4.0;
    if (t < 150) return 3.0;
    return 2.5;
  }

  /// Later shards are placed farther from the player (more risk to reach).
  double shardMinPlayerDistance(double t) =>
      t < GameConstants.phasePressureStart ? 80 : 140;

  /// The second (older) echo joins from 120s.
  bool secondEchoActiveAt(double t) => t >= GameConstants.secondEchoStartSeconds;
}
