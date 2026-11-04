import 'package:flutter/material.dart';

import '../core/services/settings_controller.dart';
import '../core/services/storage_service.dart';
import '../features/gameplay/presentation/gameplay_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import 'app_routes.dart';
import 'app_theme.dart';

class DontTouchTheFutureApp extends StatelessWidget {
  const DontTouchTheFutureApp({
    super.key,
    required this.storage,
    required this.settings,
  });

  final StorageService storage;
  final SettingsController settings;

  Route<dynamic> _onGenerateRoute(RouteSettings route) {
    final Widget page;
    switch (route.name) {
      case AppRoutes.home:
        page = HomeScreen(storage: storage);
      case AppRoutes.gameplay:
        page = const GameplayScreen();
      case AppRoutes.splash:
      default:
        page = const SplashScreen();
    }
    return PageRouteBuilder<void>(
      settings: route,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "DON'T TOUCH THE FUTURE",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: _onGenerateRoute,
    );
  }
}
