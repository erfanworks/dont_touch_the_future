import 'package:flutter/widgets.dart';

import '../core/services/audio_service.dart';
import '../core/services/haptic_service.dart';
import '../core/services/settings_controller.dart';
import '../core/services/storage_service.dart';

/// Gives every screen access to the app-wide services without long
/// constructor chains. The services never change, so it never notifies.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.storage,
    required this.settings,
    required this.audio,
    required this.haptics,
    required super.child,
  });

  final StorageService storage;
  final SettingsController settings;
  final AudioService audio;
  final HapticService haptics;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found above this context');
    return scope!;
  }

  static AppScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>();

  @override
  bool updateShouldNotify(AppScope oldWidget) => false;
}
