import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../app/app_scope.dart';
import '../../../core/constants/color_constants.dart';
import '../../../shared/widgets/echo_demo.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../utils/format.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _open(String route) async {
    await Navigator.of(context).pushNamed(route);
    // Refresh best score / time after returning from a run.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final storage = scope.storage;
    final settings = scope.settings;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              // Top bar: mini logo + settings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'DTTF',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 5,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_rounded),
                    color: AppColors.secondaryText,
                    onPressed: () => _open(AppRoutes.settings),
                  ),
                ],
              ),
              // Center: animated mechanic + title
              const Expanded(flex: 4, child: EchoDemo()),
              const Text(
                "DON'T TOUCH\nTHE FUTURE",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'YOUR PAST IS CHASING YOU.',
                style: TextStyle(
                  color: AppColors.futureEcho,
                  fontSize: 12,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(flex: 2),
              // Main: PLAY + records
              PrimaryButton(
                label: 'PLAY',
                onPressed: () => _open(AppRoutes.gameplay),
              ),
              const SizedBox(height: 28),
              Text(
                'BEST  ${storage.bestScore}',
                style: const TextStyle(
                  color: AppColors.primaryText,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'BEST TIME  ${formatSurvivalTime(storage.bestSurvivalSeconds)}',
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  letterSpacing: 2,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(flex: 1),
              // Bottom: How to play + sound shortcut
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => _open(AppRoutes.tutorial),
                    icon: const Icon(Icons.help_outline_rounded, size: 18),
                    label: const Text(
                      'HOW TO PLAY',
                      style: TextStyle(
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.secondaryText,
                    ),
                  ),
                  ListenableBuilder(
                    listenable: settings,
                    builder: (_, __) => IconButton(
                      icon: Icon(
                        settings.soundEnabled
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                      ),
                      color: AppColors.secondaryText,
                      onPressed: () =>
                          settings.setSoundEnabled(!settings.soundEnabled),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
