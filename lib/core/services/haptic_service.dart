import 'package:flutter/services.dart';

import 'settings_controller.dart';

/// Haptics that always respect the user's setting.
class HapticService {
  const HapticService(this._settings);

  final SettingsController _settings;

  void light() {
    if (_settings.hapticsEnabled) HapticFeedback.lightImpact();
  }

  void medium() {
    if (_settings.hapticsEnabled) HapticFeedback.mediumImpact();
  }

  void heavy() {
    if (_settings.hapticsEnabled) HapticFeedback.heavyImpact();
  }
}
