import 'package:flutter/material.dart';

/// Nexus Design System - Spacing & Sizing
/// Consistent spacing and sizing system based on 4px grid
class AppSpacing {
  // Base unit: 4px
  static const double unit = 4.0;
  
  // Spacing Scale
  static const double xs = 4.0;    // 1 unit
  static const double sm = 8.0;    // 2 units
  static const double md = 12.0;   // 3 units
  static const double lg = 16.0;   // 4 units
  static const double xl = 20.0;   // 5 units
  static const double xl2 = 24.0;  // 6 units
  static const double xl3 = 28.0;  // 7 units
  static const double xl4 = 32.0;  // 8 units
  static const double xl5 = 40.0;  // 10 units
  static const double xl6 = 48.0;  // 12 units
  static const double xl7 = 56.0;  // 14 units
  static const double xl8 = 64.0;  // 16 units
  
  // Border Radius
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusXl2 = 24.0;
  static const double radiusXl3 = 28.0;
  static const double radiusFull = 9999.0;
  
  // Icon Sizes
  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 40.0;
  static const double iconXl2 = 48.0;
  
  // Button Heights
  static const double buttonHeightSm = 36.0;
  static const double buttonHeightMd = 44.0;
  static const double buttonHeightLg = 52.0;
  static const double buttonHeightXl = 60.0;
  
  // Card Padding
  static const EdgeInsets cardPaddingSm = EdgeInsets.all(12.0);
  static const EdgeInsets cardPaddingMd = EdgeInsets.all(16.0);
  static const EdgeInsets cardPaddingLg = EdgeInsets.all(20.0);
  static const EdgeInsets cardPaddingXl = EdgeInsets.all(24.0);
  
  // Screen Padding
  static const EdgeInsets screenPaddingH = EdgeInsets.symmetric(horizontal: 20.0);
  static const EdgeInsets screenPaddingV = EdgeInsets.symmetric(vertical: 20.0);
  static const EdgeInsets screenPaddingAll = EdgeInsets.all(20.0);
  
  // List Item Heights
  static const double listItemHeightSm = 56.0;
  static const double listItemHeightMd = 72.0;
  static const double listItemHeightLg = 88.0;
}

/// Nexus Design System - Shadows & Effects
class AppShadows {
  // Card Shadows (subtle, layered)
  static List<BoxShadow> get cardShadowSm => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get cardShadowMd => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> get cardShadowLg => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 32,
      offset: const Offset(0, 16),
    ),
  ];
  
  // Colored Shadows (for accent elements)
  static BoxShadow coloredShadow(Color color, {double opacity = 0.3}) {
    return BoxShadow(
      color: color.withOpacity(opacity),
      blurRadius: 16,
      offset: const Offset(0, 8),
    );
  }
  
  // Inner Shadow Effect (for depth)
  static List<BoxShadow> get innerShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: -4,
    ),
  ];
  
  // Glow Effect
  static BoxShadow glow(Color color, {double blur = 20, double opacity = 0.5}) {
    return BoxShadow(
      color: color.withOpacity(opacity),
      blurRadius: blur,
      spreadRadius: 0,
    );
  }
}

/// Nexus Design System - Animations & Durations
class AppAnimations {
  // Duration
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration verySlow = Duration(milliseconds: 600);
  
  // Curves
  static const Curve defaultCurve = Curves.easeInOutCubic;
  static const Curve bounceCurve = Curves.easeOutBack;
  static const Curve smoothCurve = Curves.easeOut;
  
  // Common Animations
  static Curve get spring => Curves.elasticOut;
  static Curve get ease => Curves.easeInOut;
}
