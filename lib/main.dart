import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'core/services/audio_service.dart';
import 'core/services/haptic_service.dart';
import 'core/services/settings_controller.dart';
import 'core/services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The game is designed for portrait only (9:16).
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final storage = await StorageService.create();
  final settings = SettingsController(storage);
  final audio = AudioService(settings);
  await audio.preload();

  runApp(DontTouchTheFutureApp(
    storage: storage,
    settings: settings,
    audio: audio,
    haptics: HapticService(settings),
  ));
}
