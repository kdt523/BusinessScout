/// Enum representing PDF page display modes
enum PdfPageDisplayMode {
  fitWidth,
  fitHeight,
  original,
}

/// Model class for PDF viewer settings with persistence support
class PdfViewerSettings {
  final double zoomLevel;
  final PdfPageDisplayMode displayMode;
  final bool darkMode;
  final bool enableTextSelection;

  const PdfViewerSettings({
    this.zoomLevel = 1.0,
    this.displayMode = PdfPageDisplayMode.fitWidth,
    this.darkMode = false,
    this.enableTextSelection = true,
  });

  /// Creates a copy of this settings object with updated fields
  PdfViewerSettings copyWith({
    double? zoomLevel,
    PdfPageDisplayMode? displayMode,
    bool? darkMode,
    bool? enableTextSelection,
  }) {
    return PdfViewerSettings(
      zoomLevel: zoomLevel ?? this.zoomLevel,
      displayMode: displayMode ?? this.displayMode,
      darkMode: darkMode ?? this.darkMode,
      enableTextSelection: enableTextSelection ?? this.enableTextSelection,
    );
  }

  /// Converts settings to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'zoom_level': zoomLevel,
      'display_mode': displayMode.name,
      'dark_mode': darkMode,
      'enable_text_selection': enableTextSelection,
    };
  }

  /// Creates settings from JSON data
  factory PdfViewerSettings.fromJson(Map<String, dynamic> json) {
    return PdfViewerSettings(
      zoomLevel: (json['zoom_level'] as num?)?.toDouble() ?? 1.0,
      displayMode: _parseDisplayMode(json['display_mode'] as String?),
      darkMode: json['dark_mode'] as bool? ?? false,
      enableTextSelection: json['enable_text_selection'] as bool? ?? true,
    );
  }

  /// Helper method to parse display mode from string
  static PdfPageDisplayMode _parseDisplayMode(String? value) {
    if (value == null) return PdfPageDisplayMode.fitWidth;
    
    switch (value) {
      case 'fitWidth':
        return PdfPageDisplayMode.fitWidth;
      case 'fitHeight':
        return PdfPageDisplayMode.fitHeight;
      case 'original':
        return PdfPageDisplayMode.original;
      default:
        return PdfPageDisplayMode.fitWidth;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PdfViewerSettings &&
        other.zoomLevel == zoomLevel &&
        other.displayMode == displayMode &&
        other.darkMode == darkMode &&
        other.enableTextSelection == enableTextSelection;
  }

  @override
  int get hashCode {
    return Object.hash(
      zoomLevel,
      displayMode,
      darkMode,
      enableTextSelection,
    );
  }

  @override
  String toString() {
    return 'PdfViewerSettings(zoomLevel: $zoomLevel, displayMode: $displayMode, darkMode: $darkMode, enableTextSelection: $enableTextSelection)';
  }
}
