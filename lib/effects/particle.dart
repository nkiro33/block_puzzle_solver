import 'dart:math';
import 'package:flutter/material.dart';

class Particle {
  double x, y;
  double vx, vy;
  final Color color;
  double life;
  final double decay;
  final double size;

  static const double _gravity = 0.3;

  Particle._({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.decay,
    required this.size,
  }) : life = 1.0;

  factory Particle.burst(double x, double y, Color color, Random rng) {
    return Particle._(
      x: x,
      y: y,
      vx: (rng.nextDouble() - 0.5) * 6,
      vy: rng.nextDouble() * -4 - 1,
      color: color,
      decay: 0.02 + rng.nextDouble() * 0.02,
      size: 4 + rng.nextDouble() * 4,
    );
  }

  /// Advances one frame. Returns `true` while still alive.
  bool update() {
    x += vx;
    vy += _gravity;
    y += vy;
    life -= decay;
    return life > 0;
  }
}