import 'package:flutter/material.dart';

abstract class AppColors {
  // Layout
  static const background = Color(0xFF191923);
  static const gridBg = Color(0xFF2D2D3A);
  static const emptyCell = Color(0xFF232330);
  static const emptyCellBorder = Color(0xFF2D2D3A);
  static const scoreBg = Color(0xFF373744);
  static const shapeAreaBg = Color(0xFF282834);
  static const shapeAreaBorder = Color(0xFF3C3C4B);

  // Text
  static const text = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB4B4BE);

  // Gameplay
  static const previewValid = Color(0xFF64FF64);
  static const gold = Color(0xFFFFD700);
  static const comboText = Color(0xFFFFC832);
  static const scorePopup = Color(0xFFFFFF64);

  // Shape palette
  static const List<Color> shapeColors = [
    Color(0xFFFF6B6B), // red
    Color(0xFF4ECDC4), // teal
    Color(0xFFFFE66D), // yellow
    Color(0xFFAA78FF), // purple
    Color(0xFFFFB142), // orange
    Color(0xFF63CDDA), // light blue
    Color(0xFFFF8FB1), // pink
    Color(0xFF90EE90), // light green
  ];

  /// Lighten a color by [amount] (0–255 per channel).
  static Color lighten(Color c, [int amount = 40]) => Color.fromARGB(
        c.alpha,
        (c.red + amount).clamp(0, 255),
        (c.green + amount).clamp(0, 255),
        (c.blue + amount).clamp(0, 255),
      );

  /// Darken a color by [amount] (0–255 per channel).
  static Color darken(Color c, [int amount = 40]) => Color.fromARGB(
        c.alpha,
        (c.red - amount).clamp(0, 255),
        (c.green - amount).clamp(0, 255),
        (c.blue - amount).clamp(0, 255),
      );
}