import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../constants/art_assets.dart';
import '../constants/game_colors.dart';
import '../constants/game_config.dart';
import '../utils/isometric_helper.dart';
import 'hero_component.dart';

enum SlotHighlightState {
  none,
  validDrop,
  validMerge,
  invalidDrop,
}

/// A tactical defense slot on the 3x3 battlefield grid capable of hosting a unit.
class DefenseSlotComponent extends PositionComponent {
  final int slotIndex;
  final int gridRow;
  final int gridCol;

  HeroComponent? currentHero;
  SlotHighlightState highlightState = SlotHighlightState.none;
  double _pulseTimer = 0.0;

  DefenseSlotComponent({
    required this.slotIndex,
    required this.gridRow,
    required this.gridCol,
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2(GameConfig.slotWidth, GameConfig.slotHeight),
          anchor: Anchor.center,
          priority: 10,
        );

  bool get isEmpty => currentHero == null;

  /// Row perspective scale: rear 0.92, middle 1.00, front 1.08 (Clause 904).
  static double getPerspectiveScale(int row) {
    switch (row) {
      case 0:
        return 0.92;
      case 1:
        return 1.00;
      case 2:
        return 1.08;
      default:
        return 1.00;
    }
  }

  double get perspectiveScale => getPerspectiveScale(gridRow);

  double _spawnRingTimer = 0.0;

  void triggerSpawnRing() {
    _spawnRingTimer = 0.25;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_spawnRingTimer > 0) {
      _spawnRingTimer -= dt;
    }
    if (highlightState == SlotHighlightState.validMerge) {
      _pulseTimer += dt * 6.0;
    } else {
      _pulseTimer = 0.0;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final w = size.x;
    final h = size.y;
    final padRect = Rect.fromCenter(center: Offset.zero, width: w, height: h);
    final padRRect = RRect.fromRectAndRadius(padRect, const Radius.circular(8));

    final padImg = ArtAssetManager.getImage(WorldArtAssets.defensePad);
    if (padImg != null) {
      canvas.save();
      canvas.scale(perspectiveScale);

      // Contact shadow below pad
      IsometricHelper.drawDropShadow(
        canvas: canvas,
        center: Offset(0, h * 0.12),
        radiusX: w * 0.50,
        radiusY: h * 0.40,
        opacity: 0.25,
      );

      final src = Rect.fromLTWH(0, 0, padImg.width.toDouble(), padImg.height.toDouble());
      final dst = Rect.fromCenter(center: Offset.zero, width: w * 1.25, height: h * 1.25);
      final padPaint = Paint()
        ..filterQuality = FilterQuality.medium
        ..color = (!isEmpty) ? Colors.white.withValues(alpha: 0.85) : Colors.white;
      canvas.drawImageRect(padImg, src, dst, padPaint);
      canvas.restore();
    } else {
      // Drop shadow fallback
      IsometricHelper.drawDropShadow(
        canvas: canvas,
        center: Offset(0, h * 0.1),
        radiusX: w * 0.48,
        radiusY: h * 0.42,
        opacity: 0.22,
      );

      // Base fill
      final bgPaint = Paint()..color = const Color(0xFF6B7267);
      canvas.drawRRect(padRRect, bgPaint);

      // Top face highlight
      final topHighlight = Path()
        ..moveTo(-w * 0.45, -h * 0.45)
        ..lineTo(w * 0.45, -h * 0.45)
        ..lineTo(w * 0.4, -h * 0.2)
        ..lineTo(-w * 0.4, -h * 0.2)
        ..close();
      canvas.drawPath(topHighlight, Paint()..color = Colors.white.withValues(alpha: 0.15));

      // Standard border
      final borderPaint = Paint()
        ..color = GameColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawRRect(padRRect, borderPaint);

      // Tactical corner crosshairs
      _drawCornerCrosshairs(canvas, w, h);
    }

    // Unit purchase spawn ground ring (Clause 755: friendly cyan ring 200–300ms)
    if (_spawnRingTimer > 0) {
      final p = (1.0 - (_spawnRingTimer / 0.25)).clamp(0.0, 1.0);
      final ringRadius = (w * 0.35) + (p * w * 0.35);
      final ringOpacity = (1.0 - p).clamp(0.0, 1.0);
      final ringPaint = Paint()
        ..color = GameColors.techBlue.withValues(alpha: ringOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5 * (1.0 - p * 0.5);
      canvas.drawCircle(Offset.zero, ringRadius, ringPaint);
    }

    // Highlight state rendering
    if (highlightState != SlotHighlightState.none) {
      _renderHighlightOverlay(canvas, padRRect, w, h);
    }
  }

  void _drawCornerCrosshairs(Canvas canvas, double w, double h) {
    final markPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 2.0;

    const len = 8.0;
    final hw = w * 0.42;
    final hh = h * 0.42;

    // Top-left
    canvas.drawLine(Offset(-hw, -hh), Offset(-hw + len, -hh), markPaint);
    canvas.drawLine(Offset(-hw, -hh), Offset(-hw, -hh + len), markPaint);

    // Top-right
    canvas.drawLine(Offset(hw, -hh), Offset(hw - len, -hh), markPaint);
    canvas.drawLine(Offset(hw, -hh), Offset(hw, -hh + len), markPaint);

    // Bottom-left
    canvas.drawLine(Offset(-hw, hh), Offset(-hw + len, hh), markPaint);
    canvas.drawLine(Offset(-hw, hh), Offset(-hw, hh - len), markPaint);

    // Bottom-right
    canvas.drawLine(Offset(hw, hh), Offset(hw - len, hh), markPaint);
    canvas.drawLine(Offset(hw, hh), Offset(hw, hh - len), markPaint);
  }

  void _renderHighlightOverlay(Canvas canvas, RRect padRRect, double w, double h) {
    Color highlightColor;
    double strokeWidth = 3.5;

    switch (highlightState) {
      case SlotHighlightState.validDrop:
        highlightColor = GameColors.electricLime;
        break;
      case SlotHighlightState.validMerge:
        highlightColor = GameColors.acidYellow;
        // Pulse width between 4.0 and 6.5
        strokeWidth = 4.5 + (_pulseTimer.sin().abs() * 2.0);
        break;
      case SlotHighlightState.invalidDrop:
        highlightColor = GameColors.punchRed;
        break;
      case SlotHighlightState.none:
        return;
    }

    final glowPaint = Paint()
      ..color = highlightColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawRRect(padRRect, glowPaint);

    // Render "MERGE!" badge and subtle orbit particles when active (Clause 759)
    if (highlightState == SlotHighlightState.validMerge) {
      _renderMergeBadge(canvas, h);
      _renderMergeOrbits(canvas, w, h);
    }
  }

  void _renderMergeOrbits(Canvas canvas, double w, double h) {
    const orbitCount = 4;
    final orbitPaint = Paint()..color = GameColors.acidYellow.withValues(alpha: 0.8);
    for (int i = 0; i < orbitCount; i++) {
      final angle = (_pulseTimer * 1.5) + (i * 3.14159 / (orbitCount / 2));
      final ox = (w * 0.48) * (angle % 6.28 > 3.14 ? 1 : -1) * 0.7;
      final oy = (h * 0.42) * (angle % 6.28 > 3.14 ? -1 : 1) * 0.7;
      canvas.drawCircle(Offset(ox, oy), 2.2, orbitPaint);
    }
  }

  void _renderMergeBadge(Canvas canvas, double h) {
    const badgeW = 60.0;
    const badgeH = 18.0;
    final badgeRect = Rect.fromCenter(center: Offset(0, -h * 0.65), width: badgeW, height: badgeH);
    final badgeRRect = RRect.fromRectAndRadius(badgeRect, const Radius.circular(4));

    // Yellow fill
    canvas.drawRRect(badgeRRect, Paint()..color = GameColors.acidYellow);
    // Black border
    canvas.drawRRect(
      badgeRRect,
      Paint()
        ..color = GameColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    final textSpan = TextSpan(
      text: 'MERGE!',
      style: const TextStyle(
        color: GameColors.ink,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -h * 0.65 - textPainter.height / 2),
    );
  }
}

extension on double {
  double sin() => (this % 6.28318) - 3.14159; // lightweight approx for visual pulse
}
