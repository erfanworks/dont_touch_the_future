import 'dart:ui';

import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/services/settings_controller.dart';
import '../../../utils/format.dart';
import '../../statistics/models/run_summary.dart';
import '../../statistics/services/stats_repository.dart';
import 'components/arena_component.dart';
import 'components/chrono_shard_component.dart';
import 'components/effects_component.dart';
import 'components/future_echo_component.dart';
import 'components/input_layer_component.dart';
import 'components/obstacle_component.dart';
import 'components/player_component.dart';
import 'game_session.dart';
import 'models/game_state.dart';
import 'systems/effects_system.dart';

/// Thin Flame wrapper: forwards time/input to [GameSession], draws its state,
/// plays feedback (effects, sound, haptics) and bridges to Flutter overlays.
class FutureGame extends FlameGame {
  FutureGame({
    required this.statsRepository,
    required this.haptics,
    required this.audio,
    required this.settings,
  }) {
    session.onEvent = _handleEvent;
  }

  static const String hudOverlay = 'hud';
  static const String pauseOverlay = 'pause';
  static const String gameOverOverlay = 'gameOver';

  final StatsRepository statsRepository;
  final HapticService haptics;
  final AudioService audio;
  final SettingsController settings;
  final GameSession session = GameSession();
  final EffectsSystem effects = EffectsSystem();

  // Flutter overlays listen to these. They only notify on real changes.
  final ValueNotifier<int> score = ValueNotifier<int>(0);
  final ValueNotifier<GameStatus> status =
      ValueNotifier<GameStatus>(GameStatus.initializing);
  final ValueNotifier<String> hint = ValueNotifier<String>('');
  final ValueNotifier<String> banner = ValueNotifier<String>('');
  final ValueNotifier<RunSummary?> lastRun = ValueNotifier<RunSummary?>(null);

  int _hintKey = -1;
  double _bannerLeft = 0;

  @override
  Color backgroundColor() => AppColors.background;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await addAll([
      ArenaComponent(session),
      ChronoShardComponent(session),
      ObstacleComponent(session),
      FutureEchoComponent(session),
      PlayerComponent(session),
      EffectsComponent(effects: effects, session: session),
      InputLayerComponent(session: session, onInputHandled: _syncNotifiers),
    ]);
    _syncNotifiers();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    session.configureArena(size.x, size.y);
    _syncNotifiers();
  }

  @override
  void update(double dt) {
    session.update(dt);

    effects.reducedMotion = settings.reducedMotion;
    if (session.isPlaying && session.echoActive) {
      effects.emitTrail(session.echoX, session.echoY, dt);
    }
    effects.update(dt);
    _tickBanner(dt);

    super.update(dt);
    _syncNotifiers();
  }

  /// Screen shake: shift the whole scene by the current shake offset.
  @override
  void render(Canvas canvas) {
    if (effects.shakeX == 0 && effects.shakeY == 0) {
      super.render(canvas);
      return;
    }
    canvas.save();
    canvas.translate(effects.shakeX, effects.shakeY);
    super.render(canvas);
    canvas.restore();
  }

  /// Backgrounding must never corrupt gameplay timing: pause the session.
  @override
  void lifecycleStateChange(AppLifecycleState state) {
    super.lifecycleStateChange(state);
    if (state != AppLifecycleState.resumed) pauseGame();
  }

  // ------------------------------------------------------------- controls

  void pauseGame() {
    if (!session.pause()) return;
    overlays.add(pauseOverlay);
    pauseEngine();
    _syncNotifiers();
  }

  void resumeGame() {
    if (!session.resume()) return;
    overlays.remove(pauseOverlay);
    resumeEngine();
    _syncNotifiers();
  }

  void restartGame() {
    if (!session.reset()) return;
    effects.reset();
    banner.value = '';
    _bannerLeft = 0;
    overlays.remove(pauseOverlay);
    overlays.remove(gameOverOverlay);
    overlays.add(hudOverlay);
    lastRun.value = null;
    resumeEngine();
    _syncNotifiers();
  }

  // --------------------------------------------------------------- events

  void _handleEvent(GameEvent event) {
    final unit = session.unit;
    switch (event.type) {
      case GameEventType.shardCollected:
        haptics.light();
        audio.collect();
        effects.burst(
          event.x,
          event.y,
          count: 14,
          speed: 140 * unit,
          color: EffectColor.shard,
          size: 2.6,
        );
        effects.spawnText(
          event.x,
          event.y - 16 * unit,
          '+${event.value}',
          color: EffectColor.shard,
        );
      case GameEventType.milestone:
        haptics.medium();
        audio.milestone();
        effects.spawnText(
          session.player.x,
          session.player.y - 30 * unit,
          '${event.value}s',
          scale: 0.9,
        );
        if (event.value >= 30) {
          effects.burst(
            session.player.x,
            session.player.y,
            count: 28,
            speed: 150 * unit,
            color: EffectColor.white,
            size: 2.4,
            life: 0.7,
            ring: true,
          );
        }
        if (event.value >= 60) {
          _showBanner(
            'ACHIEVEMENT  ${formatSurvivalTime(event.value.toDouble())}',
          );
        }
      case GameEventType.phaseChanged:
        break;
      case GameEventType.died:
        haptics.heavy();
        audio.collision();
        effects.shake(amplitude: 9 * unit, duration: 0.35);
        effects.impactFlash();
        effects.burst(
          event.x,
          event.y,
          count: 36,
          speed: 260 * unit,
          color: EffectColor.danger,
          size: 3.2,
        );
        effects.burst(
          event.x,
          event.y,
          count: 16,
          speed: 200 * unit,
          color: EffectColor.white,
          size: 2.4,
        );
        _finishRun();
    }
  }

  Future<void> _finishRun() async {
    final runId = session.runId;
    final summary = await statsRepository.recordRun(
      score: session.score,
      survivalSeconds: session.scoring.survivalSeconds,
      shards: session.scoring.shardsCollected,
    );
    // Let the impact animation play before the Game Over screen appears.
    await Future<void>.delayed(const Duration(milliseconds: 650));
    // The player may have restarted while we were waiting.
    if (runId != session.runId || session.status != GameStatus.gameOver) {
      return;
    }
    lastRun.value = summary;
    overlays.remove(hudOverlay);
    overlays.add(gameOverOverlay);
    audio.gameOver();
    _syncNotifiers();
  }

  void _showBanner(String text) {
    banner.value = text;
    _bannerLeft = 2.2;
  }

  void _tickBanner(double dt) {
    if (_bannerLeft <= 0) return;
    _bannerLeft -= dt;
    if (_bannerLeft <= 0) banner.value = '';
  }

  // ------------------------------------------------------------ UI bridge

  void _syncNotifiers() {
    score.value = session.score;
    status.value = session.status;

    int key;
    String text;
    if (session.status == GameStatus.ready) {
      key = -2;
      text = 'DRAG ANYWHERE TO MOVE';
    } else if (session.isPlaying && !session.echoActive) {
      final left = (GameConstants.echoDelaySeconds - session.gameTime)
          .ceil()
          .clamp(1, 3);
      key = left;
      text = 'YOUR ECHO ARRIVES IN $left';
    } else {
      key = -1;
      text = '';
    }
    if (key != _hintKey) {
      _hintKey = key;
      hint.value = text;
    }
  }

  /// Exposed for overlays that want the best score without async work.
  int get bestScore => statsRepository.bestScore > score.value
      ? statsRepository.bestScore
      : score.value;
}
