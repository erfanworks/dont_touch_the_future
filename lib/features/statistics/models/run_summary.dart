/// Result of one finished run, after it has been saved.
class RunSummary {
  const RunSummary({
    required this.score,
    required this.survivalSeconds,
    required this.shards,
    required this.bestScore,
    required this.bestSurvivalSeconds,
    required this.isNewBestScore,
    required this.isNewBestTime,
  });

  final int score;
  final double survivalSeconds;
  final int shards;
  final int bestScore;
  final double bestSurvivalSeconds;
  final bool isNewBestScore;
  final bool isNewBestTime;
}
