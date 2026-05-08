import 'dart:ui';

/// Expanding golden rings when the whole board is cleared.
class BoardClearRings {
  final Offset center;
  final List<_Ring> rings = [];
  int progress = 0;

  static const int _duration = 60;

  BoardClearRings(this.center);

  bool update() {
    progress++;
    if (progress % 8 == 0 && progress < 40) {
      rings.add(_Ring());
    }
    for (final r in rings) {
      r.radius += 8;
      r.alpha = (r.alpha - 0.024).clamp(0.0, 1.0);
    }
    rings.removeWhere((r) => r.alpha <= 0);
    return progress < _duration || rings.isNotEmpty;
  }
}

class _Ring {
  double radius = 0;
  double alpha = 1.0;
}