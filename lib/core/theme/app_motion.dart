import 'package:flutter/animation.dart';

/// Single source of truth for animation timing. Every `.animate(...)` call
/// and implicit-animation widget in the app should reference these instead
/// of picking an arbitrary duration, so transitions feel like one system.
class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  /// Entrances: cards, sheets, page content appearing.
  static const Curve enter = Curves.easeOutCubic;

  /// Exits: dismissals, fade-outs.
  static const Curve exit = Curves.easeIn;

  /// Micro-interactions: button press, toggle, selection feedback.
  static const Curve tap = Curves.easeOut;
}
