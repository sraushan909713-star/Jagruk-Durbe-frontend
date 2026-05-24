// lib/core/theme/banner_themes.dart
// ──────────────────────────────────────────────────────────────────
// Curated gradient themes for banners.
//
// Each theme name (e.g. 'indigo_night') maps to a two-color gradient.
// The backend stores only the theme key string; actual colors live
// here so we can add or refine themes without touching the database
// or running migrations.
//
// Used by:
//   - Home carousel slide (background gradient)
//   - Banner detail page (header gradient)
//   - Admin banner form (theme picker grid)
// ──────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

class BannerThemeData {
  final String key;       // stored in DB (e.g. 'indigo_night')
  final String label;     // shown in picker (e.g. 'Indigo Night')
  final String hint;      // picker subtitle (e.g. 'deep blue → indigo')
  final Color  start;     // gradient top-left
  final Color  end;       // gradient bottom-right

  const BannerThemeData({
    required this.key,
    required this.label,
    required this.hint,
    required this.start,
    required this.end,
  });

  LinearGradient get gradient => LinearGradient(
        colors: [start, end],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

class BannerThemes {
  /// Fallback key if a banner has no theme or unknown theme.
  static const String defaultKey = 'indigo_night';

  /// Master list — the curated palette.
  /// To add a new theme later: append one entry here. Zero backend work.
  static const List<BannerThemeData> all = [
    BannerThemeData(
      key:   'indigo_night',
      label: 'Indigo Night',
      hint:  'deep blue → indigo',
      start: Color(0xFF1E3A8A),
      end:   Color(0xFF4338CA),
    ),
    BannerThemeData(
      key:   'sunset',
      label: 'Sunset',
      hint:  'crimson → orange',
      start: Color(0xFFB91C1C),
      end:   Color(0xFFEA580C),
    ),
    BannerThemeData(
      key:   'emergency',
      label: 'Emergency',
      hint:  'deep red → urgent red',
      start: Color(0xFF991B1B),
      end:   Color(0xFFDC2626),
    ),
    BannerThemeData(
      key:   'sunrise',
      label: 'Sunrise',
      hint:  'soft yellow → peach',
      start: Color(0xFFFBBF24),
      end:   Color(0xFFFB923C),
    ),
    BannerThemeData(
      key:   'celebration',
      label: 'Celebration',
      hint:  'pink → gold',
      start: Color(0xFFDB2777),
      end:   Color(0xFFF59E0B),
    ),
    BannerThemeData(
      key:   'festival',
      label: 'Festival',
      hint:  'violet → magenta',
      start: Color(0xFF6D28D9),
      end:   Color(0xFFBE185D),
    ),
    BannerThemeData(
      key:   'paddy_field',
      label: 'Paddy Field',
      hint:  'teal → leaf green',
      start: Color(0xFF0F766E),
      end:   Color(0xFF15803D),
    ),
    BannerThemeData(
      key:   'monsoon',
      label: 'Monsoon',
      hint:  'deep blue → cyan',
      start: Color(0xFF0C4A6E),
      end:   Color(0xFF0E7490),
    ),
    BannerThemeData(
      key:   'rosewood',
      label: 'Rosewood',
      hint:  'maroon → rose',
      start: Color(0xFF831843),
      end:   Color(0xFF9D174D),
    ),
    BannerThemeData(
      key:   'slate',
      label: 'Slate',
      hint:  'charcoal → grey',
      start: Color(0xFF1F2937),
      end:   Color(0xFF374151),
    ),
    BannerThemeData(
      key:   'earthen',
      label: 'Earthen',
      hint:  'rust → ochre',
      start: Color(0xFF7C2D12),
      end:   Color(0xFFA16207),
    ),
  ];

  /// Look up theme by key. Falls back to defaultKey if null or unknown.
  static BannerThemeData byKey(String? key) {
    if (key == null) return all.first;
    return all.firstWhere(
      (t) => t.key == key,
      orElse: () => all.first,
    );
  }
}