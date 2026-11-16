import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/constants/color_constants.dart';

/// Quiet text-style button for secondary actions (Restart, Home...).
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        final scope = AppScope.maybeOf(context);
        scope?.audio.button();
        scope?.haptics.light();
        onPressed();
      },
      style: TextButton.styleFrom(
        foregroundColor: AppColors.secondaryText,
        minimumSize: const Size(240, 48),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 3,
        ),
      ),
    );
  }
}
