import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import '../../constants/art_assets.dart';
import '../../constants/game_colors.dart';
import '../../models/hero_data.dart';
import '../../systems/save_system.dart';
import '../../systems/goal_presentation_service.dart';
import '../common/brutalist_card.dart';
import '../common/brutalist_button.dart';
import '../common/brutalist_badge.dart';

/// Neo-Brutalist Main Menu with animated 2.5D low-poly outpost preview (Clauses 53, 54, 114).
class MainMenuView extends StatefulWidget {
  final VoidCallback onStartGame;
  final VoidCallback onOpenUpgrades;
  final VoidCallback onOpenArmory;
  final VoidCallback onOpenSettings;

  const MainMenuView({
    super.key,
    required this.onStartGame,
    required this.onOpenUpgrades,
    required this.onOpenArmory,
    required this.onOpenSettings,
  });

  @override
  State<MainMenuView> createState() => _MainMenuViewState();
}

class _MainMenuViewState extends State<MainMenuView> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final save = SaveSystem.currentSave;

    return Column(
      children: [
        // Upper 55-58%: Low-Poly Animated Outpost Preview (Clause 53)
        Expanded(
          flex: 56,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Custom low-poly base environment animation
              AnimatedBuilder(
                animation: _animController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _OutpostPreviewPainter(progress: _animController.value),
                    size: Size.infinite,
                  );
                },
              ),

              // Title Header overlay in upper section
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                  child: Column(
                    children: [
                      BrutalistCard(
                        backgroundColor: GameColors.acidYellow,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        borderWidth: 4.0,
                        shadowOffset: 5.0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shield, color: GameColors.ink, size: 30),
                                SizedBox(width: 8),
                                Text(
                                  'POLY FORT',
                                  style: TextStyle(
                                    color: GameColors.ink,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: GameColors.ink,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: const Text(
                                'BASE DEFENSE • MERGE • SURVIVAL',
                                style: TextStyle(
                                  color: GameColors.acidYellow,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // High Score & Scrap Badges (Clause 114)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          BrutalistBadge(
                            text: 'BEST WAVE: ${save.highestWave}',
                            backgroundColor: GameColors.electricLime,
                            icon: Icons.military_tech,
                            fontSize: 12,
                          ),
                          const SizedBox(width: 8),
                          BrutalistBadge(
                            text: '${save.totalScrap} SCRAP',
                            backgroundColor: GameColors.cyberPurple,
                            textColor: Colors.white,
                            icon: Icons.build_circle,
                            fontSize: 12,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Single Next Milestone Goal (Clauses 203, 252)
                      Builder(builder: (context) {
                        final nextMilestone = GoalPresentationService.resolveNextUnlockGoal(save);
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: GameColors.ink,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: nextMilestone.accentColor, width: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(nextMilestone.icon, color: nextMilestone.accentColor, size: 12),
                              const SizedBox(width: 6),
                              Text(
                                '${nextMilestone.title} • ${nextMilestone.subtitle}',
                                style: TextStyle(
                                  color: nextMilestone.accentColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Lower 42-45%: Neo-Brutalist Action Controls (Clauses 53, 54)
        Expanded(
          flex: 44,
          child: Container(
            color: GameColors.background,
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // PLAY BUTTON: Biggest button, Acid Yellow, Thick Border, 4px push animation (Clause 53, 792)
                  BrutalistButton(
                    label: 'PLAY',
                    icon: Icons.play_arrow,
                    backgroundColor: GameColors.acidYellow,
                    fullWidth: true,
                    fontSize: 22,
                    verticalPadding: 18,
                    pulseOnce: true,
                    onPressed: widget.onStartGame,
                  ),

                  // UPGRADES & ARMORY Secondary Row
                  Row(
                    children: [
                      Expanded(
                        child: BrutalistButton(
                          label: 'UPGRADES',
                          icon: Icons.upgrade,
                          backgroundColor: GameColors.surface,
                          fontSize: 13,
                          verticalPadding: 13,
                          onPressed: widget.onOpenUpgrades,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: BrutalistButton(
                          label: 'ARMORY',
                          icon: Icons.shield,
                          backgroundColor: GameColors.surface,
                          fontSize: 13,
                          verticalPadding: 13,
                          onPressed: widget.onOpenArmory,
                        ),
                      ),
                    ],
                  ),

                  // SETTINGS Button
                  BrutalistButton(
                    label: 'SETTINGS',
                    icon: Icons.settings,
                    backgroundColor: GameColors.surfaceSubtle,
                    fullWidth: true,
                    fontSize: 13,
                    verticalPadding: 11,
                    onPressed: widget.onOpenSettings,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter rendering the 2.5D low-poly outpost environment with subtle idle animations (Clause 53).
class _OutpostPreviewPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0

  _OutpostPreviewPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.65;

    // Ground plane
    final groundPaint = Paint()..color = const Color(0xFFDED9CD);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), groundPaint);

    // Hazard stripes at base apron
    _drawHazardStripe(canvas, size);

    final baseImg = ArtAssetManager.getImage(WorldArtAssets.mainBase);
    if (baseImg != null) {
      final bSrc = Rect.fromLTWH(0, 0, baseImg.width.toDouble(), baseImg.height.toDouble());
      final bDst = Rect.fromCenter(center: Offset(cx, cy + 25), width: 300, height: 100);
      canvas.drawImageRect(baseImg, bSrc, bDst, Paint()..filterQuality = FilterQuality.medium);
    } else {
      // Bunker Platform Fallback (Hex/Isometric Octagon)
      final bunkerPath = Path()
        ..moveTo(cx - 140, cy + 20)
        ..lineTo(cx - 100, cy - 50)
        ..lineTo(cx + 100, cy - 50)
        ..lineTo(cx + 140, cy + 20)
        ..lineTo(cx + 100, cy + 80)
        ..lineTo(cx - 100, cy + 80)
        ..close();

      canvas.drawPath(bunkerPath, Paint()..color = const Color(0xFF8B929E));
      canvas.drawPath(
        bunkerPath,
        Paint()
          ..color = GameColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5,
      );
    }

    // Sandbags Left
    _drawSandbags(canvas, Offset(cx - 95, cy + 25));

    // Metal Crate Right
    _drawCrate(canvas, Offset(cx + 80, cy + 15), 32);

    // Watchtower Center-Back
    _drawTower(canvas, Offset(cx, cy - 55));

    // Animated Idle Soldiers with Low-Poly Sprite Quality (Clauses 1084, 1085)
    final idleBob1 = sin(progress * 2 * pi) * 2.5;
    final idleBob2 = cos(progress * 2 * pi) * 2.5;

    final rDef = UnitArtAssets.definitions[HeroClass.rifleman];
    final hDef = UnitArtAssets.definitions[HeroClass.heavyGunner];
    final rBody = (rDef != null) ? ArtAssetManager.getImage(rDef.bodyAsset) : null;
    final rWpn = (rDef != null) ? ArtAssetManager.getImage(rDef.weaponAsset) : null;
    final hBody = (hDef != null) ? ArtAssetManager.getImage(hDef.bodyAsset) : null;
    final hWpn = (hDef != null) ? ArtAssetManager.getImage(hDef.weaponAsset) : null;

    _drawSoldier(
      canvas,
      Offset(cx - 50, cy + 18 + idleBob1),
      GameColors.riflemanUniform,
      bodyImg: rBody,
      weaponImg: rWpn,
      bodySize: rDef?.bodySize,
    );
    _drawSoldier(
      canvas,
      Offset(cx + 50, cy + 22 + idleBob2),
      GameColors.heavyGunnerUniform,
      bodyImg: hBody,
      weaponImg: hWpn,
      bodySize: hDef?.bodySize,
    );
  }

  void _drawHazardStripe(Canvas canvas, Size size) {
    final stripePaint = Paint()
      ..color = GameColors.acidYellow.withValues(alpha: 0.35)
      ..strokeWidth = 14;
    for (double x = -100; x < size.width + 100; x += 36) {
      canvas.drawLine(Offset(x, size.height - 20), Offset(x + 24, size.height), stripePaint);
    }
  }

  void _drawSandbags(Canvas canvas, Offset origin) {
    final bagPaint = Paint()..color = const Color(0xFFB5A686);
    final borderPaint = Paint()
      ..color = GameColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int row = 0; row < 2; row++) {
      for (int i = 0; i < 2; i++) {
        final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(origin.dx + (i * 22) + (row * 10), origin.dy - (row * 12), 24, 13),
          const Radius.circular(3),
        );
        canvas.drawRRect(r, bagPaint);
        canvas.drawRRect(r, borderPaint);
      }
    }
  }

  void _drawCrate(Canvas canvas, Offset origin, double size) {
    final crateRect = Rect.fromLTWH(origin.dx, origin.dy, size, size);
    canvas.drawRect(crateRect, Paint()..color = const Color(0xFF4A5568));
    canvas.drawRect(
      crateRect,
      Paint()
        ..color = GameColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    // X brace
    final xPaint = Paint()
      ..color = GameColors.ink
      ..strokeWidth = 1.8;
    canvas.drawLine(crateRect.topLeft, crateRect.bottomRight, xPaint);
    canvas.drawLine(crateRect.topRight, crateRect.bottomLeft, xPaint);
  }

  void _drawTower(Canvas canvas, Offset base) {
    // Pillar
    final pillar = Rect.fromCenter(center: base + const Offset(0, -30), width: 44, height: 60);
    canvas.drawRect(pillar, Paint()..color = const Color(0xFF334155));
    canvas.drawRect(
      pillar,
      Paint()
        ..color = GameColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Cupola Roof
    final roof = Path()
      ..moveTo(base.dx - 32, base.dy - 60)
      ..lineTo(base.dx, base.dy - 85)
      ..lineTo(base.dx + 32, base.dy - 60)
      ..close();
    canvas.drawPath(roof, Paint()..color = GameColors.punchRed);
    canvas.drawPath(
      roof,
      Paint()
        ..color = GameColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Blinking Radar / Beacon Light (Clause 53)
    final blinkPhase = (sin(progress * 4 * pi) + 1) / 2;
    final beaconColor = Color.lerp(GameColors.acidYellow, Colors.white, blinkPhase)!;
    canvas.drawCircle(Offset(base.dx, base.dy - 88), 4.5, Paint()..color = beaconColor);

    // Flag pole & Swaying Flag (Clause 53)
    canvas.drawLine(
      Offset(base.dx + 20, base.dy - 60),
      Offset(base.dx + 20, base.dy - 100),
      Paint()
        ..color = GameColors.ink
        ..strokeWidth = 2.0,
    );

    final flagSway = sin(progress * 2 * pi) * 4.0;
    final flag = Path()
      ..moveTo(base.dx + 20, base.dy - 100)
      ..lineTo(base.dx + 42 + flagSway, base.dy - 93)
      ..lineTo(base.dx + 20, base.dy - 86)
      ..close();
    canvas.drawPath(flag, Paint()..color = GameColors.electricLime);
    canvas.drawPath(
      flag,
      Paint()
        ..color = GameColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawSoldier(
    Canvas canvas,
    Offset pos,
    Color uniformColor, {
    ui.Image? bodyImg,
    ui.Image? weaponImg,
    Vector2? bodySize,
  }) {
    if (bodyImg != null) {
      final bSize = bodySize ?? Vector2(72, 72);
      // Pre-rendered Low-Poly Soldier (Clauses 1084, 1085)
      canvas.drawOval(
        Rect.fromCenter(center: pos + const Offset(0, 16), width: 34, height: 14),
        Paint()..color = const Color(0x38000000),
      );
      final bodySrc = Rect.fromLTWH(0, 0, bodyImg.width.toDouble(), bodyImg.height.toDouble());
      final bodyDst = Rect.fromCenter(center: pos, width: bSize.x * 0.72, height: bSize.y * 0.72);
      canvas.drawImageRect(bodyImg, bodySrc, bodyDst, Paint()..filterQuality = FilterQuality.medium);

      if (weaponImg != null) {
        final wpnSrc = Rect.fromLTWH(0, 0, weaponImg.width.toDouble(), weaponImg.height.toDouble());
        final wpnDst = Rect.fromCenter(center: pos + const Offset(8, -6), width: bSize.x * 0.40, height: bSize.y * 0.40);
        canvas.drawImageRect(weaponImg, wpnSrc, wpnDst, Paint()..filterQuality = FilterQuality.medium);
      }
    } else {
      // Drop shadow fallback
      canvas.drawOval(
        Rect.fromCenter(center: pos + const Offset(0, 8), width: 22, height: 10),
        Paint()..color = Colors.black.withValues(alpha: 0.25),
      );

      // Body
      final body = Rect.fromCenter(center: pos, width: 16, height: 18);
      canvas.drawRRect(
        RRect.fromRectAndRadius(body, const Radius.circular(3)),
        Paint()..color = uniformColor,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(body, const Radius.circular(3)),
        Paint()
          ..color = GameColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );

      // Helmet
      canvas.drawCircle(pos + const Offset(0, -11), 7.5, Paint()..color = const Color(0xFF1E293B));
      canvas.drawCircle(
        pos + const Offset(0, -11),
        7.5,
        Paint()
          ..color = GameColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );

      // Visor
      canvas.drawRect(
        Rect.fromCenter(center: pos + const Offset(0, -10), width: 8, height: 3),
        Paint()..color = GameColors.techBlue,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OutpostPreviewPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
