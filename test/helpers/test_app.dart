import 'package:dont_touch_the_future/app/app_scope.dart';
import 'package:dont_touch_the_future/app/app_theme.dart';
import 'package:dont_touch_the_future/core/services/audio_service.dart';
import 'package:dont_touch_the_future/core/services/haptic_service.dart';
import 'package:dont_touch_the_future/core/services/settings_controller.dart';
import 'package:dont_touch_the_future/core/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestApp {
  TestApp(this.widget, this.storage, this.settings);
  final Widget widget;
  final StorageService storage;
  final SettingsController settings;
}

/// Builds [home] inside the real AppScope. Sound and haptics start OFF so
/// widget tests never touch platform channels.
Future<TestApp> buildTestApp(Widget home) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'setting_sound': false,
    'setting_haptics': false,
  });
  final storage = await StorageService.create();
  final settings = SettingsController(storage);
  final widget = AppScope(
    storage: storage,
    settings: settings,
    audio: AudioService(settings),
    haptics: HapticService(settings),
    child: MaterialApp(theme: AppTheme.dark, home: home),
  );
  return TestApp(widget, storage, settings);
}
