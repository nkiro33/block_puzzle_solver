import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/game_constants.dart';
import '../solver/solver.dart';

// ---------------------------------------------------------------
// One frame in the step-by-step replay
// ---------------------------------------------------------------

class _Step {
  final List<List<Color?>> grid;
  final Set<(int, int)> highlighted; // newly placed cells
  final String label;

  const _Step(this.grid, this.highlighted, this.label);
}

// ---------------------------------------------------------------
// Overlay widget
// ---------------------------------------------------------------

class SolutionOverlay extends StatefulWidget {
  final SolverResult result;
  final List<List<Color?>> initialGrid;
  final VoidCallback onClose;

  const SolutionOverlay({
    super.key,
    required this.result,
    required this.initialGrid,
    required this.onClose,
  });

  @override
  State<SolutionOverlay> createState() => _SolutionOverlayState();
}

class _SolutionOverlayState extends State<SolutionOverlay> {
  int _currentStep = 0;
  late final List<_Step> _steps = _buildSteps();

  // -----------------------------------------------------------------
  // Build step-by-step replay from placements
  // -----------------------------------------------------------------

  List<_Step> _buildSteps() {
    final placements = widget.result.placements;
    if (placements == null || placements.isEmpty) return [];

    final steps = <_Step>[];
    var grid = widget.initialGrid.map((r) => List<Color?>.from(r)).toList();
    steps.add(_Step(_copy(grid), const {}, 'Initial board'));

    // Track arrows placed on the grid for the expansion step
    final arrows = <({int row, int col, int dx, int dy})>[];

    for (int i = 0; i < placements.length; i++) {
      final p = placements[i];
      final color = Color(p.colorValue);
      final cells = <(int, int)>{};

      for (final b in p.blocks) {
        final cy = p.gridY + b.y, cx = p.gridX + b.x;
        grid[cy][cx] = color;
        cells.add((cy, cx));
        if (b.hasArrow) {
          arrows.add((row: cy, col: cx, dx: b.arrowDx, dy: b.arrowDy));
        }
      }

      steps.add(_Step(
        _copy(grid),
        cells,
        'Step ${i + 1}: shape ${p.originalShapeIndex + 1} '
            '→ (${p.gridX}, ${p.gridY})',
      ));

      grid = _clearLines(grid);
    }

    // --- Expansion step ---
    if (arrows.isNotEmpty) {
      final expanded = <(int, int)>{};
      for (final a in arrows) {
        if (grid[a.row][a.col] == null) continue;
        final nr = a.row + a.dy, nc = a.col + a.dx;
        if (nr < 0 || nr >= GameConstants.gridSize) continue;
        if (nc < 0 || nc >= GameConstants.gridSize) continue;
        if (grid[nr][nc] != null) continue;
        grid[nr][nc] = grid[a.row][a.col];
        expanded.add((nr, nc));
      }
      if (expanded.isNotEmpty) {
        steps.add(_Step(_copy(grid), expanded, 'Arrows expand!'));
        grid = _clearLines(grid);
      }
    }

    return steps;
  }

  // -----------------------------------------------------------------
  // Minimal line-clearing (mirrors solver / controller logic)
  // -----------------------------------------------------------------

  static List<List<Color?>> _clearLines(List<List<Color?>> g) {
    const s = GameConstants.gridSize;
    final ng = _copy(g);

    final rows = <int>[];
    final cols = <int>[];

    for (int r = 0; r < s; r++) {
      if (ng[r].every((c) => c != null)) rows.add(r);
    }
    for (int c = 0; c < s; c++) {
      var full = true;
      for (int r = 0; r < s; r++) {
        if (ng[r][c] == null) {
          full = false;
          break;
        }
      }
      if (full) cols.add(c);
    }

    for (final r in rows) {
      for (int c = 0; c < s; c++) ng[r][c] = null;
    }
    for (final c in cols) {
      for (int r = 0; r < s; r++) ng[r][c] = null;
    }

    return ng;
  }

  static List<List<Color?>> _copy(List<List<Color?>> g) =>
      g.map((r) => List<Color?>.from(r)).toList();

  // -----------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          // Scrim
          GestureDetector(
            onTap: widget.onClose,
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),

          // Panel
          Center(
            child: GestureDetector(
              onTap: () {}, // absorb tap so scrim doesn't close
              child: widget.result.found ? _solutionPanel() : _noSolutionPanel(),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // "No solution" panel
  // -----------------------------------------------------------------

  Widget _noSolutionPanel() {
    return _panel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded, color: Color(0xFFFF6464), size: 48),
          const SizedBox(height: 12),
          const Text(
            'No Solution',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.text),
          ),
          const SizedBox(height: 8),
          Text(
            'Checked ${widget.result.totalPermutations} permutation(s)',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          _closeButton(),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // Solution panel with step navigation
  // -----------------------------------------------------------------

  Widget _solutionPanel() {
    if (_steps.isEmpty) return _noSolutionPanel();

    final step = _steps[_currentStep];
    final isFirst = _currentStep == 0;
    final isLast = _currentStep == _steps.length - 1;

    return _panel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF50C878), size: 24),
              const SizedBox(width: 8),
              Text(
                'Solution Found',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${widget.result.placements!.length} shapes)',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Mini grid
          _MiniGrid(step: step),

          const SizedBox(height: 10),

          // Label
          Text(
            step.label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),

          const SizedBox(height: 14),

          // Navigation
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _navButton(Icons.arrow_back_rounded, isFirst ? null : _prev),
              const SizedBox(width: 8),

              // Step dots
              for (int i = 0; i < _steps.length; i++)
                Container(
                  width: i == _currentStep ? 10 : 7,
                  height: i == _currentStep ? 10 : 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _currentStep
                        ? const Color(0xFF50C878)
                        : const Color(0xFF555568),
                  ),
                ),

              const SizedBox(width: 8),
              _navButton(Icons.arrow_forward_rounded, isLast ? null : _next),
            ],
          ),

          const SizedBox(height: 14),
          _closeButton(),
        ],
      ),
    );
  }

  void _prev() => setState(() => _currentStep--);
  void _next() => setState(() => _currentStep++);

  // -----------------------------------------------------------------
  // Reusable pieces
  // -----------------------------------------------------------------

  Widget _panel({required Widget child}) {
    return Material(
      color: const Color(0xFF2A2A3A),
      borderRadius: BorderRadius.circular(16),
      elevation: 12,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF4A4A60), width: 2),
        ),
        child: child,
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback? onPressed) {
    final enabled = onPressed != null;
    return Material(
      color: enabled ? const Color(0xFF3A3A50) : const Color(0xFF2A2A38),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 22,
            color: enabled ? AppColors.text : const Color(0xFF555568),
          ),
        ),
      ),
    );
  }

  Widget _closeButton() {
    return TextButton(
      onPressed: widget.onClose,
      child:
          const Text('Close', style: TextStyle(color: AppColors.textSecondary)),
    );
  }
}

// ---------------------------------------------------------------
// Mini 8×8 grid that renders a single step
// ---------------------------------------------------------------

class _MiniGrid extends StatelessWidget {
  final _Step step;

  const _MiniGrid({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    const gridCells = GameConstants.gridSize;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Fit grid into available width, capped for readability
        final maxSide = math.min(constraints.maxWidth, 280.0);
        final cellSize = maxSide / gridCells;

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2A),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(3),
          child: SizedBox(
            width: cellSize * gridCells,
            height: cellSize * gridCells,
            child: Stack(
              children: [
                for (int r = 0; r < gridCells; r++)
                  for (int c = 0; c < gridCells; c++)
                    Positioned(
                      left: c * cellSize,
                      top: r * cellSize,
                      width: cellSize,
                      height: cellSize,
                      child: _MiniCell(
                        color: step.grid[r][c],
                        highlighted: step.highlighted.contains((r, c)),
                        cellSize: cellSize,
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MiniCell extends StatelessWidget {
  final Color? color;
  final bool highlighted;
  final double cellSize;

  const _MiniCell({
    required this.color,
    required this.highlighted,
    required this.cellSize,
  });

  @override
  Widget build(BuildContext context) {
    final margin = (cellSize * 0.06).clamp(0.5, 2.0);
    final radius = (cellSize * 0.14).clamp(1.5, 6.0);

    if (color == null) {
      return Container(
        margin: EdgeInsets.all(margin),
        decoration: BoxDecoration(
          color: const Color(0xFF282834),
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.all(margin),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.3, 0.7, 1.0],
          colors: [
            AppColors.lighten(color!),
            color!,
            color!,
            AppColors.darken(color!),
          ],
        ),
        border: highlighted
            ? Border.all(color: const Color(0xFFFFD700), width: 2)
            : null,
        boxShadow: highlighted
            ? const [BoxShadow(color: Color(0x60FFD700), blurRadius: 4)]
            : null,
      ),
    );
  }
}