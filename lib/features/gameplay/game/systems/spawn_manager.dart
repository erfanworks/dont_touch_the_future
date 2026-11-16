import 'dart:math' as math;

import '../../../../core/constants/game_constants.dart';
import 'difficulty_manager.dart';

enum SpawnRequest { none, staticObstacle, movingObstacle, shard }

/// Simple circle used for spawn-safety checks.
class CircleBody {
  const CircleBody(this.x, this.y, this.radius);
  final double x;
  final double y;
  final double radius;
}

/// Decides WHEN to spawn (timers + difficulty targets) and WHERE
/// (random candidates filtered by strict safety rules).
class SpawnManager {
  SpawnManager({
    math.Random? random,
    DifficultyManager difficulty = const DifficultyManager(),
  })  : _random = random ?? math.Random(),
        _difficulty = difficulty;

  final math.Random _random;
  final DifficultyManager _difficulty;

  double _obstacleTimer = 0;
  double _shardTimer = 0;

  math.Random get random => _random;

  void reset() {
    _obstacleTimer = 0;
    _shardTimer = 0;
  }

  SpawnRequest update(
    double dt,
    double survivalSeconds, {
    required int staticCount,
    required int movingCount,
    required int shardCount,
  }) {
    _obstacleTimer += dt;
    _shardTimer += dt;

    final interval = _difficulty.obstacleSpawnInterval(survivalSeconds);
    if (_obstacleTimer >= interval) {
      if (staticCount < _difficulty.targetStaticObstacles(survivalSeconds)) {
        return SpawnRequest.staticObstacle;
      }
      if (movingCount < _difficulty.targetMovingObstacles(survivalSeconds)) {
        return SpawnRequest.movingObstacle;
      }
    }
    if (_shardTimer >= GameConstants.shardSpawnIntervalSeconds &&
        shardCount < _difficulty.targetShards(survivalSeconds)) {
      return SpawnRequest.shard;
    }
    return SpawnRequest.none;
  }

  void notifySpawned(SpawnRequest request) {
    if (request == SpawnRequest.shard) {
      _shardTimer = 0;
    } else if (request != SpawnRequest.none) {
      _obstacleTimer = 0;
    }
  }

  /// No safe spot was found: retry shortly instead of every frame.
  void notifySpawnFailed(SpawnRequest request) {
    const back = GameConstants.spawnRetryBackoffSeconds;
    if (request == SpawnRequest.shard) {
      _shardTimer -= back;
    } else if (request != SpawnRequest.none) {
      _obstacleTimer -= back;
    }
  }

  /// Called when the player picks up a shard, so the next one is delayed.
  void notifyShardCollected() => _shardTimer = 0;

  /// Returns a safe center point, or null if none was found in [attempts] tries.
  ///
  /// A point is safe when it is inside the arena, far enough from the player
  /// and the (active) echo, and clear of every other body by [gap].
  ({double x, double y})? findPoint({
    required double radius,
    required double minX,
    required double minY,
    required double maxX,
    required double maxY,
    required double playerX,
    required double playerY,
    required double minPlayerDistance,
    required bool echoActive,
    double echoX = 0,
    double echoY = 0,
    double minEchoDistance = 0,
    required List<CircleBody> others,
    required double gap,
    int attempts = 30,
  }) {
    final lowX = minX + radius;
    final highX = maxX - radius;
    final lowY = minY + radius;
    final highY = maxY - radius;
    if (highX <= lowX || highY <= lowY) return null;

    for (var i = 0; i < attempts; i++) {
      final x = lowX + _random.nextDouble() * (highX - lowX);
      final y = lowY + _random.nextDouble() * (highY - lowY);

      if (_distSq(x, y, playerX, playerY) <
          minPlayerDistance * minPlayerDistance) {
        continue;
      }
      if (echoActive &&
          _distSq(x, y, echoX, echoY) < minEchoDistance * minEchoDistance) {
        continue;
      }
      var clear = true;
      for (final o in others) {
        final need = radius + o.radius + gap;
        if (_distSq(x, y, o.x, o.y) < need * need) {
          clear = false;
          break;
        }
      }
      if (clear) return (x: x, y: y);
    }
    return null;
  }

  static double _distSq(double ax, double ay, double bx, double by) {
    final dx = ax - bx;
    final dy = ay - by;
    return dx * dx + dy * dy;
  }
}
