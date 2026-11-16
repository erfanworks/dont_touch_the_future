import '../../../../core/constants/game_constants.dart';

/// All score rules live here (never in widgets).
/// score = floor(survivalSeconds * 10) + shards * 50
class ScoringSystem {
  double _survivalSeconds = 0;
  int _shards = 0;
  int _nextMilestoneIndex = 0;

  double get survivalSeconds => _survivalSeconds;
  int get shardsCollected => _shards;

  int get score =>
      (_survivalSeconds * GameConstants.survivalPointsPerSecond).floor() +
      _shards * GameConstants.shardPoints;

  /// Adds survival time. Returns the milestone (in seconds) reached during
  /// this call, or 0 when none. If several are crossed, the highest is returned.
  int addSurvivalTime(double dt) {
    if (dt <= 0) return 0;
    _survivalSeconds += dt;
    var reached = 0;
    const milestones = GameConstants.milestoneSeconds;
    while (_nextMilestoneIndex < milestones.length &&
        _survivalSeconds >= milestones[_nextMilestoneIndex]) {
      reached = milestones[_nextMilestoneIndex];
      _nextMilestoneIndex++;
    }
    return reached;
  }

  void collectShard() => _shards++;

  void reset() {
    _survivalSeconds = 0;
    _shards = 0;
    _nextMilestoneIndex = 0;
  }
}
