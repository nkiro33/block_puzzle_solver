import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class GameOverOverlay extends StatefulWidget {
  final int score;
  final int highScore;
  final bool isNewBest;
  final VoidCallback onRestart;

  const GameOverOverlay({
    super.key,
    required this.score,
    required this.highScore,
    required this.isNewBest,
    required this.onRestart,
  });

  @override
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onRestart,
        child: Container(
          color: Colors.black.withOpacity(0.7),
          child: Center(
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF323241),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF505064), width: 3),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'GAME OVER',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6464),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Score: ${widget.score}',
                    style: const TextStyle(fontSize: 24, color: AppColors.text),
                  ),
                  if (widget.isNewBest) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'NEW BEST!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, _) {
                      final b = (180 + _pulse.value * 75).round();
                      return Text(
                        'Tap to restart',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color.fromRGBO(b, b, b, 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}