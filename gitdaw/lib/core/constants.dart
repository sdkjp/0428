class AppConstants {
  // Timeline layout
  static const double trackHeight = 130.0;
  static const double trackHeaderWidth = 180.0;
  static const double timelineRulerHeight = 44.0;
  static const double hoverPanelHeight = 64.0;

  // Zoom levels
  static const double initialPixelsPerDay = 220.0;
  static const double minPixelsPerDay = 30.0;
  static const double maxPixelsPerDay = 3000.0;

  // Layer clip dimensions
  static const double clipWidth = 130.0;
  static const double clipHeight = 72.0;
  static const double clipRadius = 10.0;
  static const double clipStackOffset = 4.0; // px per stackIndex for 3D illusion

  // Auto-commit
  static const Duration watcherDebounce = Duration(seconds: 2);
  static const int gitLogLimit = 300;

  // Branch naming
  static const String defaultClonePrefix = 'クローン';
  static const String mainBranchDisplay = 'メイン';
}
