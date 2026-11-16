/// Cheap geometric helpers. Circle-vs-circle only (all entities are circles).
class CollisionSystem {
  const CollisionSystem._();

  /// True when two circles overlap (touching exactly does not count).
  static bool circlesOverlap(
    double ax,
    double ay,
    double ar,
    double bx,
    double by,
    double br,
  ) {
    final dx = ax - bx;
    final dy = ay - by;
    final r = ar + br;
    return dx * dx + dy * dy < r * r;
  }
}
