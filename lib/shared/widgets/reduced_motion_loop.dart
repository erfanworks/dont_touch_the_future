import 'package:flutter/widgets.dart';

import '../../app/app_scope.dart';
import '../../core/services/settings_controller.dart';

/// Keeps a looping animation in sync with Reduced Motion: in-app setting
/// (reacts instantly) OR the operating system's "reduce motion" setting.
mixin ReducedMotionLoop<T extends StatefulWidget> on State<T> {
  AnimationController get loopController;

  /// Frozen position used when motion is reduced.
  double get restValue => 0.4;

  SettingsController? _settings;
  bool _systemReduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _systemReduced = MediaQuery.disableAnimationsOf(context);
    final s = AppScope.maybeOf(context)?.settings;
    if (!identical(s, _settings)) {
      _settings?.removeListener(_applyMotion);
      _settings = s;
      _settings?.addListener(_applyMotion);
    }
    _applyMotion();
  }

  void _applyMotion() {
    if (!mounted) return;
    final reduced = _systemReduced || (_settings?.reducedMotion ?? false);
    final c = loopController;
    if (reduced) {
      c
        ..stop()
        ..value = restValue;
    } else if (!c.isAnimating) {
      c.repeat();
    }
  }

  @override
  void dispose() {
    _settings?.removeListener(_applyMotion);
    super.dispose();
  }
}
