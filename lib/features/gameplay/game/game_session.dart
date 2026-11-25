import 'dart:math' as math;

import '../../../core/constants/game_constants.dart';
import 'models/game_state.dart';
import 'systems/collision_system.dart';
import 'systems/difficulty_manager.dart';
import 'systems/game_state_machine.dart';
import 'systems/movement_history.dart';
import 'systems/player_motion.dart';
import 'systems/scoring_system.dart';
import 'systems/spawn_manager.dart';

enum GameEventType {
  shardCollected,
  milestone,
  phaseChanged,
  graze,
  secondEcho,
  died,
}

enum DeathCause { echo, obstacle }

class GameEvent {
  const GameEvent(
    this.type, {
    this.x = 0,
    this.y = 0,
    this.value = 0,
    this.multiplier = 1.0,
    this.cause,
  });

  final GameEventType type;
  final double x;
  final double y;

  /// Points (shard / graze), milestone seconds, or phase index.
  final int value;

  /// Combo multiplier (shard) or phase score multiplier (phase change).
  final double multiplier;

  /// Death cause, or which hazard was grazed.
  final DeathCause? cause;
}

typedef GameEventListener = void Function(GameEvent event);

class ObstacleState {
  ObstacleState({
    required this.x,
    required this.y,
    required this.radius,
    this.vx = 0,
    this.vy = 0,
    this.isMoving = false,
  });

  double x;
  double y;
  final double radius;
  double vx;
  double vy;
  final bool isMoving;

  /// Seconds since it appeared.
  double age = 0;

  /// Gameplay time of the last graze bonus from this obstacle.
  double lastGrazeAt = -1e9;

  /// 0..1 telegraph progress; it is harmless until this reaches 1.
  double get armProgress {
    final p = age / GameConstants.obstacleArmSeconds;
    return p > 1 ? 1 : p;
  }

  bool get isArmed => age >= GameConstants.obstacleArmSeconds;
}

class ShardState {
  ShardState({required this.x, required this.y, required this.radius});
  final double x;
  final double y;
  final double radius;
  double age = 0;
}

/// The whole game simulation, with ZERO Flutter/Flame dependencies.
///
/// Flame only (1) forwards input and time to this class and (2) draws its
/// state. Keeping the rules here makes them deterministic and unit testable.
class GameSession {
  GameSession({
    math.Random? random,
    DifficultyManager difficulty = const DifficultyManager(),
  })  : _difficulty = difficulty,
        _spawn = SpawnManager(random: random, difficulty: difficulty);

  final DifficultyManager _difficulty;
  final SpawnManager _spawn;
  final GameStateMachine _machine = GameStateMachine();

  final ScoringSystem scoring = ScoringSystem();
  final MovementHistory history = MovementHistory();
  final PlayerMotion player = PlayerMotion();
  final List<ObstacleState> obstacles = <ObstacleState>[];
  final List<ShardState> shards = <ShardState>[];
  final MutablePoint _echoPoint = MutablePoint();
  final MutablePoint _echo2Point = MutablePoint();

  GameEventListener? onEvent;

  /// QA/testing switch: when false nothing can kill the player (and no grazes).
  bool collisionsEnabled = true;

  // --- arena ---
  double arenaWidth = 0;
  double arenaHeight = 0;
  double unit = 1;
  double arenaLeft = 0;
  double arenaTop = 0;
  double arenaRight = 0;
  double arenaBottom = 0;

  // --- run state ---
  double gameTime = 0;
  DifficultyPhase phase = DifficultyPhase.awakening;
  DeathCause? deathCause;
  int runId = 0;
  int _staticCount = 0;
  int _movingCount = 0;
  bool _echoActive = false;
  bool _echo2Active = false;
  double _echo2BornAt = 0;
  double _echoGrazeAt = -1e9;
  double _echo2GrazeAt = -1e9;
  ({double w, double h, double top, double bottom, double left, double right})?
      _pendingLayout;

  GameStatus get status => _machine.status;
  bool get isPlaying => _machine.isPlaying;
  int get score => scoring.score;

  bool get echoActive => _echoActive;
  double get echoX => _echoPoint.x;
  double get echoY => _echoPoint.y;

  /// 0..1 while the echo fades in (it is harmless until 1).
  double get echoFade {
    if (!_echoActive) return 0;
    final p = (gameTime - GameConstants.echoDelaySeconds) /
        GameConstants.echoSpawnGraceSeconds;
    return p < 0 ? 0 : (p > 1 ? 1 : p);
  }

  bool get echoArmed => _echoActive && echoFade >= 1;

  // Second (older) echo.
  bool get echo2Active => _echo2Active;
  double get echo2X => _echo2Point.x;
  double get echo2Y => _echo2Point.y;

  double get echo2Fade {
    if (!_echo2Active) return 0;
    final p = (gameTime - _echo2BornAt) / GameConstants.echoSpawnGraceSeconds;
    return p < 0 ? 0 : (p > 1 ? 1 : p);
  }

  bool get echo2Armed => _echo2Active && echo2Fade >= 1;

  /// Score multiplier of the current phase (x1.0 .. x2.0).
  double get phaseMultiplier => GameConstants.phaseScoreMultipliers[phase.index];

  /// Current shard-chain length (0 when no combo is running).
  int get comboChain => scoring.comboChainAt(gameTime);

  double get playerRadius => GameConstants.playerRadius * unit;
  double get echoRadius => GameConstants.echoRadius * unit;

  // ---------------------------------------------------------------- setup

  /// Called with the real canvas size and the device safe-area insets.
  /// Moves initializing -> ready. While a run is playing, paused or over, the
  /// layout is remembered and applied on the next [reset], so a resize can
  /// never wipe a running game or the Game Over scene.
  void configureArena(
    double width,
    double height, {
    double insetTop = 0,
    double insetBottom = 0,
    double insetLeft = 0,
    double insetRight = 0,
  }) {
    if (width <= 0 || height <= 0) return;
    final layout = (
      w: width,
      h: height,
      top: insetTop,
      bottom: insetBottom,
      left: insetLeft,
      right: insetRight,
    );
    final s = _machine.status;
    if (s == GameStatus.playing ||
        s == GameStatus.paused ||
        s == GameStatus.gameOver) {
      _pendingLayout = layout;
      return;
    }
    _applyLayout(layout);
    if (s == GameStatus.initializing) {
      _machine.transitionTo(GameStatus.ready);
    }
    _resetWorld();
  }

  /// The arena starts below the HUD band so the score never hides gameplay,
  /// and stays clear of notches and gesture bars.
  void _applyLayout(
    ({
      double w,
      double h,
      double top,
      double bottom,
      double left,
      double right
    }) l,
  ) {
    arenaWidth = l.w;
    arenaHeight = l.h;
    final raw = l.w / GameConstants.designWidth;
    unit = raw < GameConstants.minWorldUnit
        ? GameConstants.minWorldUnit
        : (raw > GameConstants.maxWorldUnit ? GameConstants.maxWorldUnit : raw);

    final pad = GameConstants.arenaPadding * unit;
    arenaLeft = pad + l.left;
    arenaRight = l.w - pad - l.right;
    arenaTop = l.top + GameConstants.hudReservedHeight;
    arenaBottom = l.h - pad - l.bottom;

    final r = playerRadius;
    player.configure(
      radius: r,
      speed: GameConstants.playerSpeed * unit,
      followRadius: GameConstants.dragFollowRadius * unit,
      deadZone: GameConstants.dragDeadZone * unit,
      minX: arenaLeft + r,
      minY: arenaTop + r,
      maxX: arenaRight - r,
      maxY: arenaBottom - r,
    );
  }

  void _resetWorld() {
    gameTime = 0;
    history.clear();
    obstacles.clear();
    shards.clear();
    scoring.reset();
    _spawn.reset();
    _staticCount = 0;
    _movingCount = 0;
    _echoActive = false;
    _echo2Active = false;
    _echo2BornAt = 0;
    _echoGrazeAt = -1e9;
    _echo2GrazeAt = -1e9;
    _echoPoint
      ..x = 0
      ..y = 0;
    _echo2Point
      ..x = 0
      ..y = 0;
    deathCause = null;
    phase = DifficultyPhase.awakening;
    player.reset(
      (arenaLeft + arenaRight) / 2,
      arenaTop + (arenaBottom - arenaTop) * GameConstants.playerStartYFraction,
    );
    runId++;
  }

  // ---------------------------------------------------------- state control

  /// ready -> playing. Starts the clock and records the first sample.
  bool start() {
    if (!_machine.transitionTo(GameStatus.playing)) return false;
    history.record(0, player.x, player.y);
    return true;
  }

  bool pause() {
    if (!_machine.transitionTo(GameStatus.paused)) return false;
    player.dragEnd();
    return true;
  }

  bool resume() => _machine.transitionTo(GameStatus.playing);

  /// Full restart: allowed from paused / gameOver (or already ready).
  /// Clears history, entities and score so nothing leaks into the next run.
  bool reset() {
    if (_machine.status != GameStatus.ready &&
        !_machine.transitionTo(GameStatus.ready)) {
      return false;
    }
    final pending = _pendingLayout;
    if (pending != null) {
      _pendingLayout = null;
      _applyLayout(pending);
    }
    _resetWorld();
    return true;
  }

  // ------------------------------------------------------------------ input

  /// A touch-drag begins. The first drag starts the run.
  void beginDrag() {
    if (_machine.status == GameStatus.ready) start();
    if (_machine.isPlaying) player.dragStart();
  }

  void dragBy(double dx, double dy) {
    if (_machine.isPlaying) player.dragUpdate(dx, dy);
  }

  void endDrag() => player.dragEnd();

  // ----------------------------------------------------------------- update

  void update(double dt) {
    if (!_machine.isPlaying || dt <= 0) return;
    if (dt > GameConstants.maxFrameDeltaSeconds) {
      dt = GameConstants.maxFrameDeltaSeconds;
    }

    gameTime += dt;
    player.update(dt);
    history.record(gameTime, player.x, player.y);

    _echoActive = gameTime >= GameConstants.echoDelaySeconds;
    if (_echoActive) {
      history.sampleAt(gameTime - GameConstants.echoDelaySeconds, _echoPoint);
    }

    if (!_echo2Active && _difficulty.secondEchoActiveAt(gameTime)) {
      _echo2Active = true;
      _echo2BornAt = gameTime;
      onEvent?.call(const GameEvent(GameEventType.secondEcho));
    }
    if (_echo2Active) {
      history.sampleAt(
        gameTime - GameConstants.secondEchoDelaySeconds,
        _echo2Point,
      );
    }

    final milestone =
        scoring.addSurvivalTime(dt, multiplier: phaseMultiplier);
    if (milestone > 0) {
      onEvent?.call(GameEvent(GameEventType.milestone, value: milestone));
    }

    final newPhase = _difficulty.phaseAt(scoring.survivalSeconds);
    if (newPhase != phase) {
      phase = newPhase;
      if (phase.index >= DifficultyPhase.pressure.index) {
        _spawn.holdObstacleSpawns(GameConstants.phaseBreatherSeconds);
      }
      onEvent?.call(GameEvent(
        GameEventType.phaseChanged,
        value: phase.index,
        multiplier: phaseMultiplier,
      ));
    }

    _updateEntities(dt);
    _updateSpawning(dt);
    _checkCollisions();
  }

  void _updateEntities(double dt) {
    for (final s in shards) {
      s.age += dt;
    }
    for (final o in obstacles) {
      o.age += dt;
      if (!o.isMoving || !o.isArmed) continue;
      o.x += o.vx * dt;
      o.y += o.vy * dt;
      final minX = arenaLeft + o.radius;
      final maxX = arenaRight - o.radius;
      final minY = arenaTop + o.radius;
      final maxY = arenaBottom - o.radius;
      if (o.x < minX) {
        o.x = minX;
        o.vx = o.vx.abs();
      } else if (o.x > maxX) {
        o.x = maxX;
        o.vx = -o.vx.abs();
      }
      if (o.y < minY) {
        o.y = minY;
        o.vy = o.vy.abs();
      } else if (o.y > maxY) {
        o.y = maxY;
        o.vy = -o.vy.abs();
      }
    }
  }

  void _updateSpawning(double dt) {
    final t = scoring.survivalSeconds;
    final request = _spawn.update(
      dt,
      t,
      staticCount: _staticCount,
      movingCount: _movingCount,
      shardCount: shards.length,
    );
    if (request == SpawnRequest.none) return;

    final isShard = request == SpawnRequest.shard;
    final isMoving = request == SpawnRequest.movingObstacle;
    final radius = (isShard
            ? GameConstants.shardRadius
            : (isMoving
                ? GameConstants.movingObstacleRadius
                : GameConstants.staticObstacleRadius)) *
        unit;

    final point = _spawn.findPoint(
      radius: radius,
      minX: arenaLeft,
      minY: arenaTop,
      maxX: arenaRight,
      maxY: arenaBottom,
      playerX: player.x,
      playerY: player.y,
      minPlayerDistance: (isShard
              ? _difficulty.shardMinPlayerDistance(t)
              : GameConstants.spawnMinPlayerDistance) *
          unit,
      echoActive: _echoActive,
      echoX: _echoPoint.x,
      echoY: _echoPoint.y,
      minEchoDistance: GameConstants.spawnMinEchoDistance * unit,
      echo2Active: _echo2Active,
      echo2X: _echo2Point.x,
      echo2Y: _echo2Point.y,
      others: _occupiedBodies(),
      gap: GameConstants.spawnGap * unit,
    );

    if (point == null) {
      _spawn.notifySpawnFailed(request);
      return;
    }

    if (isShard) {
      spawnShardAt(point.x, point.y);
    } else if (isMoving) {
      final angle = _spawn.random.nextDouble() * math.pi * 2;
      final speed = _difficulty.movingObstacleSpeed(t) * unit;
      spawnMovingObstacleAt(
        point.x,
        point.y,
        math.cos(angle) * speed,
        math.sin(angle) * speed,
      );
    } else {
      spawnStaticObstacleAt(point.x, point.y);
    }
    _spawn.notifySpawned(request);
  }

  List<CircleBody> _occupiedBodies() {
    return <CircleBody>[
      for (final o in obstacles) CircleBody(o.x, o.y, o.radius),
      for (final s in shards) CircleBody(s.x, s.y, s.radius),
    ];
  }

  // Public so tests (and future special modes) can place entities exactly.
  void spawnStaticObstacleAt(double x, double y) {
    obstacles.add(ObstacleState(
      x: x,
      y: y,
      radius: GameConstants.staticObstacleRadius * unit,
    ));
    _staticCount++;
  }

  void spawnMovingObstacleAt(double x, double y, double vx, double vy) {
    obstacles.add(ObstacleState(
      x: x,
      y: y,
      radius: GameConstants.movingObstacleRadius * unit,
      vx: vx,
      vy: vy,
      isMoving: true,
    ));
    _movingCount++;
  }

  void spawnShardAt(double x, double y) {
    shards.add(ShardState(
      x: x,
      y: y,
      radius: GameConstants.shardRadius * unit,
    ));
  }

  // -------------------------------------------------------------- collisions

  void _checkCollisions() {
    // Shards first: a pickup on the same frame as a hit still counts.
    for (var i = shards.length - 1; i >= 0; i--) {
      final s = shards[i];
      if (CollisionSystem.circlesOverlap(
        player.x,
        player.y,
        playerRadius,
        s.x,
        s.y,
        s.radius,
      )) {
        shards.removeAt(i);
        final points = scoring.collectShard(gameTime);
        _spawn.notifyShardCollected();
        onEvent?.call(GameEvent(
          GameEventType.shardCollected,
          x: s.x,
          y: s.y,
          value: points,
          multiplier: points / GameConstants.shardPoints,
        ));
      }
    }

    if (!collisionsEnabled) return;

    final hitRadius = playerRadius * GameConstants.hazardHitboxFactor;

    for (final o in obstacles) {
      if (o.isArmed &&
          CollisionSystem.circlesOverlap(
            player.x,
            player.y,
            hitRadius,
            o.x,
            o.y,
            o.radius,
          )) {
        _die(DeathCause.obstacle);
        return;
      }
    }

    if (echoArmed &&
        CollisionSystem.circlesOverlap(
          player.x,
          player.y,
          hitRadius,
          _echoPoint.x,
          _echoPoint.y,
          echoRadius,
        )) {
      _die(DeathCause.echo);
      return;
    }

    if (echo2Armed &&
        CollisionSystem.circlesOverlap(
          player.x,
          player.y,
          hitRadius,
          _echo2Point.x,
          _echo2Point.y,
          echoRadius,
        )) {
      _die(DeathCause.echo);
      return;
    }

    _checkGrazes(hitRadius);
  }

  /// Near-miss bonus: reward surviving right next to a hazard.
  /// Each hazard has its own cooldown so hovering cannot be farmed.
  void _checkGrazes(double hitRadius) {
    final margin = GameConstants.grazeMargin * unit;
    const cooldown = GameConstants.grazeCooldownSeconds;

    for (final o in obstacles) {
      if (!o.isArmed || gameTime - o.lastGrazeAt < cooldown) continue;
      final reach = hitRadius + o.radius + margin;
      if (_distSq(player.x, player.y, o.x, o.y) < reach * reach) {
        o.lastGrazeAt = gameTime;
        _award(GameConstants.grazeObstaclePoints, DeathCause.obstacle);
      }
    }

    final echoReach = hitRadius + echoRadius + margin;
    if (echoArmed &&
        gameTime - _echoGrazeAt >= cooldown &&
        _distSq(player.x, player.y, _echoPoint.x, _echoPoint.y) <
            echoReach * echoReach) {
      _echoGrazeAt = gameTime;
      _award(GameConstants.grazeEchoPoints, DeathCause.echo);
    }
    if (echo2Armed &&
        gameTime - _echo2GrazeAt >= cooldown &&
        _distSq(player.x, player.y, _echo2Point.x, _echo2Point.y) <
            echoReach * echoReach) {
      _echo2GrazeAt = gameTime;
      _award(GameConstants.grazeEchoPoints, DeathCause.echo);
    }
  }

  void _award(int points, DeathCause hazard) {
    scoring.addGraze(points);
    onEvent?.call(GameEvent(
      GameEventType.graze,
      x: player.x,
      y: player.y,
      value: points,
      cause: hazard,
    ));
  }

  static double _distSq(double ax, double ay, double bx, double by) {
    final dx = ax - bx;
    final dy = ay - by;
    return dx * dx + dy * dy;
  }

  void _die(DeathCause cause) {
    if (!_machine.transitionTo(GameStatus.gameOver)) return;
    deathCause = cause;
    player.dragEnd();
    onEvent?.call(GameEvent(
      GameEventType.died,
      x: player.x,
      y: player.y,
      cause: cause,
    ));
  }
}
