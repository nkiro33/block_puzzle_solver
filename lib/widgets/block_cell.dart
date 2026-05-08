import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/block_shape.dart';

/// A single grid / shape cell with optional arrow overlay.
class BlockCell extends StatelessWidget {
  final Color? color;
  final double opacity;
  final ArrowDirection? arrow;

  const BlockCell({super.key, this.color, this.opacity = 1.0, this.arrow});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.maxWidth;
      final margin = (size * 0.04).clamp(1.0, 2.0);
      final radius = (size * 0.12).clamp(2.0, 6.0);

      if (color == null) {
        return Container(
          margin: EdgeInsets.all(margin),
          decoration: BoxDecoration(
            color: AppColors.emptyCell,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.emptyCellBorder, width: 1),
          ),
        );
      }

      final c = color!;

      return Container(
        margin: EdgeInsets.all(margin),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.25, 0.75, 1.0],
            colors: [
              AppColors.lighten(c).withOpacity(opacity),
              c.withOpacity(opacity),
              c.withOpacity(opacity),
              AppColors.darken(c).withOpacity(opacity),
            ],
          ),
        ),
        child: arrow != null
            ? Center(
                child: CustomPaint(
                  size: Size(size * 0.45, size * 0.45),
                  painter: _ArrowPainter(arrow!),
                ),
              )
            : null,
      );
    });
  }
}

/// Draws a filled triangle pointing in [direction].
class _ArrowPainter extends CustomPainter {
  final ArrowDirection direction;
  const _ArrowPainter(this.direction);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final s = size.width * 0.45;

    final path = Path();
    switch (direction) {
      case ArrowDirection.up:
        path.addPolygon([
          Offset(cx, cy - s),
          Offset(cx - s, cy + s),
          Offset(cx + s, cy + s),
        ], true);
      case ArrowDirection.down:
        path.addPolygon([
          Offset(cx, cy + s),
          Offset(cx - s, cy - s),
          Offset(cx + s, cy - s),
        ], true);
      case ArrowDirection.left:
        path.addPolygon([
          Offset(cx - s, cy),
          Offset(cx + s, cy - s),
          Offset(cx + s, cy + s),
        ], true);
      case ArrowDirection.right:
        path.addPolygon([
          Offset(cx + s, cy),
          Offset(cx - s, cy - s),
          Offset(cx - s, cy + s),
        ], true);
    }

    canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withOpacity(0.92)
          ..style = PaintingStyle.fill);
    canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black.withOpacity(0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => old.direction != direction;
}