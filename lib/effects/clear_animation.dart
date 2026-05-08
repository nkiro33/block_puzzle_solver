import 'package:flutter/material.dart';

/// One cell inside a clear animation (remembers the color it had).
@immutable
class ClearingCell {
  final int row, col;
  final Color color;
  const ClearingCell(this.row, this.col, this.color);
}

/// Flash → shrink animation when rows/columns are cleared.
class ClearAnimation {
  final List<ClearingCell> cells;
  int progress = 0;

  static const int _duration = 22;
  static const int _flashFrames = 9;

  ClearAnimation(this.cells);

  bool get isFlashing => progress < _flashFrames;
  double get flashAlpha => (1.0 - progress / _flashFrames).clamp(0.0, 1.0);
  double get flashExpand => progress * 1.5;

  double get shrinkT => progress < _flashFrames
      ? 0
      : ((progress - _flashFrames) / (_duration - _flashFrames)).clamp(0.0, 1.0);

  bool update() {
    progress++;
    return progress < _duration;
  }
}