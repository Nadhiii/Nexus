import 'package:flutter/material.dart';
import 'package:animations/animations.dart';

class AppAnimations {
  // ═══════════════════════════════════════════════════════════════════════════
  // DURATIONS - Synced for consistent reaction time
  // ═══════════════════════════════════════════════════════════════════════════
  static const Duration extraFast = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 200);
  static const Duration standardMedium = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 300);
  static const Duration slower = Duration(milliseconds: 350);
  static const Duration slowest = Duration(milliseconds: 400);
  static const Duration verySlow = Duration(milliseconds: 500);
  static const Duration ultra = Duration(milliseconds: 600);
  static const Duration veryLong = Duration(milliseconds: 1500);

  static const Duration navDuration = Duration(milliseconds: 300);
  static const Duration fabCrossFadeDuration = Duration(milliseconds: 200);
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
  static const Duration modalDuration = Duration(milliseconds: 400);

  // ═══════════════════════════════════════════════════════════════════════════
  // CURVES - The "Nexus" DNA
  // ═══════════════════════════════════════════════════════════════════════════
  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve emphasizedCurve = Curves.easeInOutCubic;
  static const Curve fadeInCurve = Curves.easeIn;
  static const Curve fadeOutCurve = Curves.easeOut;
  static const Curve sizeCurve = Curves.easeInOut;
  static const Curve bouncyCurve = Curves.elasticOut;
  static const Curve backdropCurve = Curves.easeInOutBack;
  static const Curve smoothCurve = Curves.easeInOut;
  static const Curve staggeredCurve = Interval(0.0, 0.8, curve: Curves.easeOut);

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE TRANSITIONS
  // ═══════════════════════════════════════════════════════════════════════════
  static PageTransitionsTheme get pageTransitionsTheme =>
      const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _FadeThroughPageTransitionsBuilder(),
          TargetPlatform.iOS: _FadeThroughPageTransitionsBuilder(),
        },
      );
}

class _FadeThroughPageTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeThroughPageTransitionsBuilder();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeThroughTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      fillColor: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }
}
