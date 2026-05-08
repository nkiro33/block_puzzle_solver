const int _gridSize = 8;

// ---------------------------------------------------------------
// Data transfer objects
// ---------------------------------------------------------------

class SolverInput {
  final List<List<int?>> grid;
  final List<SolverShape> shapes;
  SolverInput(this.grid, this.shapes);
}

class SolverBlock {
  final int x, y;
  /// (0,0) means no arrow.
  final int arrowDx, arrowDy;
  bool get hasArrow => arrowDx != 0 || arrowDy != 0;
  SolverBlock(this.x, this.y, [this.arrowDx = 0, this.arrowDy = 0]);
}

class SolverShape {
  final List<SolverBlock> blocks;
  final int colorValue;
  final int originalIndex;
  SolverShape(this.blocks, this.colorValue, this.originalIndex);
}

class Placement {
  final int originalShapeIndex;
  final List<SolverBlock> blocks;
  final int colorValue;
  final int gridX, gridY;
  Placement(this.originalShapeIndex, this.blocks, this.colorValue,
      this.gridX, this.gridY);
}

class SolverResult {
  final List<Placement>? placements;
  final int permutationsChecked;
  final int totalPermutations;
  SolverResult(this.placements, this.permutationsChecked, this.totalPermutations);
  bool get found => placements != null && placements!.isNotEmpty;
}

// ---------------------------------------------------------------
SolverResult runSolver(SolverInput input) => _Solver(input).run();
// ---------------------------------------------------------------

class _Solver {
  final SolverInput input;
  _Solver(this.input);

  SolverResult run() {
    if (input.shapes.isEmpty) return SolverResult(const [], 0, 0);
    final perms = _permutations(List.generate(input.shapes.length, (i) => i));
    for (int pi = 0; pi < perms.length; pi++) {
      final ordered = [for (final i in perms[pi]) input.shapes[i]];
      final r = _solve(_copy(input.grid), ordered, 0, []);
      if (r != null) return SolverResult(r, pi + 1, perms.length);
    }
    return SolverResult(null, perms.length, perms.length);
  }

  List<Placement>? _solve(List<List<int?>> grid, List<SolverShape> shapes,
      int depth, List<Placement> cur) {
    if (depth >= shapes.length) return List.of(cur);
    final shape = shapes[depth];
    for (int gy = 0; gy < _gridSize; gy++) {
      for (int gx = 0; gx < _gridSize; gx++) {
        if (!_canPlace(grid, shape.blocks, gx, gy)) continue;
        final placed = _place(grid, shape.blocks, shape.colorValue, gx, gy);
        final cleared = _clearLines(placed);
        cur.add(Placement(shape.originalIndex, shape.blocks, shape.colorValue, gx, gy));
        final r = _solve(cleared, shapes, depth + 1, cur);
        if (r != null) return r;
        cur.removeLast();
      }
    }
    return null;
  }

  static bool _canPlace(List<List<int?>> g, List<SolverBlock> blocks, int gx, int gy) {
    for (final b in blocks) {
      final cx = gx + b.x, cy = gy + b.y;
      if (cx < 0 || cx >= _gridSize || cy < 0 || cy >= _gridSize) return false;
      if (g[cy][cx] != null) return false;
    }
    return true;
  }

  static List<List<int?>> _place(
      List<List<int?>> g, List<SolverBlock> blocks, int c, int gx, int gy) {
    final n = _copy(g);
    for (final b in blocks) n[gy + b.y][gx + b.x] = c;
    return n;
  }

  static List<List<int?>> _clearLines(List<List<int?>> g) {
    final n = _copy(g);
    final rows = <int>[], cols = <int>[];
    for (int r = 0; r < _gridSize; r++) {
      if (n[r].every((c) => c != null)) rows.add(r);
    }
    for (int c = 0; c < _gridSize; c++) {
      var f = true;
      for (int r = 0; r < _gridSize; r++) {
        if (n[r][c] == null) { f = false; break; }
      }
      if (f) cols.add(c);
    }
    for (final r in rows) for (int c = 0; c < _gridSize; c++) n[r][c] = null;
    for (final c in cols) for (int r = 0; r < _gridSize; r++) n[r][c] = null;
    return n;
  }

  static List<List<int?>> _copy(List<List<int?>> g) =>
      g.map((r) => List<int?>.from(r)).toList();

  static List<List<int>> _permutations(List<int> items) {
    if (items.length <= 1) return [List.of(items)];
    final res = <List<int>>[];
    for (int i = 0; i < items.length; i++) {
      final rest = [...items.sublist(0, i), ...items.sublist(i + 1)];
      for (final p in _permutations(rest)) res.add([items[i], ...p]);
    }
    return res;
  }
}