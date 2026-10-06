import 'package:flutter/material.dart';
import '../constants/game_colors.dart';

/// Pre-allocated reusable Paints and geometric paths for 2.5D low-poly rendering.
/// Avoids per-frame allocations to maintain a rock-solid 60 FPS.
class AssetManager {
  AssetManager._();
  static final AssetManager instance = AssetManager._();

  // Cached Paints
  final Paint fillPaint = Paint()..style = PaintingStyle.fill;
  final Paint strokePaint = Paint()..style = PaintingStyle.stroke;
  final Paint shadowPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = GameColors.unitDropShadow;

  // Neo-brutalist border paint
  final Paint borderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.5
    ..color = GameColors.ink;

  // Flash & effect paints
  final Paint flashPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.white.withValues(alpha: 0.85);

  final Paint muzzlePaint = Paint()
    ..style = PaintingStyle.fill
    ..color = GameColors.muzzleFlash;

  final Paint bulletPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = GameColors.bulletTracer;
}
