abstract class GameConstants {
  static const int gridSize = 8;
  static const int shapesPerRound = 3;

  // Scoring
  static const int boardClearBonus = 500;
  static const int lineBaseScore = 100;
  static const double comboMultiplierStep = 0.5;

  // Drag UX: lift shape above finger so the player can see it on mobile.
  static const double dragLiftOffset = 70.0;

  /// How far (in cells) to search for a valid spot when the exact
  /// target is blocked. 1 = only adjacent cells. Prevents the preview
  /// from jumping across the board.
  static const int snapSearchRadius = 1;

  // Dev mode
  static const int shapeEditorSize = 5; // 5x5 canvas for editing shapes
}