import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../constants/art_assets.dart';
import '../constants/game_colors.dart';
import '../constants/game_config.dart';
import '../utils/isometric_helper.dart';
import '../game/base_defense_game.dart';
import 'vfx_component.dart';

/// The fortified command bunker at the bottom of the arena defending against horde breaches.
/// Features ambient radar rotation, beacon pulse, localized damage shake, and low-HP indicators (Clauses 775–778).
///
/// ponytail: Procedural bunker animations with pre-rendered low-poly sprite asset support.
class BaseComponent extends PositionComponent with HasGameReference<BaseDefenseGame> {
  double _damageFlashTimer = 0.0;
  double _localShakeTimer = 0.0;
  double _ambientTimer = 0.0;
  bool _lightsOff = false;

  BaseComponent()
      : super(
          position: Vector2(GameConfig.virtualWidth / 2, 748),
          size: Vector2(GameConfig.baseWidth, GameConfig.baseHeight),
          anchor: Anchor.center,
          priority: 5, // Behind pads (priority 10) and heroes (priority 20) per Clause 1068
        );

  void triggerDamageFlash() {
    _damageFlashTimer = 0.12; // Brief red flash (Clause 776)
    _localShakeTimer = 0.12; // Localized shake (Clause 776)

    // Tiny local dust puff at base edge
    game.add(
      ImpactFlashVFXComponent(
        position: Vector2(position.x + (Random().nextDouble() * 80 - 40), position.y - 20),
        color: const Color(0xFF8D8D8D),
      ),
    );
  }

  void triggerDestructionSequence() {
    _lightsOff = true;
    _damageFlashTimer = 0.30;
    _localShakeTimer = 0.35;

    // Dust burst & debris (Clause 778)
    for (int i = 0; i < 3; i++) {
      game.add(
        DeathPuffVFXComponent(
          position: Vector2(position.x + (i - 1) * 50, position.y - 15),
          color: const Color(0xFF6B7267),
          isLarge: true,
        ),
      );
    }
  }

  void reset() {
    _lightsOff = false;
    _damageFlashTimer = 0.0;
    _localShakeTimer = 0.0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _ambientTimer += dt;

    if (_damageFlashTimer > 0) {
      _damageFlashTimer -= dt;
    }
    if (_localShakeTimer > 0) {
      _localShakeTimer -= dt;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final w = size.x;
    final h = size.y;

    final isLowHp = game.gameManager.baseHp < (game.gameManager.maxBaseHp * 0.3);

    // Drop shadow
    IsometricHelper.drawDropShadow(
      canvas: canvas,
      center: Offset(0, h * 0.4),
      radiusX: w * 0.52,
      radiusY: 26,
      opacity: 0.35,
    );

    canvas.save();

    // Localized base damage shake (Clause 776)
    if (_localShakeTimer > 0) {
      final shakeX = (sin(_localShakeTimer * 60) * 2.5);
      final shakeY = (cos(_localShakeTimer * 60) * 1.5);
      canvas.translate(shakeX, shakeY);
    }

    final baseImg = ArtAssetManager.getImage(WorldArtAssets.mainBase);
    if (baseImg != null) {
      final src = Rect.fromLTWH(0, 0, baseImg.width.toDouble(), baseImg.height.toDouble());
      // Calibrated to 384px width (fits within 450px canvas without clipping) and 125px height (behind Row 2 slots)
      final dst = Rect.fromCenter(center: Offset.zero, width: 384.0, height: 125.0);
      final paint = Paint()
        ..filterQuality = FilterQuality.medium
        ..color = (_damageFlashTimer > 0)
            ? GameColors.punchRed.withValues(alpha: 0.85)
            : (_lightsOff ? Colors.white.withValues(alpha: 0.45) : Colors.white);
      canvas.drawImageRect(baseImg, src, dst, paint);

      // Warning light on cupola
      final lightImg = ArtAssetManager.getImage(WorldArtAssets.warningLight);
      if (lightImg != null && !_lightsOff) {
        final pulseFreq = isLowHp ? 10.0 : 4.0;
        final alpha = 0.35 + (sin(_ambientTimer * pulseFreq).abs() * 0.65);
        final lightPaint = Paint()..color = Colors.white.withValues(alpha: alpha);
        final lDst = Rect.fromCenter(center: const Offset(0, -52), width: 24, height: 24);
        canvas.drawImageRect(lightImg, Rect.fromLTWH(0, 0, lightImg.width.toDouble(), lightImg.height.toDouble()), lDst, lightPaint);
      }
    } else {
      // Bunker main hull (low-poly beveled bunker)
      final bunkerRect = Rect.fromCenter(center: Offset.zero, width: w, height: h);
      final bunkerRRect = RRect.fromRectAndRadius(bunkerRect, const Radius.circular(8));

      // Base concrete color (flash red when hit)
      final hullPaint = Paint()
        ..color = (_damageFlashTimer > 0) ? GameColors.punchRed : GameColors.baseConcrete;
      canvas.drawRRect(bunkerRRect, hullPaint);

      // Top face highlight
      final topFacet = Path()
        ..moveTo(-w * 0.48, -h * 0.48)
        ..lineTo(w * 0.48, -h * 0.48)
        ..lineTo(w * 0.44, -h * 0.15)
        ..lineTo(-w * 0.44, -h * 0.15)
        ..close();
      canvas.drawPath(topFacet, Paint()..color = Colors.white.withValues(alpha: 0.14));

      // Black Neo-Brutalist structural border
      final borderPaint = Paint()
        ..color = GameColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5;
      canvas.drawRRect(bunkerRRect, borderPaint);

      // Hazard warning stripes along the front face
      _drawHazardStripes(canvas, Rect.fromLTWH(-w * 0.45, -h * 0.1, w * 0.9, 14));

      // Central command antenna & rotating radar dish (Clauses 775, 777)
      _drawRadarDish(canvas, Offset(0, -h * 0.48), isLowHp);

      // Heavy reinforced blast doors and gun embrasures
      _drawEmbrasure(canvas, Offset(-w * 0.3, h * 0.15));
      _drawEmbrasure(canvas, Offset(w * 0.3, h * 0.15));
      _drawBlastDoor(canvas, Offset(0, h * 0.15));
    }

    canvas.restore();
  }

  void _drawHazardStripes(Canvas canvas, Rect rect) {
    canvas.save();
    canvas.clipRect(rect);

    final bgPaint = Paint()..color = GameColors.acidYellow;
    canvas.drawRect(rect, bgPaint);

    final stripePaint = Paint()
      ..color = GameColors.ink
      ..strokeWidth = 10.0;

    for (double x = rect.left - 40; x < rect.right + 40; x += 22) {
      canvas.drawLine(Offset(x, rect.bottom + 5), Offset(x + 18, rect.top - 5), stripePaint);
    }
    canvas.restore();

    // Outline
    canvas.drawRect(
      rect,
      Paint()
        ..color = GameColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  void _drawRadarDish(Canvas canvas, Offset pos, bool isLowHp) {
    final mountPaint = Paint()
      ..color = GameColors.baseMetal
      ..strokeWidth = 4.0;
    canvas.drawLine(pos, Offset(pos.dx, pos.dy - 16), mountPaint);

    // Rotating radar dish angle
    final dishAngle = sin(_ambientTimer * 1.8) * 0.4;
    canvas.save();
    canvas.translate(pos.dx, pos.dy - 18);
    canvas.rotate(dishAngle);

    final dishPaint = Paint()..color = GameColors.techBlue;
    canvas.drawArc(
      Rect.fromCenter(center: Offset.zero, width: 22, height: 16),
      3.14,
      3.14,
      true,
      dishPaint,
    );
    canvas.restore();

    // Indicator blinker (Clause 777: speeds up on Low HP < 30%)
    if (!_lightsOff) {
      final pulseSpeed = isLowHp ? 8.0 : 3.0;
      final pulse = (sin(_ambientTimer * pulseSpeed) + 1.0) / 2.0;
      final lightColor = isLowHp ? const Color(0xFFFF5252) : GameColors.electricLime;

      final lightPaint = Paint()..color = lightColor.withValues(alpha: 0.4 + pulse * 0.6);
      canvas.drawCircle(Offset(pos.dx, pos.dy - 22), 3.0 + (pulse * 1.5), lightPaint);
    }
  }

  void _drawEmbrasure(Canvas canvas, Offset pos) {
    final rect = Rect.fromCenter(center: pos, width: 36, height: 16);
    canvas.drawRect(rect, Paint()..color = GameColors.ink);
    canvas.drawRect(
      rect,
      Paint()
        ..color = GameColors.baseMetal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  void _drawBlastDoor(Canvas canvas, Offset pos) {
    final rect = Rect.fromCenter(center: pos, width: 44, height: 26);
    canvas.drawRect(rect, Paint()..color = GameColors.baseMetal);
    canvas.drawRect(
      rect,
      Paint()
        ..color = GameColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );
  }
}
