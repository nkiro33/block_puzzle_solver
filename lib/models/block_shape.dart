import 'package:flutter/material.dart';

/// A direction an arrow-block will expand towards.
enum ArrowDirection {
  up(0, -1),
  down(0, 1),
  left(-1, 0),
  right(1, 0);

  final int dx, dy;
  const ArrowDirection(this.dx, this.dy);
}

/// A single cell coordinate within a shape.
/// An optional [arrow] means this cell will spawn an extra block on the grid
/// when the round is completed.
@immutable
class Block {
  final int x;
  final int y;
  final ArrowDirection? arrow;

  const Block(this.x, this.y, [this.arrow]);

  /// Equality is by *position only* — arrows are metadata, not identity.
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Block && other.x == x && other.y == y);

  @override
  int get hashCode => Object.hash(x, y);
}

/// A draggable shape made of [Block]s.
class BlockShape {
  final List<Block> blocks;
  final Color color;
  bool placed;

  BlockShape({required this.blocks, required this.color, this.placed = false});

  int get width {
    var m = 0;
    for (final b in blocks) {
      if (b.x > m) m = b.x;
    }
    return m + 1;
  }

  int get height {
    var m = 0;
    for (final b in blocks) {
      if (b.y > m) m = b.y;
    }
    return m + 1;
  }

  bool get hasArrows => blocks.any((b) => b.arrow != null);
}