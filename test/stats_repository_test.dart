import 'package:dont_touch_the_future/features/statistics/services/stats_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeStore implements StatsStore {
  @override
  int bestScore = 0;
  @override
  double bestSurvivalSeconds = 0;
  @override
  int gamesPlayed = 0;
  @override
  int totalShards = 0;

  @override
  Future<void> setBestScore(int value) async => bestScore = value;
  @override
  Future<void> setBestSurvivalSeconds(double value) async =>
      bestSurvivalSeconds = value;
  @override
  Future<void> setGamesPlayed(int value) async => gamesPlayed = value;
  @override
  Future<void> setTotalShards(int value) async => totalShards = value;
}

void main() {
  group('StatsRepository', () {
    test('first run becomes the best score and best time', () async {
      final store = FakeStore();
      final repo = StatsRepository(store);
      final r = await repo.recordRun(score: 120, survivalSeconds: 9, shards: 1);
      expect(r.isNewBestScore, isTrue);
      expect(r.isNewBestTime, isTrue);
      expect(store.bestScore, 120);
      expect(store.gamesPlayed, 1);
      expect(store.totalShards, 1);
    });

    test('a worse run never lowers the records', () async {
      final store = FakeStore();
      final repo = StatsRepository(store);
      await repo.recordRun(score: 500, survivalSeconds: 40, shards: 2);
      final r = await repo.recordRun(score: 100, survivalSeconds: 10, shards: 0);
      expect(r.isNewBestScore, isFalse);
      expect(r.isNewBestTime, isFalse);
      expect(r.bestScore, 500);
      expect(store.bestScore, 500);
      expect(store.bestSurvivalSeconds, 40);
    });

    test('an equal score is not a new record', () async {
      final store = FakeStore();
      final repo = StatsRepository(store);
      await repo.recordRun(score: 300, survivalSeconds: 20, shards: 0);
      final r = await repo.recordRun(score: 300, survivalSeconds: 20, shards: 0);
      expect(r.isNewBestScore, isFalse);
    });

    test('lifetime counters accumulate across runs', () async {
      final store = FakeStore();
      final repo = StatsRepository(store);
      await repo.recordRun(score: 10, survivalSeconds: 1, shards: 2);
      await repo.recordRun(score: 20, survivalSeconds: 2, shards: 3);
      expect(store.gamesPlayed, 2);
      expect(store.totalShards, 5);
    });

    test('best time and best score are tracked independently', () async {
      final store = FakeStore();
      final repo = StatsRepository(store);
      await repo.recordRun(score: 900, survivalSeconds: 20, shards: 10);
      final r = await repo.recordRun(score: 400, survivalSeconds: 35, shards: 0);
      expect(r.isNewBestScore, isFalse);
      expect(r.isNewBestTime, isTrue);
    });
  });
}
