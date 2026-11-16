import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../game_session.dart';

/// Invisible full-screen layer that turns touch drags into session input.
/// Uses only drag DELTAS, so it works at any position on the screen.
class InputLayerComponent extends PositionComponent with DragCallbacks {
  InputLayerComponent({required this.session, required this.onInputHandled}) {
    priority = 100;
  }

  final GameSession session;
  final VoidCallback onInputHandled;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    session.beginDrag();
    onInputHandled();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    session.dragBy(event.localDelta.x, event.localDelta.y);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    session.endDrag();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    session.endDrag();
  }
}
