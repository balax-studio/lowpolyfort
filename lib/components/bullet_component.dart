import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../constants/game_colors.dart';
import '../constants/game_config.dart';
import '../models/hero_data.dart';
import '../managers/camera_feedback_manager.dart';
import '../utils/isometric_helper.dart';
import '../game/base_defense_game.dart';
import 'vfx_component.dart';

/// High-velocity tracer round fired by defenders with archetype-specific trails (Clause 744).
///
/// ponytail: Procedural tracer lengths based on weapon archetype without external particles.
class BulletComponent extends PositionComponent with HasGameReference<BaseDefenseGame> {
  final double angleRad;
  final double speed;
  final double damage;
  final bool isCrit;
  final Color color;
  final HeroClass? heroClass;

  late Vector2 velocity;

  BulletComponent({
    required Vector2 spawnPosition,
    required double angle,
    required this.speed,
    required this.damage,
    required this.isCrit,
    required this.color,
    this.heroClass,
  })  : angleRad = angle,
        super(
          position: spawnPosition,
          size: Vector2(16, 6),
          anchor: Anchor.center,
          priority: 40,
        ) {
    velocity = Vector2(cos(angleRad), sin(angleRad)) * speed;
  }

  @override
  void update(double dt) {
    super.update(dt);

    position += velocity * dt;

    // Check boundary despawn
    if (position.y < -40 ||
        position.y > GameConfig.virtualHeight + 40 ||
        position.x < -40 ||
        position.x > GameConfig.virtualWidth + 40) {
      removeFromParent();
      return;
    }

    // Check hit collision against active enemies
    for (final enemy in game.activeEnemies) {
      if (enemy.isDead || !enemy.isMounted) continue;

      final dist = (enemy.position - position).length;
      if (dist <= enemy.definition.radius + 6.0) {
        // Hit confirmed!
        enemy.takeDamage(damage, isCrit);

        // Small micro camera impulse on crits (Clause 800)
        if (isCrit) {
          game.triggerCameraShakePreset(CameraShakePreset.micro);
        }

        // Impact spark
        game.add(
          ImpactFlashVFXComponent(
            position: position.clone(),
            color: isCrit ? GameColors.critGold : color,
          ),
        );

        removeFromParent();
        return;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Drop shadow
    IsometricHelper.drawDropShadow(
      canvas: canvas,
      center: const Offset(0, 10),
      radiusX: 7,
      radiusY: 3,
      opacity: 0.22,
    );

    canvas.save();
    canvas.rotate(angleRad);

    // Archetype projectile trail dimensions (Clause 744)
    double tracerLen;
    double tracerWidth;
    switch (heroClass) {
      case HeroClass.sniper:
        tracerLen = isCrit ? 30.0 : 24.0; // Long thin bright trail
        tracerWidth = 2.8;
        break;
      case HeroClass.shotgunner:
        tracerLen = 8.0; // Very short pellet streak
        tracerWidth = 4.8;
        break;
      case HeroClass.heavyGunner:
        tracerLen = 10.0; // Tiny rapid tracer
        tracerWidth = 3.2;
        break;
      case HeroClass.rifleman:
      default:
        tracerLen = isCrit ? 18.0 : 13.0; // Small short trail
        tracerWidth = 4.0;
        break;
    }

    final tracerPaint = Paint()..color = isCrit ? GameColors.acidYellow : color;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: tracerLen, height: tracerWidth),
      const Radius.circular(2),
    );
    canvas.drawRRect(rrect, tracerPaint);

    // Core white light
    final corePaint = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: tracerLen * 0.5, height: max(1.5, tracerWidth * 0.45)),
        const Radius.circular(1),
      ),
      corePaint,
    );

    // Neo-brutalist dark contour
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = GameColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    canvas.restore();
  }
}
