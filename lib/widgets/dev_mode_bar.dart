import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../game/game_controller.dart';

class DevModeBar extends StatelessWidget {
  const DevModeBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, game, _) {
        return AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Toggle row ---
              Row(
                children: [
                  Switch.adaptive(
                    value: game.devMode,
                    onChanged: (_) => game.toggleDevMode(),
                    activeColor: const Color(0xFF50C878),
                  ),
                  const Text(
                    'Dev mode',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),

                  if (game.devMode) ...[
                    const Spacer(),

                    // Solve button / spinner
                    if (game.isSolving)
                      const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF50C878),
                          ),
                        ),
                      )
                    else
                      TextButton.icon(
                        onPressed: game.startSolver,
                        icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                        label: const Text('Solve'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF64C8FF),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ],
              ),

              // --- Color swatches (when on) ---
              if (game.devMode)
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 4, bottom: 4),
                  child: Row(
                    children: [
                      const Text(
                        'Paint: ',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                      for (int i = 0; i < AppColors.shapeColors.length; i++)
                        GestureDetector(
                          onTap: () => game.setPaintColor(i),
                          child: Container(
                            width: 22,
                            height: 22,
                            margin: const EdgeInsets.only(right: 5),
                            decoration: BoxDecoration(
                              color: AppColors.shapeColors[i],
                              borderRadius: BorderRadius.circular(4),
                              border: i == game.paintColorIndex
                                  ? Border.all(color: Colors.white, width: 2)
                                  : null,
                            ),
                          ),
                        ),
                      const Spacer(),
                      const Text(
                        'Tap · Drag · Hold→arrow',
                        style: TextStyle(color: Color(0xFF6A7A8A), fontSize: 11),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}