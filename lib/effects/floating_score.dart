import 'package:flutter/material.dart';

class FloatingScore {
  final String text;
  final Color color;
  final Offset origin;

  double life = 1.0;
  double offsetY = 0;
  double vy = -2.0;

  static const double _decay = 0.022;

  FloatingScore({
    required this.text,
    required this.origin,
    required this.color,
  });

  Offset get position => origin + Offset(0, offsetY);

  /// Returns `true` while still alive.
  bool update() {
    offsetY += vy;
    vy *= 0.95;
    life -= _decay;
    return life > 0;
  }
}