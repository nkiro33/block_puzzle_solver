import 'package:flutter/material.dart';
import '../models/block_shape.dart';
import 'block_cell.dart';

class ShapeWidget extends StatelessWidget {
  final BlockShape shape;
  final double cellSize;
  final double opacity;

  const ShapeWidget({
    super.key,
    required this.shape,
    required this.cellSize,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: shape.width * cellSize,
      height: shape.height * cellSize,
      child: Stack(
        children: [
          for (final b in shape.blocks)
            Positioned(
              left: b.x * cellSize,
              top: b.y * cellSize,
              width: cellSize,
              height: cellSize,
              child: BlockCell(
                color: shape.color,
                opacity: opacity,
                arrow: b.arrow,
              ),
            ),
        ],
      ),
    );
  }
}
