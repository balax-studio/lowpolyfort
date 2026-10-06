/// Layout dimensions, virtual canvas size, and runtime engine configurations.
class GameConfig {
  GameConfig._();

  // Virtual logical resolution for 9:16 portrait design
  static const double virtualWidth = 450.0;
  static const double virtualHeight = 800.0;

  // 3x3 Defense Grid
  static const int gridRows = 3;
  static const int gridCols = 3;
  static const int totalSlots = gridRows * gridCols; // 9

  // Slot sizing & positioning
  static const double slotWidth = 76.0;
  static const double slotHeight = 60.0;
  static const double slotSpacingX = 14.0;
  static const double slotSpacingY = 12.0;

  // Base bunker dimensions
  static const double baseHeight = 90.0;
  static const double baseWidth = 430.0;

  // Lanes for enemy pathing
  static const int spawnLanes = 5;
  static const double topSpawnY = -40.0;

  // Debug flag (can be toggled in dev)
  static bool isDebugMode = true;
}
