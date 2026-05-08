import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/game_constants.dart';
import '../game/game_controller.dart';
import '../models/block_shape.dart';

class ShapeEditorOverlay extends StatelessWidget {
  const ShapeEditorOverlay({super.key});

  static const double _cellSize = 44;
  static const int _grid = GameConstants.shapeEditorSize;

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, game, _) {
        final shape = game.editingShape;
        if (shape == null) return const SizedBox.shrink();

        return Positioned.fill(
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: game.closeShapeEditor,
                  child: Container(color: Colors.black.withOpacity(0.55)),
                ),
              ),
              Center(
                child: GestureDetector(
                  onTap: () {},
                  child: _EditorPanel(
                    shape: shape,
                    index: game.editingShapeIndex!,
                    onClose: game.closeShapeEditor,
                    onPaintStart: game.paintShapeStart,
                    onPaintUpdate: game.paintShapeUpdate,
                    onPaintEnd: game.paintShapeEnd,
                    onCycleArrow: game.cycleShapeArrow,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EditorPanel extends StatelessWidget {
  final BlockShape shape;
  final int index;
  final VoidCallback onClose;
  final void Function(int x, int y) onPaintStart;
  final void Function(int x, int y) onPaintUpdate;
  final VoidCallback onPaintEnd;
  final bool Function(int x, int y) onCycleArrow;

  const _EditorPanel({
    required this.shape,
    required this.index,
    required this.onClose,
    required this.onPaintStart,
    required this.onPaintUpdate,
    required this.onPaintEnd,
    required this.onCycleArrow,
  });

  static const double _cell = ShapeEditorOverlay._cellSize;
  static const int _grid = ShapeEditorOverlay._grid;

  (int, int)? _hitTest(Offset local) {
    final x = (local.dx / _cell).floor();
    final y = (local.dy / _cell).floor();
    if (x < 0 || x >= _grid || y < 0 || y >= _grid) return null;
    return (x, y);
  }

  @override
  Widget build(BuildContext context) {
    final gridPx = _cell * _grid;

    // Build position → arrow lookup so the 5×5 canvas can show arrows
    // without scanning the list for every cell.
    final arrowAt = <(int, int), ArrowDirection>{};
    for (final b in shape.blocks) {
      if (b.arrow != null) arrowAt[(b.x, b.y)] = b.arrow!;
    }
    final filled = shape.blocks.toSet();

    return Material(
      color: const Color(0xFF2D2D3C),
      borderRadius: BorderRadius.circular(16),
      elevation: 12,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF506482), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Edit Shape ${index + 1}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(width: 24),
                IconButton(
                  onPressed: onClose,
                  icon:
                      const Icon(Icons.close, color: AppColors.textSecondary),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Canvas
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: GestureDetector(
                // Tap → toggle one cell
                onTapUp: (d) {
                  final h = _hitTest(d.localPosition);
                  if (h != null) {
                    onPaintStart(h.$1, h.$2);
                    onPaintEnd();
                  }
                },
                // Drag → paint stroke
                onPanStart: (d) {
                  final h = _hitTest(d.localPosition);
                  if (h != null) onPaintStart(h.$1, h.$2);
                },
                onPanUpdate: (d) {
                  final h = _hitTest(d.localPosition);
                  if (h != null) onPaintUpdate(h.$1, h.$2);
                },
                onPanEnd: (_) => onPaintEnd(),
                onPanCancel: onPaintEnd,
                // Long press → cycle arrow
                onLongPressStart: (d) {
                  final h = _hitTest(d.localPosition);
                  if (h != null && onCycleArrow(h.$1, h.$2)) {
                    HapticFeedback.selectionClick();
                  }
                },
                child: SizedBox(
                  width: gridPx,
                  height: gridPx,
                  child: Stack(
                    children: [
                      for (int y = 0; y < _grid; y++)
                        for (int x = 0; x < _grid; x++)
                          Positioned(
                            left: x * _cell,
                            top: y * _cell,
                            width: _cell,
                            height: _cell,
                            child: _EditorCell(
                              filled: filled.contains(Block(x, y)),
                              color: shape.color,
                              arrow: arrowAt[(x, y)],
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),
            const Text(
              'Tap: toggle · Drag: paint · Hold: cycle arrow',
              style: TextStyle(color: Color(0xFF8A96A4), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorCell extends StatelessWidget {
  final bool filled;
  final Color color;
  final ArrowDirection? arrow;

  const _EditorCell({
    required this.filled,
    required this.color,
    this.arrow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: filled ? null : const Color(0xFF282834),
        gradient: filled
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.25, 0.75, 1.0],
                colors: [
                  AppColors.lighten(color),
                  color,
                  color,
                  AppColors.darken(color),
                ],
              )
            : null,
        border:
            filled ? null : Border.all(color: const Color(0xFF373744), width: 1),
      ),
      child: filled && arrow != null
          ? Center(
              child: CustomPaint(
                size: const Size(18, 18),
                painter: _ArrowTriangle(arrow!),
              ),
            )
          : null,
    );
  }
}

class _ArrowTriangle extends CustomPainter {
  final ArrowDirection d;
  const _ArrowTriangle(this.d);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2, s = size.width * 0.4;
    final p = Path();
    switch (d) {
      case ArrowDirection.up:
        p.addPolygon([Offset(cx, cy - s), Offset(cx - s, cy + s), Offset(cx + s, cy + s)], true);
      case ArrowDirection.down:
        p.addPolygon([Offset(cx, cy + s), Offset(cx - s, cy - s), Offset(cx + s, cy - s)], true);
      case ArrowDirection.left:
        p.addPolygon([Offset(cx - s, cy), Offset(cx + s, cy - s), Offset(cx + s, cy + s)], true);
      case ArrowDirection.right:
        p.addPolygon([Offset(cx + s, cy), Offset(cx - s, cy - s), Offset(cx - s, cy + s)], true);
    }
    canvas.drawPath(p, Paint()..color = Colors.white.withOpacity(0.9));
    canvas.drawPath(
        p,
        Paint()
          ..color = Colors.black.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(_ArrowTriangle o) => o.d != d;
}