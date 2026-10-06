import 'dart:math';
import 'package:flutter/material.dart';

/// Mathematics and easing helpers for clean animations and combat calculations.
class MathUtils {
  MathUtils._();

  /// Cubic Ease-Out curve for smooth snap-back transitions.
  static double easeOutCubic(double t) {
    t = t.clamp(0.0, 1.0);
    return 1.0 - pow(1.0 - t, 3.0).toDouble();
  }

  /// Overshoot elastic bounce curve for Level Up scale bursts.
  static double easeOutBack(double t, [double s = 1.70158]) {
    t = t.clamp(0.0, 1.0) - 1.0;
    return (t * t * ((s + 1.0) * t + s) + 1.0);
  }

  /// Standard Euclidean distance between two offsets.
  static double distance(Offset a, Offset b) {
    final dx = a.dx - b.dx;
    final dy = a.dy - b.dy;
    return sqrt(dx * dx + dy * dy);
  }

  /// Linear interpolation between two offsets.
  static Offset lerpOffset(Offset a, Offset b, double t) {
    return Offset(
      a.dx + (b.dx - a.dx) * t,
      a.dy + (b.dy - a.dy) * t,
    );
  }

  /// Angle in radians from source to target.
  static double angleBetween(Offset from, Offset to) {
    return atan2(to.dy - from.dy, to.dx - from.dx);
  }
}
