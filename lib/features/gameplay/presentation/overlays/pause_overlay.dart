import 'package:flutter/material.dart';

import '../../../../core/constants/color_constants.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/secondary_button.dart';
import '../../game/future_game.dart';

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({super.key, required this.game});

  final FutureGame game;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background.withValues(alpha: 0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PAUSED',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 6,
              ),
            ),
            const SizedBox(height: 40),
            PrimaryButton(label: 'RESUME', onPressed: game.resumeGame),
            const SizedBox(height: 12),
            SecondaryButton(label: 'RESTART', onPressed: game.restartGame),
            ListenableBuilder(
              listenable: game.settings,
              builder: (_, __) => SecondaryButton(
                label: game.settings.soundEnabled ? 'SOUND: ON' : 'SOUND: OFF',
                onPressed: () => game.settings
                    .setSoundEnabled(!game.settings.soundEnabled),
              ),
            ),
            SecondaryButton(
              label: 'HOME',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
