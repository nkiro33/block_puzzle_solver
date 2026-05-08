import 'dart:math';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/game_constants.dart';
import '../constants/shape_definitions.dart';
import '../effects/board_clear_rings.dart';
import '../effects/clear_animation.dart';
import '../effects/floating_score.dart';
import '../effects/particle.dart';
import '../models/block_shape.dart';
import '../solver/solver.dart';

@immutable
class GridPos {
  final int x, y;
  const GridPos(this.x, this.y);
}

class GameController extends ChangeNotifier {
  final Random _rng = Random();

  // ===================================================================
  // CORE STATE
  // ===================================================================
  late List<List<Color?>> grid;
  int score = 0;
  int highScore = 0;
  bool gameOver = false;
  List<BlockShape> shapes = [];

  /// Arrow directions currently sitting on the grid.
  /// Cleared when the round completes and expansions are processed.
  final Map<(int, int), ArrowDirection> gridArrows = {};

  // ===================================================================
  // DRAG STATE
  // ===================================================================
  int? draggingIndex;
  Offset dragPosition = Offset.zero;
  GridPos? snapPosition;

  BlockShape? get draggingShape =>
      draggingIndex != null ? shapes[draggingIndex!] : null;

  // ===================================================================
  // EFFECTS
  // ===================================================================
  final List<Particle> particles = [];
  final List<FloatingScore> floatingScores = [];
  final List<ClearAnimation> clearAnimations = [];
  BoardClearRings? boardClearRings;

  bool get hasActiveEffects =>
      particles.isNotEmpty ||
      floatingScores.isNotEmpty ||
      clearAnimations.isNotEmpty ||
      boardClearRings != null;

  Rect _gridRect = Rect.zero;
  double _cellSize = 0;
  void setGridLayout(Rect r, double c) {
    _gridRect = r;
    _cellSize = c;
  }

  // ===================================================================
  // DEV MODE
  // ===================================================================
  bool devMode = false;
  int paintColorIndex = 0;

  int? editingShapeIndex;
  Color get paintColor => AppColors.shapeColors[paintColorIndex];
  BlockShape? get editingShape =>
      editingShapeIndex != null ? shapes[editingShapeIndex!] : null;

  bool _isPainting = false;
  bool? _paintAdding;
  (int, int)? _lastPaintCell;
  void _resetPaintStroke() {
    _isPainting = false;
    _paintAdding = null;
    _lastPaintCell = null;
  }

  void toggleDevMode() {
    devMode = !devMode;
    draggingIndex = null;
    snapPosition = null;
    _resetPaintStroke();
    if (devMode) {
      gameOver = false;
    } else {
      if (editingShapeIndex != null) {
        _normalizeShape(shapes[editingShapeIndex!]);
        editingShapeIndex = null;
      }
      showSolution = false;
      solverResult = null;
      solverInitialGrid = null;
      gameOver = !_canAnyShapeBePlaced();
      if (gameOver && score > highScore) highScore = score;
    }
    notifyListeners();
  }

  void setPaintColor(int i) {
    if (i == paintColorIndex) return;
    paintColorIndex = i;
    notifyListeners();
  }

  // --- grid painting ---
  void paintGridStart(int r, int c) {
    if (!devMode) return;
    _isPainting = true;
    _paintAdding = null;
    _lastPaintCell = null;
    _paintGridCell(r, c);
  }

  void paintGridUpdate(int r, int c) {
    if (!_isPainting) return;
    _paintGridCell(r, c);
  }

  void paintGridEnd() => _resetPaintStroke();

  void _paintGridCell(int r, int c) {
    if (r < 0 || r >= GameConstants.gridSize) return;
    if (c < 0 || c >= GameConstants.gridSize) return;
    if (_lastPaintCell == (r, c)) return;
    _lastPaintCell = (r, c);
    _paintAdding ??= grid[r][c] == null;
    if (_paintAdding!) {
      grid[r][c] = paintColor;
    } else {
      grid[r][c] = null;
    }
    gridArrows.remove((r, c));
    notifyListeners();
  }

  // --- shape editing ---
  void openShapeEditor(int idx) {
    if (!devMode || shapes[idx].placed) return;
    editingShapeIndex = idx;
    final shape = shapes[idx];
    final dx = (GameConstants.shapeEditorSize - shape.width) ~/ 2;
    final dy = (GameConstants.shapeEditorSize - shape.height) ~/ 2;
    if (dx > 0 || dy > 0) {
      shape.blocks.replaceRange(0, shape.blocks.length,
          shape.blocks.map((b) => Block(b.x + dx, b.y + dy, b.arrow)));
    }
    notifyListeners();
  }

  void closeShapeEditor() {
    if (editingShapeIndex != null) _normalizeShape(shapes[editingShapeIndex!]);
    editingShapeIndex = null;
    _resetPaintStroke();
    notifyListeners();
  }

  void paintShapeStart(int x, int y) {
    if (editingShapeIndex == null) return;
    _isPainting = true;
    _paintAdding = null;
    _lastPaintCell = null;
    _paintShapeCell(x, y);
  }

  void paintShapeUpdate(int x, int y) {
    if (!_isPainting) return;
    _paintShapeCell(x, y);
  }

  void paintShapeEnd() => _resetPaintStroke();

  void _paintShapeCell(int x, int y) {
    const s = GameConstants.shapeEditorSize;
    if (x < 0 || x >= s || y < 0 || y >= s) return;
    if (_lastPaintCell == (x, y)) return;
    _lastPaintCell = (x, y);
    final shape = shapes[editingShapeIndex!];
    final block = Block(x, y);
    final exists = shape.blocks.contains(block);
    _paintAdding ??= !exists;
    if (_paintAdding!) {
      if (!exists) shape.blocks.add(block);
    } else {
      if (exists && shape.blocks.length > 1) shape.blocks.remove(block);
    }
    notifyListeners();
  }

  void _normalizeShape(BlockShape shape) {
    if (shape.blocks.isEmpty) return;
    var mx = shape.blocks.first.x, my = shape.blocks.first.y;
    for (final b in shape.blocks) {
      if (b.x < mx) mx = b.x;
      if (b.y < my) my = b.y;
    }
    if (mx == 0 && my == 0) return;
    shape.blocks.replaceRange(0, shape.blocks.length,
        shape.blocks.map((b) => Block(b.x - mx, b.y - my, b.arrow)));
  }
  // --- Arrow cycling (dev mode) -------------------------------------

  /// Clockwise cycle: none → up → right → down → left → none.
  static ArrowDirection? _nextArrowDirection(ArrowDirection? current) {
    switch (current) {
      case null:
        return ArrowDirection.up;
      case ArrowDirection.up:
        return ArrowDirection.right;
      case ArrowDirection.right:
        return ArrowDirection.down;
      case ArrowDirection.down:
        return ArrowDirection.left;
      case ArrowDirection.left:
        return null;
    }
  }

  /// Cycle the arrow on a filled grid cell. Returns `true` if the cell
  /// was valid (so the widget can fire haptic feedback).
  bool cycleGridArrow(int row, int col) {
    if (!devMode) return false;
    if (row < 0 || row >= GameConstants.gridSize) return false;
    if (col < 0 || col >= GameConstants.gridSize) return false;
    if (grid[row][col] == null) return false;

    final next = _nextArrowDirection(gridArrows[(row, col)]);
    if (next == null) {
      gridArrows.remove((row, col));
    } else {
      gridArrows[(row, col)] = next;
    }
    notifyListeners();
    return true;
  }

  /// Cycle the arrow on a block inside the shape being edited.
  bool cycleShapeArrow(int x, int y) {
    if (editingShapeIndex == null) return false;
    final shape = shapes[editingShapeIndex!];
    final idx = shape.blocks.indexWhere((b) => b.x == x && b.y == y);
    if (idx < 0) return false;

    final next = _nextArrowDirection(shape.blocks[idx].arrow);
    shape.blocks[idx] = Block(x, y, next);
    notifyListeners();
    return true;
  }

  // ===================================================================
  // SOLVER
  // ===================================================================
  bool isSolving = false;
  SolverResult? solverResult;
  bool showSolution = false;
  List<List<Color?>>? solverInitialGrid;

  Future<void> startSolver() async {
    if (isSolving) return;
    final unplaced = shapes.where((s) => !s.placed).toList();
    if (unplaced.isEmpty) return;

    isSolving = true;
    solverResult = null;
    showSolution = false;
    solverInitialGrid = grid.map((r) => List<Color?>.from(r)).toList();
    notifyListeners();

    final gridData = grid.map((r) => r.map((c) => c?.value).toList()).toList();
    final shapesData = <SolverShape>[];
    for (int i = 0; i < shapes.length; i++) {
      if (shapes[i].placed) continue;
      shapesData.add(SolverShape(
        shapes[i]
            .blocks
            .map((b) =>
                SolverBlock(b.x, b.y, b.arrow?.dx ?? 0, b.arrow?.dy ?? 0))
            .toList(),
        shapes[i].color.value,
        i,
      ));
    }

    try {
      final result = await compute(runSolver, SolverInput(gridData, shapesData))
          .timeout(const Duration(seconds: 30),
              onTimeout: () => SolverResult(null, 0, 0));
      solverResult = result;
      showSolution = true;
    } catch (_) {
      solverResult = SolverResult(null, 0, 0);
      showSolution = true;
    }
    isSolving = false;
    notifyListeners();
  }

  void closeSolution() {
    showSolution = false;
    solverResult = null;
    solverInitialGrid = null;
    notifyListeners();
  }

  // ===================================================================
  // LIFECYCLE
  // ===================================================================
  GameController() {
    _resetState();
  }

  void _resetState() {
    grid = List.generate(GameConstants.gridSize,
        (_) => List<Color?>.filled(GameConstants.gridSize, null));
    score = 0;
    gameOver = false;
    draggingIndex = null;
    snapPosition = null;
    editingShapeIndex = null;
    _resetPaintStroke();
    gridArrows.clear();
    particles.clear();
    floatingScores.clear();
    clearAnimations.clear();
    boardClearRings = null;
    isSolving = false;
    solverResult = null;
    showSolution = false;
    solverInitialGrid = null;
    _generateNewShapes();
  }

  void resetGame() {
    _resetState();
    notifyListeners();
  }

  // ===================================================================
  // SHAPE GENERATION
  // ===================================================================
  void _generateNewShapes() {
    shapes = List.generate(GameConstants.shapesPerRound, (_) {
      final template =
          ShapeDefinitions.all[_rng.nextInt(ShapeDefinitions.all.length)];
      final color =
          AppColors.shapeColors[_rng.nextInt(AppColors.shapeColors.length)];
      final shape = BlockShape(blocks: List.of(template), color: color);
      return shape;
    });
  }

  /// ~25 % chance to attach an outward-pointing arrow to one random block.
  void _maybeAddArrow(BlockShape shape) {
    if (shape.blocks.length <= 1) return; // no arrows on single dots
    if (_rng.nextDouble() > 0.25) return;

    final idx = _rng.nextInt(shape.blocks.length);
    final b = shape.blocks[idx];

    // collect directions that point *outside* this shape
    final dirs = <ArrowDirection>[];
    for (final d in ArrowDirection.values) {
      if (!shape.blocks.any((o) => o.x == b.x + d.dx && o.y == b.y + d.dy)) {
        dirs.add(d);
      }
    }
    if (dirs.isEmpty) return;

    shape.blocks[idx] = Block(b.x, b.y, dirs[_rng.nextInt(dirs.length)]);
  }

  // ===================================================================
  // PLACEMENT
  // ===================================================================
  bool canPlaceShape(BlockShape shape, int gx, int gy) {
    for (final b in shape.blocks) {
      final cx = gx + b.x, cy = gy + b.y;
      if (cx < 0 || cx >= GameConstants.gridSize) return false;
      if (cy < 0 || cy >= GameConstants.gridSize) return false;
      if (grid[cy][cx] != null) return false;
    }
    return true;
  }

  GridPos? _findNearestValid(BlockShape shape, int gx, int gy) {
    if (canPlaceShape(shape, gx, gy)) return GridPos(gx, gy);
    for (int r = 1; r <= GameConstants.snapSearchRadius; r++) {
      GridPos? best;
      int bestD = 1 << 30;
      for (int dx = -r; dx <= r; dx++) {
        for (int dy = -r; dy <= r; dy++) {
          if (dx.abs() != r && dy.abs() != r) continue;
          final nx = gx + dx, ny = gy + dy;
          if (canPlaceShape(shape, nx, ny)) {
            final d = dx * dx + dy * dy;
            if (d < bestD) {
              bestD = d;
              best = GridPos(nx, ny);
            }
          }
        }
      }
      if (best != null) return best;
    }
    return null;
  }

  void _placeShapeAt(BlockShape shape, int gx, int gy) {
    for (final b in shape.blocks) {
      final cy = gy + b.y, cx = gx + b.x;
      grid[cy][cx] = shape.color;
      if (b.arrow != null) {
        gridArrows[(cy, cx)] = b.arrow!;
      }
    }
    score += shape.blocks.length;
    shape.placed = true;

    _clearLines();

    if (_isBoardClear()) {
      score += GameConstants.boardClearBonus;
      if (_gridRect != Rect.zero) {
        boardClearRings = BoardClearRings(_gridRect.center);
      }
      _spawnFloatingScore(
          'BOARD CLEAR! +${GameConstants.boardClearBonus}', AppColors.gold);
    }

    if (_allShapesPlaced()) {
      _processExpansions();
      _generateNewShapes();
    }

    if (!_canAnyShapeBePlaced()) {
      gameOver = true;
      if (score > highScore) highScore = score;
    }
  }

  // ===================================================================
  // ARROW EXPANSION
  // ===================================================================
  void _processExpansions() {
    if (gridArrows.isEmpty) return;

    final pending = Map.of(gridArrows);
    gridArrows.clear();

    bool added = false;
    for (final entry in pending.entries) {
      final (row, col) = entry.key;
      final dir = entry.value;
      final srcColor = grid[row][col];
      if (srcColor == null) continue; // was cleared

      final nr = row + dir.dy;
      final nc = col + dir.dx;
      if (nr < 0 || nr >= GameConstants.gridSize) continue;
      if (nc < 0 || nc >= GameConstants.gridSize) continue;
      if (grid[nr][nc] != null) continue;

      grid[nr][nc] = srcColor;
      added = true;
      _spawnParticlesAt(nr, nc, srcColor);
    }

    if (!added) return;

    _spawnFloatingScore('Arrows expand!', const Color(0xFF64C8FF));
    _clearLines();

    if (_isBoardClear()) {
      score += GameConstants.boardClearBonus;
      if (_gridRect != Rect.zero) {
        boardClearRings = BoardClearRings(_gridRect.center);
      }
      _spawnFloatingScore(
          'BOARD CLEAR! +${GameConstants.boardClearBonus}', AppColors.gold);
    }
  }

  // ===================================================================
  // LINE CLEARING
  // ===================================================================
  void _clearLines() {
    final rows = <int>[];
    final cols = <int>[];

    for (int r = 0; r < GameConstants.gridSize; r++) {
      if (grid[r].every((c) => c != null)) rows.add(r);
    }
    for (int c = 0; c < GameConstants.gridSize; c++) {
      var full = true;
      for (int r = 0; r < GameConstants.gridSize; r++) {
        if (grid[r][c] == null) {
          full = false;
          break;
        }
      }
      if (full) cols.add(c);
    }

    if (rows.isEmpty && cols.isEmpty) return;

    final visited = <int>{};
    final clearing = <ClearingCell>[];

    void add(int r, int c) {
      final key = r * GameConstants.gridSize + c;
      if (!visited.add(key)) return;
      final color = grid[r][c] ?? Colors.white;
      clearing.add(ClearingCell(r, c, color));
      _spawnParticlesAt(r, c, color);
    }

    for (final r in rows) {
      for (int c = 0; c < GameConstants.gridSize; c++) add(r, c);
    }
    for (final c in cols) {
      for (int r = 0; r < GameConstants.gridSize; r++) add(r, c);
    }

    clearAnimations.add(ClearAnimation(clearing));

    for (final cell in clearing) {
      grid[cell.row][cell.col] = null;
      gridArrows.remove((cell.row, cell.col));
    }

    final total = rows.length + cols.length;
    final base = total * GameConstants.lineBaseScore;
    if (total >= 2) {
      final mult = 1 + (total - 1) * GameConstants.comboMultiplierStep;
      final bonus = (base * mult).toInt();
      score += bonus;
      _spawnFloatingScore('COMBO ×$total! +$bonus', AppColors.comboText);
    } else {
      score += base;
      _spawnFloatingScore('+$base', AppColors.scorePopup);
    }
  }

  bool _isBoardClear() {
    for (final row in grid) {
      for (final c in row) {
        if (c != null) return false;
      }
    }
    return true;
  }

  bool _allShapesPlaced() => shapes.every((s) => s.placed);

  bool _canAnyShapeBePlaced() {
    for (final shape in shapes) {
      if (shape.placed) continue;
      for (int r = 0; r < GameConstants.gridSize; r++) {
        for (int c = 0; c < GameConstants.gridSize; c++) {
          if (canPlaceShape(shape, c, r)) return true;
        }
      }
    }
    return false;
  }

  // ===================================================================
  // DRAG
  // ===================================================================
  void startDrag(int index, Offset pos) {
    if (gameOver || devMode || shapes[index].placed) return;
    draggingIndex = index;
    dragPosition = pos;
    snapPosition = null;
    notifyListeners();
  }

  void updateDrag(Offset stackPos, Offset? gridPos) {
    if (draggingIndex == null) return;
    dragPosition = stackPos;
    if (gridPos != null && _cellSize > 0) {
      final shape = draggingShape!;
      final tx = (gridPos.dx / _cellSize - shape.width / 2.0).round();
      final ty = (gridPos.dy / _cellSize - shape.height / 2.0).round();
      snapPosition = _findNearestValid(shape, tx, ty);
    } else {
      snapPosition = null;
    }
    notifyListeners();
  }

  void endDrag() {
    if (draggingIndex == null) return;
    if (snapPosition != null) {
      _placeShapeAt(draggingShape!, snapPosition!.x, snapPosition!.y);
    }
    draggingIndex = null;
    snapPosition = null;
    notifyListeners();
  }

  // ===================================================================
  // EFFECTS
  // ===================================================================
  void _spawnParticlesAt(int row, int col, Color color) {
    if (_cellSize == 0) return;
    final x = _gridRect.left + col * _cellSize + _cellSize / 2;
    final y = _gridRect.top + row * _cellSize + _cellSize / 2;
    for (int i = 0; i < 6; i++) {
      particles.add(Particle.burst(x, y, color, _rng));
    }
  }

  void _spawnFloatingScore(String text, Color color) {
    if (_gridRect == Rect.zero) return;
    floatingScores
        .add(FloatingScore(text: text, origin: _gridRect.center, color: color));
  }

  void tickEffects() {
    particles.removeWhere((p) => !p.update());
    floatingScores.removeWhere((f) => !f.update());
    clearAnimations.removeWhere((c) => !c.update());
    if (boardClearRings != null && !boardClearRings!.update()) {
      boardClearRings = null;
    }
    notifyListeners();
  }
}
