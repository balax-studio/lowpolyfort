import 'dart:math';
import 'package:flutter/material.dart';

/// Utilities for 2.5D pseudo-isometric projection, faceted polygon drawing,
/// and directional light calculation.
class IsometricHelper {
  IsometricHelper._();

  // Top-down 35-45 degree perspective compression factor for Y-axis
  static const double perspectiveCompression = 0.72;

  // Key light direction vector (from top-left, elevated)
  static final Offset lightDirection = () {
    const angleRad = -pi / 4; // -45 degrees
    return Offset(cos(angleRad), sin(angleRad));
  }();

  /// Adjusts a base color based on polygon face orientation to simulate low-poly lighting.
  /// [faceType]: 0 = Top, 1 = Right, 2 = Left, 3 = Front/Bottom
  static Color shadeFace(Color base, int faceType) {
    final hsl = HSLColor.fromColor(base);
    double lightnessDelta;

    switch (faceType) {
      case 0: // Top face: fully illuminated
        lightnessDelta = 0.16;
        break;
      case 1: // Right face: medium tone
        lightnessDelta = 0.0;
        break;
      case 2: // Left face: facing light source
        lightnessDelta = 0.08;
        break;
      case 3: // Bottom/back face: cast in shadow
      default:
        lightnessDelta = -0.18;
        break;
    }

    final newLightness = (hsl.lightness + lightnessDelta).clamp(0.05, 0.95);
    return hsl.withLightness(newLightness).toColor();
  }

  /// Draws a soft directional ground shadow ellipse under an entity.
  static void drawDropShadow({
    required Canvas canvas,
    required Offset center,
    required double radiusX,
    required double radiusY,
    double opacity = 0.28,
  }) {
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(center: center, width: radiusX * 2, height: radiusY * 2),
      shadowPaint,
    );
  }

  /// Draws a low-poly faceted prism or block with top, left, and right illuminated facets.
  static void drawLowPolyBlock({
    required Canvas canvas,
    required Rect rect,
    required double height3d,
    required Color color,
  }) {
    final topColor = shadeFace(color, 0);
    final leftColor = shadeFace(color, 2);
    final rightColor = shadeFace(color, 3);

    // Front/Side polygons
    final pLeft = Path()
      ..moveTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top)
      ..lineTo(rect.left, rect.top - height3d)
      ..lineTo(rect.left, rect.bottom - height3d)
      ..close();
    canvas.drawPath(pLeft, Paint()..color = leftColor);

    final pFront = Path()
      ..moveTo(rect.left, rect.bottom)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.right, rect.bottom - height3d)
      ..lineTo(rect.left, rect.bottom - height3d)
      ..close();
    canvas.drawPath(pFront, Paint()..color = rightColor);

    // Top face
    final pTop = Path()
      ..moveTo(rect.left, rect.top - height3d)
      ..lineTo(rect.right, rect.top - height3d)
      ..lineTo(rect.right, rect.bottom - height3d)
      ..lineTo(rect.left, rect.bottom - height3d)
      ..close();
    canvas.drawPath(pTop, Paint()..color = topColor);
  }
}
