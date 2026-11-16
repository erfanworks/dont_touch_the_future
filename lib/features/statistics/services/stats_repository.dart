import '../models/run_summary.dart';

/// Storage contract used by [StatsRepository]. `StorageService` implements it;
/// tests use an in-memory fake, so no device or plugin is needed.
abstract interface class StatsStore {
  int get bestScore;
  double get bestSurvivalSeconds;
  int get gamesPlayed;
  int get totalShards;

  Future<void> setBestScore(int value);
  Future<void> setBestSurvivalSeconds(double value);
  Future<void> setGamesPlayed(int value);
  Future<void> setTotalShards(int value);
}

/// Central place for high-score / lifetime-stat rules.
class StatsRepository {
  StatsRepository(this._store);

  final StatsStore _store;

  int get bestScore => _store.bestScore;
  double get bestSurvivalSeconds => _store.bestSurvivalSeconds;

  Future<RunSummary> recordRun({
    required int score,
    required double survivalSeconds,
    required int shards,
  }) async {
    final previousBestScore = _store.bestScore;
    final previousBestTime = _store.bestSurvivalSeconds;

    final isNewBestScore = score > previousBestScore;
    final isNewBestTime = survivalSeconds > previousBestTime;

    await _store.setGamesPlayed(_store.gamesPlayed + 1);
    await _store.setTotalShards(_store.totalShards + shards);
    if (isNewBestScore) await _store.setBestScore(score);
    if (isNewBestTime) await _store.setBestSurvivalSeconds(survivalSeconds);

    return RunSummary(
      score: score,
      survivalSeconds: survivalSeconds,
      shards: shards,
      bestScore: isNewBestScore ? score : previousBestScore,
      bestSurvivalSeconds: isNewBestTime ? survivalSeconds : previousBestTime,
      isNewBestScore: isNewBestScore,
      isNewBestTime: isNewBestTime,
    );
  }
}
