import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/game_constants.dart';
import '../effects/clear_animation.dart';
import '../game/game_controller.dart';
import '../models/block_shape.dart';
import 'block_cell.dart';

class GameGrid extends StatelessWidget {
  const GameGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Consumer<GameController>(
        builder: (context, game, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final cellSize = constraints.maxWidth / GameConstants.gridSize;

              Widget content = Stack(
                children: [
                  _Cells(
                      grid: game.grid,
                      gridArrows: game.gridArrows,
                      cellSize: cellSize),
                  if (game.snapPosition != null && game.draggingShape != null)
                    _SnapPreview(
                      shape: game.draggingShape!,
                      pos: game.snapPosition!,
                      cellSize: cellSize,
                    ),
                  for (final anim in game.clearAnimations)
                    _ClearLayer(animation: anim, cellSize: cellSize),
                ],
              );

              // Dev mode: wrap in paint gesture detector
              if (game.devMode) {
                (int, int) toCell(Offset local) => (
                      (local.dy / cellSize).floor(),
                      (local.dx / cellSize).floor(),
                    );

                content = GestureDetector(
                  behavior: HitTestBehavior.opaque,

                  // Single tap → toggle one cell
                  onTapUp: (d) {
                    final (r, c) = toCell(d.localPosition);
                    game.paintGridStart(r, c);
                    game.paintGridEnd();
                  },

                  // Drag → paint/erase stroke
                  onPanStart: (d) {
                    final (r, c) = toCell(d.localPosition);
                    game.paintGridStart(r, c);
                  },
                  onPanUpdate: (d) {
                    final (r, c) = toCell(d.localPosition);
                    game.paintGridUpdate(r, c);
                  },
                  onPanEnd: (_) => game.paintGridEnd(),
                  onPanCancel: game.paintGridEnd,

                  // Long press → cycle arrow on filled cell
                  onLongPressStart: (d) {
                    final (r, c) = toCell(d.localPosition);
                    if (game.cycleGridArrow(r, c)) {
                      HapticFeedback.selectionClick();
                    }
                  },

                  child: content,
                );
              }

              return content;
            },
          );
        },
      ),
    );
  }
}

class _Cells extends StatelessWidget {
  final List<List<Color?>> grid;
  final Map<(int, int), ArrowDirection> gridArrows;
  final double cellSize;

  const _Cells({
    required this.grid,
    required this.gridArrows,
    required this.cellSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int r = 0; r < GameConstants.gridSize; r++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int c = 0; c < GameConstants.gridSize; c++)
                SizedBox(
                  width: cellSize,
                  height: cellSize,
                  child: BlockCell(
                    color: grid[r][c],
                    arrow: gridArrows[(r, c)],
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

// -----------------------------------------------------------------------
// Snap preview
// -----------------------------------------------------------------------
class _SnapPreview extends StatefulWidget {
  final BlockShape shape;
  final GridPos pos;
  final double cellSize;

  const _SnapPreview({
    required this.shape,
    required this.pos,
    required this.cellSize,
  });

  @override
  State<_SnapPreview> createState() => _SnapPreviewState();
}

class _SnapPreviewState extends State<_SnapPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final opacity = 0.35 + _pulse.value * 0.25;
        return Stack(
          children: [
            for (final b in widget.shape.blocks)
              Positioned(
                left: (widget.pos.x + b.x) * widget.cellSize,
                top: (widget.pos.y + b.y) * widget.cellSize,
                width: widget.cellSize,
                height: widget.cellSize,
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: widget.shape.color.withOpacity(opacity),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.previewValid, width: 2),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// -----------------------------------------------------------------------
// Clear animation
// -----------------------------------------------------------------------
class _ClearLayer extends StatelessWidget {
  final ClearAnimation animation;
  final double cellSize;

  const _ClearLayer({required this.animation, required this.cellSize});

  @override
  Widget build(BuildContext context) {
    if (animation.isFlashing) {
      final alpha = animation.flashAlpha * 0.9;
      final expand = animation.flashExpand;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          for (final cell in animation.cells)
            Positioned(
              left: cell.col * cellSize - expand,
              top: cell.row * cellSize - expand,
              width: cellSize + expand * 2,
              height: cellSize + expand * 2,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(alpha),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      );
    }

    final t = animation.shrinkT;
    final scale = (1.0 - t).clamp(0.0, 1.0);
    final alpha = (1.0 - t).clamp(0.0, 1.0);

    return Stack(
      children: [
        for (final cell in animation.cells)
          Positioned(
            left: cell.col * cellSize,
            top: cell.row * cellSize,
            width: cellSize,
            height: cellSize,
            child: Center(
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: cellSize - 4,
                  height: cellSize - 4,
                  decoration: BoxDecoration(
                    color: cell.color.withOpacity(alpha),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
