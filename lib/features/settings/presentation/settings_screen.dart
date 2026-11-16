import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/constants/color_constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showInfo(BuildContext context, String title, String body) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.secondaryBackground,
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.primaryText,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        content: Text(
          body,
          style: const TextStyle(color: AppColors.secondaryText, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 24, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: AppColors.secondaryText,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text(
                    'SETTINGS',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: settings,
                builder: (context, _) => ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    _SwitchTile(
                      title: 'SOUND EFFECTS',
                      subtitle: 'Collect, impact and button sounds',
                      value: settings.soundEnabled,
                      onChanged: settings.setSoundEnabled,
                    ),
                    _SwitchTile(
                      title: 'HAPTIC FEEDBACK',
                      subtitle: 'Vibration on shards and impacts',
                      value: settings.hapticsEnabled,
                      onChanged: settings.setHapticsEnabled,
                    ),
                    _SwitchTile(
                      title: 'REDUCED MOTION',
                      subtitle: 'Less shake, flashes and particles',
                      value: settings.reducedMotion,
                      onChanged: settings.setReducedMotion,
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'ABOUT',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 11,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _ActionTile(
                      title: 'PRIVACY POLICY',
                      onTap: () => _showInfo(
                        context,
                        'Privacy Policy',
                        'The privacy policy link will be added before the store '
                            'release. The game works offline and needs no account.',
                      ),
                    ),
                    _ActionTile(
                      title: 'ABOUT GAME',
                      onTap: () => _showInfo(
                        context,
                        "DON'T TOUCH THE FUTURE",
                        'Version 0.3.0\n\nYour past is chasing you.\n\n'
                            'Survive by avoiding the echo of your own movement.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            thumbColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppColors.background
                  : AppColors.secondaryText,
            ),
            trackColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppColors.chronoShard
                  : AppColors.border,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.secondaryBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.secondaryText),
            ],
          ),
        ),
      ),
    );
  }
}
