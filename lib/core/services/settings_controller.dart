import 'package:flutter/foundation.dart';

import 'storage_service.dart';

/// Holds user settings, persists every change, and notifies listeners.
/// Plain ChangeNotifier is enough here; gameplay state lives inside Flame.
class SettingsController extends ChangeNotifier {
  SettingsController(this._storage)
      : _sound = _storage.soundEnabled,
        _music = _storage.musicEnabled,
        _haptics = _storage.hapticsEnabled,
        _reducedMotion = _storage.reducedMotion;

  final StorageService _storage;

  bool _sound;
  bool _music;
  bool _haptics;
  bool _reducedMotion;

  bool get soundEnabled => _sound;
  bool get musicEnabled => _music;
  bool get hapticsEnabled => _haptics;
  bool get reducedMotion => _reducedMotion;

  Future<void> setSoundEnabled(bool v) async {
    _sound = v;
    notifyListeners();
    await _storage.setSoundEnabled(v);
  }

  Future<void> setMusicEnabled(bool v) async {
    _music = v;
    notifyListeners();
    await _storage.setMusicEnabled(v);
  }

  Future<void> setHapticsEnabled(bool v) async {
    _haptics = v;
    notifyListeners();
    await _storage.setHapticsEnabled(v);
  }

  Future<void> setReducedMotion(bool v) async {
    _reducedMotion = v;
    notifyListeners();
    await _storage.setReducedMotion(v);
  }
}
