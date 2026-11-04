import 'package:flutter/material.dart';

import '../core/constants/color_constants.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      surface: AppColors.background,
      primary: AppColors.player,
      secondary: AppColors.futureEcho,
      error: AppColors.danger,
      onSurface: AppColors.primaryText,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: NoSplash.splashFactory,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.primaryText,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
        bodyMedium: TextStyle(color: AppColors.secondaryText),
      ),
    );
  }
}
