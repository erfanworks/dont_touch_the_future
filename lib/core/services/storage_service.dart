import 'package:shared_preferences/shared_preferences.dart';

import '../../features/statistics/services/stats_repository.dart';

/// Thin wrapper over SharedPreferences. All persisted keys live here.
class StorageService implements StatsStore {
  StorageService._(this._prefs);

  final SharedPreferences _prefs;

  static const String _kBestScore = 'best_score';
  static const String _kBestSurvivalSeconds = 'best_survival_seconds';
  static const String _kGamesPlayed = 'games_played';
  static const String _kTotalShards = 'total_shards';
  static const String _kSound = 'setting_sound';
  static const String _kMusic = 'setting_music';
  static const String _kHaptics = 'setting_haptics';
  static const String _kReducedMotion = 'setting_reduced_motion';

  static Future<StorageService> create() async =>
      StorageService._(await SharedPreferences.getInstance());

  // --- Stats ---
  @override
  int get bestScore => _prefs.getInt(_kBestScore) ?? 0;
  @override
  double get bestSurvivalSeconds => _prefs.getDouble(_kBestSurvivalSeconds) ?? 0;
  @override
  int get gamesPlayed => _prefs.getInt(_kGamesPlayed) ?? 0;
  @override
  int get totalShards => _prefs.getInt(_kTotalShards) ?? 0;

  @override
  Future<void> setBestScore(int v) => _prefs.setInt(_kBestScore, v);
  @override
  Future<void> setBestSurvivalSeconds(double v) =>
      _prefs.setDouble(_kBestSurvivalSeconds, v);
  @override
  Future<void> setGamesPlayed(int v) => _prefs.setInt(_kGamesPlayed, v);
  @override
  Future<void> setTotalShards(int v) => _prefs.setInt(_kTotalShards, v);

  // --- Settings (defaults: sound/music/haptics on, reduced motion off) ---
  bool get soundEnabled => _prefs.getBool(_kSound) ?? true;
  bool get musicEnabled => _prefs.getBool(_kMusic) ?? true;
  bool get hapticsEnabled => _prefs.getBool(_kHaptics) ?? true;
  bool get reducedMotion => _prefs.getBool(_kReducedMotion) ?? false;

  Future<void> setSoundEnabled(bool v) => _prefs.setBool(_kSound, v);
  Future<void> setMusicEnabled(bool v) => _prefs.setBool(_kMusic, v);
  Future<void> setHapticsEnabled(bool v) => _prefs.setBool(_kHaptics, v);
  Future<void> setReducedMotion(bool v) => _prefs.setBool(_kReducedMotion, v);
}
