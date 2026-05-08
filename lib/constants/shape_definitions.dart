import '../models/block_shape.dart';

abstract class ShapeDefinitions {
  static const List<List<Block>> all = [
    // Single
    [Block(0, 0)],
    // 2x2 square
    [Block(0, 0), Block(1, 0), Block(0, 1), Block(1, 1)],
    // 3x3 square
    [
      Block(0, 0), Block(1, 0), Block(2, 0),
      Block(0, 1), Block(1, 1), Block(2, 1),
      Block(0, 2), Block(1, 2), Block(2, 2),
    ],
    // Horizontal lines
    [Block(0, 0), Block(1, 0)],
    [Block(0, 0), Block(1, 0), Block(2, 0)],
    [Block(0, 0), Block(1, 0), Block(2, 0), Block(3, 0)],
    [Block(0, 0), Block(1, 0), Block(2, 0), Block(3, 0), Block(4, 0)],
    // Vertical lines
    [Block(0, 0), Block(0, 1)],
    [Block(0, 0), Block(0, 1), Block(0, 2)],
    [Block(0, 0), Block(0, 1), Block(0, 2), Block(0, 3)],
    [Block(0, 0), Block(0, 1), Block(0, 2), Block(0, 3), Block(0, 4)],
    // Rectangles
    [Block(0, 0), Block(1, 0), Block(0, 1), Block(1, 1), Block(0, 2), Block(1, 2)],
    [Block(0, 0), Block(1, 0), Block(2, 0), Block(0, 1), Block(1, 1), Block(2, 1)],
    // L-shapes
    [Block(0, 0), Block(0, 1), Block(0, 2), Block(1, 2)],
    [Block(0, 0), Block(0, 1), Block(0, 2), Block(1, 0)],
    [Block(0, 0), Block(1, 0), Block(2, 0), Block(2, 1)],
    [Block(0, 0), Block(1, 0), Block(2, 0), Block(0, 1)],
    [Block(0, 0), Block(1, 0), Block(1, 1), Block(1, 2)],
    [Block(0, 0), Block(1, 0), Block(0, 1), Block(0, 2)],
    [Block(0, 0), Block(0, 1), Block(1, 1), Block(2, 1)],
    [Block(2, 0), Block(0, 1), Block(1, 1), Block(2, 1)],
    // T-shapes
    [Block(0, 0), Block(1, 0), Block(2, 0), Block(1, 1)],
    [Block(1, 0), Block(0, 1), Block(1, 1), Block(2, 1)],
    [Block(0, 0), Block(0, 1), Block(1, 1), Block(0, 2)],
    [Block(1, 0), Block(0, 1), Block(1, 1), Block(1, 2)],
    // S/Z shapes
    [Block(1, 0), Block(2, 0), Block(0, 1), Block(1, 1)],
    [Block(0, 0), Block(1, 0), Block(1, 1), Block(2, 1)],
    [Block(0, 0), Block(0, 1), Block(1, 1), Block(1, 2)],
    [Block(1, 0), Block(0, 1), Block(1, 1), Block(0, 2)],
    // Small L
    [Block(0, 0), Block(0, 1), Block(1, 1)],
    [Block(0, 0), Block(1, 0), Block(1, 1)],
    [Block(0, 0), Block(1, 0), Block(0, 1)],
    [Block(1, 0), Block(0, 1), Block(1, 1)],
  ];
}