import '../../../../core/constants/game_constants.dart';

/// All score rules live here (never in widgets).
///
/// score = survival points (time x phase multiplier)
///       + shard points (with combo multiplier)
///       + graze (near-miss) bonuses
class ScoringSystem {
  double _survivalSeconds = 0;
  double _survivalPoints = 0;
  int _shardPoints = 0;
  int _bonusPoints = 0;
  int _shards = 0;
  int _grazes = 0;
  int _nextMilestoneIndex = 0;

  int _chain = 0;
  double _lastShardTime = -1e9;
  int _bestChain = 0;

  double get survivalSeconds => _survivalSeconds;
  int get shardsCollected => _shards;
  int get grazeCount => _grazes;
  int get bestChain => _bestChain;

  int get score => _survivalPoints.floor() + _shardPoints + _bonusPoints;

  /// Adds survival time. [multiplier] is the current phase's score multiplier.
  /// Returns the milestone (in seconds) reached during this call, or 0.
  int addSurvivalTime(double dt, {double multiplier = 1.0}) {
    if (dt <= 0) return 0;
    _survivalSeconds += dt;
    _survivalPoints += dt * GameConstants.survivalPointsPerSecond * multiplier;
    var reached = 0;
    const milestones = GameConstants.milestoneSeconds;
    while (_nextMilestoneIndex < milestones.length &&
        _survivalSeconds >= milestones[_nextMilestoneIndex]) {
      reached = milestones[_nextMilestoneIndex];
      _nextMilestoneIndex++;
    }
    return reached;
  }

  /// Collects a shard at gameplay time [now]. Shards picked up within the
  /// combo window of the previous one extend the chain.
  /// Returns the points awarded for THIS shard.
  int collectShard(double now) {
    if (_chain > 0 && now - _lastShardTime <= GameConstants.comboWindowSeconds) {
      _chain++;
    } else {
      _chain = 1;
    }
    _lastShardTime = now;
    if (_chain > _bestChain) _bestChain = _chain;

    final points = (GameConstants.shardPoints * _multiplierForChain(_chain)).round();
    _shardPoints += points;
    _shards++;
    return points;
  }

  /// Adds a near-miss bonus. Returns the points.
  int addGraze(int points) {
    if (points <= 0) return 0;
    _bonusPoints += points;
    _grazes++;
    return points;
  }

  static double _multiplierForChain(int chain) {
    const table = GameConstants.comboMultipliers;
    final i = chain - 1;
    return table[i >= table.length ? table.length - 1 : (i < 0 ? 0 : i)];
  }

  bool _comboAlive(double now) =>
      _chain > 0 && now - _lastShardTime <= GameConstants.comboWindowSeconds;

  /// Current chain length (0 when the combo has expired).
  int comboChainAt(double now) => _comboAlive(now) ? _chain : 0;

  /// Multiplier the NEXT shard would get if collected right now.
  double nextComboMultiplierAt(double now) =>
      _multiplierForChain(_comboAlive(now) ? _chain + 1 : 1);

  /// Seconds left before the combo expires (0 when there is none).
  double comboTimeLeftAt(double now) => _comboAlive(now)
      ? GameConstants.comboWindowSeconds - (now - _lastShardTime)
      : 0;

  void reset() {
    _survivalSeconds = 0;
    _survivalPoints = 0;
    _shardPoints = 0;
    _bonusPoints = 0;
    _shards = 0;
    _grazes = 0;
    _nextMilestoneIndex = 0;
    _chain = 0;
    _lastShardTime = -1e9;
    _bestChain = 0;
  }
}
