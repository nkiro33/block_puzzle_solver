import 'package:flutter/material.dart';
import '../models/block_shape.dart';
import 'shape_widget.dart';

/// The shape following the user's finger, drawn at grid cell size.
class DragShapeOverlay extends StatelessWidget {
  final BlockShape shape;
  final Offset position; // stack-local coords (already offset above finger)
  final double cellSize;

  const DragShapeOverlay({
    super.key,
    required this.shape,
    required this.position,
    required this.cellSize,
  });

  @override
  Widget build(BuildContext context) {
    if (cellSize <= 0) return const SizedBox.shrink();

    final w = shape.width * cellSize;
    final h = shape.height * cellSize;

    return Positioned(
      left: position.dx - w / 2,
      top: position.dy - h / 2,
      child: IgnorePointer(
        child: Material(
          type: MaterialType.transparency,
          elevation: 8,
          child: ShapeWidget(shape: shape, cellSize: cellSize, opacity: 0.92),
        ),
      ),
    );
  }
}