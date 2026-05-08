import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/game_constants.dart';
import '../game/game_controller.dart';
import '../models/block_shape.dart';
import 'shape_widget.dart';

typedef ShapeDragStart = void Function(int index, Offset globalPosition);
typedef ShapeDragUpdate = void Function(Offset globalPosition);

class ShapeTray extends StatelessWidget {
  final ShapeDragStart onDragStart;
  final ShapeDragUpdate onDragUpdate;
  final VoidCallback onDragEnd;

  const ShapeTray({
    super.key,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.shapeAreaBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.shapeAreaBorder, width: 2),
      ),
      child: Consumer<GameController>(
        builder: (context, game, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final slotW = constraints.maxWidth / GameConstants.shapesPerRound;
              final slotH = constraints.maxHeight;

              const maxCells = 5;
              const pad = 10.0;
              final cellSize = math.min(
                (slotW - pad * 2) / maxCells,
                (slotH - pad * 2) / maxCells,
              );

              return Stack(
                fit: StackFit.expand,
                children: [
                  for (int i = 1; i < GameConstants.shapesPerRound; i++)
                    Positioned(
                      left: slotW * i,
                      top: 10,
                      bottom: 10,
                      child: Container(
                        width: 1,
                        color: AppColors.shapeAreaBorder.withOpacity(0.5),
                      ),
                    ),
                  for (int i = 0; i < game.shapes.length; i++)
                    if (!game.shapes[i].placed)
                      _ShapeSlot(
                        shape: game.shapes[i],
                        index: i,
                        slotLeft: i * slotW,
                        slotWidth: slotW,
                        slotHeight: slotH,
                        cellSize: cellSize,
                        isBeingDragged: game.draggingIndex == i,
                        isBeingEdited: game.editingShapeIndex == i,
                        devMode: game.devMode,
                        onTapEdit: () => game.openShapeEditor(i),
                        onDragStart: onDragStart,
                        onDragUpdate: onDragUpdate,
                        onDragEnd: onDragEnd,
                      ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ShapeSlot extends StatelessWidget {
  final BlockShape shape;
  final int index;
  final double slotLeft, slotWidth, slotHeight, cellSize;
  final bool isBeingDragged;
  final bool isBeingEdited;
  final bool devMode;
  final VoidCallback onTapEdit;
  final ShapeDragStart onDragStart;
  final ShapeDragUpdate onDragUpdate;
  final VoidCallback onDragEnd;

  const _ShapeSlot({
    required this.shape,
    required this.index,
    required this.slotLeft,
    required this.slotWidth,
    required this.slotHeight,
    required this.cellSize,
    required this.isBeingDragged,
    required this.isBeingEdited,
    required this.devMode,
    required this.onTapEdit,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Container(
        // Highlight ring while this shape is open in the editor
        decoration: isBeingEdited
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF64C8FF), width: 2),
              )
            : null,
        padding: isBeingEdited ? const EdgeInsets.all(4) : EdgeInsets.zero,
        child: Opacity(
          opacity: isBeingDragged ? 0.2 : 1.0,
          child: ShapeWidget(shape: shape, cellSize: cellSize),
        ),
      ),
    );

    return Positioned(
      left: slotLeft,
      top: 0,
      width: slotWidth,
      height: slotHeight,
      child: devMode
          // Dev mode: simple tap opens the editor
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTapEdit,
              child: content,
            )
          // Normal mode: drag gestures
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanDown: (d) => onDragStart(index, d.globalPosition),
              onPanUpdate: (d) => onDragUpdate(d.globalPosition),
              onPanEnd: (_) => onDragEnd(),
              onPanCancel: onDragEnd,
              child: content,
            ),
    );
  }
}