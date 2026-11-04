import 'package:dont_touch_the_future/core/services/settings_controller.dart';
import 'package:dont_touch_the_future/core/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('fresh install returns safe defaults', () async {
    final s = await StorageService.create();
    expect(s.bestScore, 0);
    expect(s.bestSurvivalSeconds, 0);
    expect(s.gamesPlayed, 0);
    expect(s.totalShards, 0);
    expect(s.soundEnabled, isTrue);
    expect(s.musicEnabled, isTrue);
    expect(s.hapticsEnabled, isTrue);
    expect(s.reducedMotion, isFalse);
  });

  test('values survive an app restart (new StorageService instance)', () async {
    final first = await StorageService.create();
    await first.setBestScore(1234);
    await first.setBestSurvivalSeconds(42.5);
    await first.setSoundEnabled(false);

    final second = await StorageService.create();
    expect(second.bestScore, 1234);
    expect(second.bestSurvivalSeconds, 42.5);
    expect(second.soundEnabled, isFalse);
  });

  test('SettingsController persists changes and notifies', () async {
    final storage = await StorageService.create();
    final settings = SettingsController(storage);
    var notified = 0;
    settings.addListener(() => notified++);

    await settings.setHapticsEnabled(false);
    await settings.setReducedMotion(true);

    expect(notified, 2);
    expect(settings.hapticsEnabled, isFalse);
    expect(storage.hapticsEnabled, isFalse);
    expect(storage.reducedMotion, isTrue);
  });
}
