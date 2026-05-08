import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../effects/board_clear_rings.dart';
import '../effects/floating_score.dart';
import '../effects/particle.dart';
import '../game/game_controller.dart';

class EffectsOverlay extends StatelessWidget {
  const EffectsOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Consumer<GameController>(
          builder: (context, game, _) {
            if (!game.hasActiveEffects) return const SizedBox.shrink();
            return CustomPaint(
              painter: _EffectsPainter(
                particles: game.particles,
                floatingScores: game.floatingScores,
                rings: game.boardClearRings,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EffectsPainter extends CustomPainter {
  final List<Particle> particles;
  final List<FloatingScore> floatingScores;
  final BoardClearRings? rings;

  _EffectsPainter({
    required this.particles,
    required this.floatingScores,
    required this.rings,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintRings(canvas);
    _paintParticles(canvas);
    _paintFloatingScores(canvas);
  }

  void _paintRings(Canvas canvas) {
    if (rings == null) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    for (final r in rings!.rings) {
      paint.color = const Color(0xFFFFFF64).withOpacity(r.alpha);
      canvas.drawCircle(rings!.center, r.radius, paint);
    }
  }

  void _paintParticles(Canvas canvas) {
    final paint = Paint();
    for (final p in particles) {
      final life = p.life.clamp(0.0, 1.0);
      paint.color = p.color.withOpacity(life);
      final radius = (p.size * life).clamp(0.5, p.size);
      canvas.drawCircle(Offset(p.x, p.y), radius, paint);
    }
  }

  void _paintFloatingScores(Canvas canvas) {
    for (final fs in floatingScores) {
      final tp = TextPainter(
        text: TextSpan(
          text: fs.text,
          style: TextStyle(
            color: fs.color.withOpacity(fs.life.clamp(0.0, 1.0)),
            fontSize: 26,
            fontWeight: FontWeight.bold,
            shadows: const [
              Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 3),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      final pos = fs.position - Offset(tp.width / 2, tp.height / 2);
      tp.paint(canvas, pos);
    }
  }

  @override
  bool shouldRepaint(covariant _EffectsPainter old) => true;
}