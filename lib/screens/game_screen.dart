import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/game_constants.dart';
import '../game/game_controller.dart';
import '../widgets/dev_mode_bar.dart';
import '../widgets/drag_shape_overlay.dart';
import '../widgets/effects_overlay.dart';
import '../widgets/game_grid.dart';
import '../widgets/game_over_overlay.dart';
import '../widgets/score_bar.dart';
import '../widgets/shape_editor_overlay.dart';
import '../widgets/shape_tray.dart';
import '../widgets/solution_overlay.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _gridKey = GlobalKey();
  late final Ticker _ticker;

  static const double _trayHeight = 110;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration _) {
    if (!mounted) return;
    final game = context.read<GameController>();
    if (game.hasActiveEffects) game.tickEffects();
  }

  // --- Coordinate helpers ---
  RenderBox? get _stackBox =>
      _stackKey.currentContext?.findRenderObject() as RenderBox?;
  RenderBox? get _gridBox =>
      _gridKey.currentContext?.findRenderObject() as RenderBox?;

  double get _cellSize {
    final box = _gridBox;
    return box == null ? 0 : box.size.width / GameConstants.gridSize;
  }

  Offset _globalToStack(Offset g) => _stackBox?.globalToLocal(g) ?? g;

  Offset? _globalToGrid(Offset g) {
    final box = _gridBox;
    if (box == null) return null;
    final local = box.globalToLocal(g);
    if (local.dx < 0 || local.dy < 0) return null;
    if (local.dx > box.size.width || local.dy > box.size.height) return null;
    return local;
  }

  void _syncGridLayout() {
    final grid = _gridBox;
    final stack = _stackBox;
    if (grid == null || stack == null) return;
    final topLeft = stack.globalToLocal(grid.localToGlobal(Offset.zero));
    context.read<GameController>().setGridLayout(
          topLeft & grid.size,
          grid.size.width / GameConstants.gridSize,
        );
  }

  // --- Drag callbacks ---
  void _onDragStart(int index, Offset global) {
    final lifted = global - const Offset(0, GameConstants.dragLiftOffset);
    context.read<GameController>().startDrag(index, _globalToStack(lifted));
  }

  void _onDragUpdate(Offset global) {
    final lifted = global - const Offset(0, GameConstants.dragLiftOffset);
    context.read<GameController>().updateDrag(
          _globalToStack(lifted),
          _globalToGrid(lifted),
        );
  }

  void _onDragEnd() => context.read<GameController>().endDrag();

  // --- Build ---
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncGridLayout());

    return Scaffold(
      body: SafeArea(
        child: Stack(
          key: _stackKey,
          fit: StackFit.expand,
          children: [
            // ---------------- Main layout ----------------
            Column(
              children: [
                const _TitleBar(),
                const SizedBox(height: 8),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppColors.gridBg,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x800F0F14),
                            offset: Offset(0, 4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: GameGrid(key: _gridKey),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: ScoreBar(),
                ),

                const SizedBox(height: 12),

                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      height: _trayHeight,
                      child: ShapeTray(
                        onDragStart: _onDragStart,
                        onDragUpdate: _onDragUpdate,
                        onDragEnd: _onDragEnd,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Dev mode controls
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: DevModeBar(),
                ),

                const SizedBox(height: 12),
              ],
            ),

            // ---------------- Drag overlay ----------------
            Consumer<GameController>(
              builder: (context, game, _) {
                final shape = game.draggingShape;
                if (shape == null) return const SizedBox.shrink();
                return DragShapeOverlay(
                  shape: shape,
                  position: game.dragPosition,
                  cellSize: _cellSize,
                );
              },
            ),

            // ---------------- Effects ----------------
            const EffectsOverlay(),

            // ---------------- Shape editor (dev mode) ----------------
            const ShapeEditorOverlay(),
            // ---------------- Solution overlay (dev mode) --------
            Consumer<GameController>(
              builder: (context, game, _) {
                if (!game.showSolution || game.solverResult == null) {
                  return const SizedBox.shrink();
                }
                return SolutionOverlay(
                  result: game.solverResult!,
                  initialGrid: game.solverInitialGrid!,
                  onClose: game.closeSolution,
                );
              },
            ),

            // ---------------- Game over ----------------
            // Hidden while dev mode is on so you can rescue the board.
            Consumer<GameController>(
              builder: (context, game, _) {
                if (!game.gameOver || game.devMode) {
                  return const SizedBox.shrink();
                }
                return GameOverOverlay(
                  score: game.score,
                  highScore: game.highScore,
                  isNewBest: game.score >= game.highScore && game.score > 0,
                  onRestart: game.resetGame,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleBar extends StatelessWidget {
  const _TitleBar();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 12),
      child: Text(
        'BLOCK PUZZLE SOLVER',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          color: AppColors.text,
        ),
      ),
    );
  }
}
