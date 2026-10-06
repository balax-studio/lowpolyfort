import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../constants/art_assets.dart';
import '../constants/game_colors.dart';
import '../constants/game_config.dart';
import '../game/base_defense_game.dart';
import '../utils/isometric_helper.dart';

/// Renders the 2.5D military outpost battlefield ground, perimeter defenses,
/// hazard zone markings, and subtle ambient environmental motion (Clauses 732–735, 814–817).
///
/// ponytail: Pre-rendered low-poly ground texture with procedural ambient decor motion.
class ArenaBackgroundComponent extends PositionComponent with HasGameReference<BaseDefenseGame> {
  double _ambientTime = 0.0;

  // Ambient smoke puffs (Clause 734: 2–4s puff)
  final List<_SmokePuff> _smokePuffs = [];
  double _smokeSpawnTimer = 0.0;

  ArenaBackgroundComponent() : super(priority: -100);

  @override
  void update(double dt) {
    super.update(dt);
    _ambientTime += dt;

    // Base Low HP increases smoke emission slightly (Clause 777, 820)
    final isLowHp = game.gameManager.baseHp < (game.gameManager.maxBaseHp * 0.3);
    final spawnInterval = isLowHp ? 1.8 : 3.0;

    _smokeSpawnTimer += dt;
    if (_smokeSpawnTimer >= spawnInterval) {
      _smokeSpawnTimer = 0.0;
      if (_smokePuffs.length < 5) {
        _smokePuffs.add(
          _SmokePuff(
            startX: 52.0 + (Random().nextDouble() * 6 - 3),
            startY: 195.0,
          ),
        );
      }
    }

    // Update smoke puffs
    for (int i = _smokePuffs.length - 1; i >= 0; i--) {
      _smokePuffs[i].update(dt);
      if (_smokePuffs[i].isExpired) {
        _smokePuffs.removeAt(i);
      }
    }
  }

  void _drawProp(Canvas canvas, String assetPath, Offset center, double w, double h) {
    final img = ArtAssetManager.getImage(assetPath);
    if (img != null) {
      final src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
      final dst = Rect.fromCenter(center: center, width: w, height: h);
      canvas.drawImageRect(img, src, dst, Paint()..filterQuality = FilterQuality.medium);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final width = GameConfig.virtualWidth;
    final height = GameConfig.virtualHeight;

    // Clause 735: Parallax impulse based on camera shake
    final camOffset = game.cameraManager.currentOffset;
    final bgOffsetX = camOffset.x * 0.3;
    final bgOffsetY = camOffset.y * 0.3;

    canvas.save();
    canvas.translate(bgOffsetX, bgOffsetY);

    // Pre-rendered low-poly ground texture (Clause 909, 914)
    final groundImg = ArtAssetManager.getImage(WorldArtAssets.arenaGround);
    if (groundImg != null) {
      final src = Rect.fromLTWH(0, 0, groundImg.width.toDouble(), groundImg.height.toDouble());
      final dst = Rect.fromLTWH(0, 0, width, height);
      canvas.drawImageRect(groundImg, src, dst, Paint()..filterQuality = FilterQuality.medium);
    } else {
      // Ground base fill fallback
      final groundPaint = Paint()..color = GameColors.groundBase;
      canvas.drawRect(Rect.fromLTWH(0, 0, width, height), groundPaint);
    }



    // Pre-rendered side props (Clause 916: sandbags, crates, barrels, radar, lamp, grass)
    _drawProp(canvas, WorldArtAssets.sandbags, const Offset(36, 180), 46, 26);
    _drawProp(canvas, WorldArtAssets.sandbags, Offset(width - 36, 180), 46, 26);
    _drawProp(canvas, WorldArtAssets.crate, const Offset(34, 290), 34, 34);
    _drawProp(canvas, WorldArtAssets.barrel, Offset(width - 34, 290), 30, 36);
    _drawProp(canvas, WorldArtAssets.radar, const Offset(38, 440), 38, 42);
    _drawProp(canvas, WorldArtAssets.lamp, Offset(width - 38, 440), 26, 44);
    _drawProp(canvas, WorldArtAssets.grass, const Offset(28, 235), 24, 24);
    _drawProp(canvas, WorldArtAssets.grass, Offset(width - 28, 235), 24, 24);

    // Metal hedgehogs / tank traps
    _drawMetalHedgehog(canvas, const Offset(28, 260));
    _drawMetalHedgehog(canvas, Offset(width - 28, 260));

    // Ambient Props: Outpost Flag, Cooling Fan, Warning Beacon (Clauses 733–734)
    _drawOutpostFlag(canvas, const Offset(38, 160));
    _drawCoolingFan(canvas, Offset(width - 34, 190));
    _drawWarningBeacon(canvas, Offset(width - 34, 320));
    _drawGrassPatches(canvas);

    // Rising Smoke Puffs (Clause 734)
    _drawSmokePuffs(canvas);

    // Base Zone Hazard Stripes (Clause 815, 817: Yellow/Black hazard border)
    _drawBasePerimeterMarking(canvas, width);

    canvas.restore();
  }


  void _drawBasePerimeterMarking(Canvas canvas, double width) {
    final defenseLinePaint = Paint()
      ..color = GameColors.acidYellow.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    for (double x = 15; x < width - 15; x += 24) {
      canvas.drawLine(Offset(x, 480), Offset(x + 12, 480), defenseLinePaint);
    }
  }

  void _drawOutpostFlag(Canvas canvas, Offset pos) {
    // Flag pole
    final polePaint = Paint()
      ..color = GameColors.baseMetal
      ..strokeWidth = 2.5;
    canvas.drawLine(pos, Offset(pos.dx, pos.dy - 32), polePaint);

    // Swaying cloth flag (Clause 734: continuous slow sway)
    final sway = sin(_ambientTime * 2.2) * 4.0;
    final flagPath = Path()
      ..moveTo(pos.dx, pos.dy - 32)
      ..lineTo(pos.dx + 16, pos.dy - 26 + sway)
      ..lineTo(pos.dx, pos.dy - 20)
      ..close();

    final flagPaint = Paint()..color = GameColors.techBlue;
    canvas.drawPath(flagPath, flagPaint);

    final flagBorder = Paint()
      ..color = GameColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(flagPath, flagBorder);
  }

  void _drawCoolingFan(Canvas canvas, Offset pos) {
    IsometricHelper.drawDropShadow(
      canvas: canvas,
      center: Offset(pos.dx, pos.dy + 8),
      radiusX: 14,
      radiusY: 7,
    );

    // Circular vent housing
    final housingPaint = Paint()..color = GameColors.sandbagShadow;
    canvas.drawCircle(pos, 10, housingPaint);
    canvas.drawCircle(
      pos,
      10,
      Paint()
        ..color = GameColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    // Rotating fan blades (Clause 734: continuous slow rotation)
    final angle = _ambientTime * 2.0;
    final bladePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 2.2;

    for (int i = 0; i < 4; i++) {
      final a = angle + (i * pi / 2);
      canvas.drawLine(pos, Offset(pos.dx + cos(a) * 7, pos.dy + sin(a) * 7), bladePaint);
    }
  }

  void _drawWarningBeacon(Canvas canvas, Offset pos) {
    // Beacon post
    canvas.drawLine(
      pos,
      Offset(pos.dx, pos.dy - 12),
      Paint()
        ..color = GameColors.sandbagShadow
        ..strokeWidth = 3.0,
    );

    // Gentle pulse (Clause 734: 2–3s gentle pulse)
    final pulse = (sin(_ambientTime * 2.5) + 1.0) / 2.0;
    final beaconColor = Color.lerp(
      const Color(0xFFFFA000).withValues(alpha: 0.4),
      const Color(0xFFFFD54F).withValues(alpha: 0.95),
      pulse,
    )!;

    canvas.drawCircle(Offset(pos.dx, pos.dy - 14), 4.0, Paint()..color = beaconColor);
    canvas.drawCircle(
      Offset(pos.dx, pos.dy - 14),
      4.0 + pulse * 2.5,
      Paint()
        ..color = beaconColor.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawGrassPatches(Canvas canvas) {
    // Subtle low-amplitude grass tuft sway (Clause 734)
    final sway = sin(_ambientTime * 1.5) * 1.5;
    final grassPaint = Paint()
      ..color = const Color(0xFF4E6B4B).withValues(alpha: 0.6)
      ..strokeWidth = 1.6;

    final patches = [
      const Offset(80, 220),
      const Offset(280, 150),
      const Offset(70, 390),
      const Offset(310, 420),
    ];

    for (final p in patches) {
      canvas.drawLine(p, Offset(p.dx - 2 + sway, p.dy - 6), grassPaint);
      canvas.drawLine(p, Offset(p.dx + sway, p.dy - 7), grassPaint);
      canvas.drawLine(p, Offset(p.dx + 3 + sway, p.dy - 5), grassPaint);
    }
  }

  void _drawSmokePuffs(Canvas canvas) {
    for (final puff in _smokePuffs) {
      final p = (puff.elapsed / puff.lifetime).clamp(0.0, 1.0);
      final opacity = (1.0 - p) * 0.45;
      final currentRadius = puff.initialRadius + (p * 8.0);
      final currentY = puff.startY - (p * 28.0);
      final currentX = puff.startX + (sin(p * 4.0) * 3.0);

      canvas.drawCircle(
        Offset(currentX, currentY),
        currentRadius,
        Paint()..color = Colors.white.withValues(alpha: opacity),
      );
    }
  }


  void _drawMetalHedgehog(Canvas canvas, Offset pos) {
    IsometricHelper.drawDropShadow(
      canvas: canvas,
      center: Offset(pos.dx, pos.dy + 6),
      radiusX: 16,
      radiusY: 8,
    );

    final metalPaint = Paint()
      ..color = GameColors.metalBarrier
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.square;

    canvas.drawLine(Offset(pos.dx - 12, pos.dy - 10), Offset(pos.dx + 12, pos.dy + 10), metalPaint);
    canvas.drawLine(Offset(pos.dx + 12, pos.dy - 10), Offset(pos.dx - 12, pos.dy + 10), metalPaint);
    canvas.drawLine(Offset(pos.dx, pos.dy - 14), Offset(pos.dx, pos.dy + 14), metalPaint);
  }
}

class _SmokePuff {
  final double startX;
  final double startY;
  final double lifetime = 2.4;
  final double initialRadius = 3.5;
  double elapsed = 0.0;

  _SmokePuff({required this.startX, required this.startY});

  bool get isExpired => elapsed >= lifetime;

  void update(double dt) {
    elapsed += dt;
  }
}

