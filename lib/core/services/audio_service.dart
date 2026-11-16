import 'package:flame_audio/flame_audio.dart';

import 'settings_controller.dart';

/// Plays sound effects and always respects the user's sound setting.
/// Audio is non-critical: any playback error is swallowed, never crashes play.
class AudioService {
  AudioService(this._settings);

  final SettingsController _settings;

  static const List<String> _files = [
    'collect.wav',
    'collision.wav',
    'game_over.wav',
    'button.wav',
    'milestone.wav',
  ];

  Future<void> preload() async {
    try {
      await FlameAudio.audioCache.loadAll(_files);
    } catch (_) {
      // Audio is optional; the game works without it.
    }
  }

  void collect() => _play('collect.wav', 0.6);
  void collision() => _play('collision.wav', 0.8);
  void gameOver() => _play('game_over.wav', 0.7);
  void button() => _play('button.wav', 0.4);
  void milestone() => _play('milestone.wav', 0.5);

  Future<void> _play(String file, double volume) async {
    if (!_settings.soundEnabled) return;
    try {
      await FlameAudio.play(file, volume: volume);
    } catch (_) {
      // Audio is optional; ignore playback errors.
    }
  }
}
