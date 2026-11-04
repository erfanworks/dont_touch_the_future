import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/services/storage_service.dart';
import '../../../shared/widgets/primary_button.dart';

/// Phase 1 foundation version of the Home screen.
/// The full premium layout (settings, how-to-play, animation) comes in Phase 3.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.storage});

  final StorageService storage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 3),
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
              const SizedBox(height: 16),
              const Text(
                'YOUR PAST IS CHASING YOU.',
                style: TextStyle(
                  color: AppColors.futureEcho,
                  fontSize: 12,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(flex: 3),
              PrimaryButton(
                label: 'PLAY',
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.gameplay),
              ),
              const SizedBox(height: 32),
              Text(
                'BEST  ${storage.bestScore}',
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
