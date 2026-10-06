import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../constants/art_assets.dart';
import '../constants/game_colors.dart';
import '../constants/visual_feedback_config.dart';
import '../models/enemy_data.dart';
import '../utils/isometric_helper.dart';
import '../game/base_defense_game.dart';
import '../managers/game_manager.dart';
import '../managers/audio_manager.dart';
import '../managers/camera_feedback_manager.dart';
import 'damage_text_component.dart';
import 'coin_component.dart';
import 'vfx_component.dart';

/// Advancing horde mutant in the 2.5D arena.
/// Features archetype-tailored locomotion, hit squash, and clean dissolve (Clauses 745–751).
///
/// ponytail: Procedural hit squash, walk variations, and staged death sequence.
class EnemyComponent extends PositionComponent with HasGameReference<BaseDefenseGame> {
  final EnemyDefinition definition;
  final int wave;
  final int laneIndex;

  late double maxHp;
  late double currentHp;
  late double speed;
  late double currentShield;
  late double maxShield;

  bool isDead = false;
  bool isAttackingBase = false;
  double _baseAttackTimer = 0.0;
  double _hitFlashTimer = 0.0;
  double _hitSquashTimer = 0.0;
  double _spawnElapsed = 0.0;
  double _walkCycle = 0.0;

  // Staged death presentation (Clause 750)
  bool _isDying = false;
  double _deathElapsed = 0.0;

  // Damage text throttling & batching (Clauses 768, 805)
  double _damageBatchTimer = 0.0;
  double _batchedDamage = 0.0;
  bool _hasBatchedCrit = false;

  // Multiplier overrides from GameMode (ChaosModifier, BossRushRoundData)
  final double hpMultiplier;
  final double speedMultiplier;
  final double coinMultiplier;
  final double visualScale;
  final double baseDamageMultiplier;
  final int? customCoinReward;

  // Boss specific state (Clause 75)
  double _chargeCooldownTimer = 7.0;
  double _chargeTimer = 0.0;
  bool _isBossCharging = false;

  EnemyComponent({
    required this.definition,
    required this.wave,
    required this.laneIndex,
    required Vector2 spawnPosition,
    this.hpMultiplier = 1.0,
    this.speedMultiplier = 1.0,
    this.coinMultiplier = 1.0,
    this.visualScale = 1.0,
    this.baseDamageMultiplier = 1.0,
    this.customCoinReward,
  }) : super(
          position: spawnPosition,
          size: Vector2(definition.radius * 2.4 * visualScale, definition.radius * 2.4 * visualScale),
          anchor: Anchor.center,
          priority: 30,
        ) {
    maxHp = definition.getScaledHp(wave) * hpMultiplier;
    currentHp = maxHp;
    speed = definition.getScaledSpeed(wave) * speedMultiplier;
    maxShield = definition.getScaledShield(wave);
    currentShield = maxShield;
    _chargeCooldownTimer = definition.chargeCooldown > 0 ? definition.chargeCooldown : 7.0;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Death dissolve sequence (Clause 750: 150–250ms)
    if (_isDying) {
      _deathElapsed += dt;
      if (_deathElapsed >= VisualFeedbackConfig.enemyDeathDissolveDuration) {
        removeFromParent();
      }
      return;
    }

    if (isDead) return;

    // Freeze enemies during Second Chance grace period and decision modal (Clauses 464, 473, 474)
    if (game.gameManager.isGracePeriodActive ||
        game.gameManager.state == GameState.awaitingSecondChance ||
        game.gameManager.state == GameState.paused) {
      return;
    }

    // Spawn presentation timer (Clause 749)
    if (_spawnElapsed < VisualFeedbackConfig.enemySpawnDuration) {
      _spawnElapsed += dt;
    }

    if (_hitFlashTimer > 0) {
      _hitFlashTimer -= dt;
    }
    if (_hitSquashTimer > 0) {
      _hitSquashTimer -= dt;
    }

    // Damage text batching dispatch (Clause 768)
    if (_damageBatchTimer > 0) {
      _damageBatchTimer -= dt;
      if (_damageBatchTimer <= 0 && _batchedDamage > 0) {
        game.add(
          DamageTextComponent(
            text: _hasBatchedCrit ? 'CRIT!\n${_batchedDamage.round()}' : '${_batchedDamage.round()}',
            position: position.clone()..y -= 12,
            isCrit: _hasBatchedCrit,
          ),
        );
        _batchedDamage = 0.0;
        _hasBatchedCrit = false;
      }
    }

    // Boss footstep dust (Clause 781)
    final prevCycle = _walkCycle;
    _walkCycle += dt * (speed / 14.0);
    if (definition.type == EnemyType.boss) {
      if ((prevCycle % pi) > (_walkCycle % pi)) {
        game.add(
          ImpactFlashVFXComponent(
            position: position.clone()..y += definition.radius * 0.7,
            color: const Color(0xFF8D8D8D),
          ),
        );
      }
    }

    // Boss special charge cycle (Clause 75: 7s cooldown, 1.2s charge at 55 speed)
    if (definition.type == EnemyType.boss) {
      if (_isBossCharging) {
        _chargeTimer -= dt;
        if (_chargeTimer <= 0) {
          _isBossCharging = false;
          _chargeCooldownTimer = definition.chargeCooldown;
        }
      } else {
        _chargeCooldownTimer -= dt;
        if (_chargeCooldownTimer <= 0) {
          _isBossCharging = true;
          _chargeTimer = definition.chargeDuration;
          game.add(ShockwaveVFXComponent(position: position.clone(), color: GameColors.enemyBoss));
        }
      }
    }

    final effectiveSpeed = _isBossCharging ? definition.chargeSpeed : speed;
    const baseBreachY = 675.0; // Point where enemy halts and attacks base

    if (position.y < baseBreachY) {
      position.y += effectiveSpeed * dt;
      // Subtle lane wander
      position.x += sin(_walkCycle * 2) * 0.4;
    } else {
      // Reached base
      if (!isAttackingBase) {
        isAttackingBase = true;
        _baseAttackTimer = 0.2; // Strike promptly upon arrival
      }

      _baseAttackTimer -= dt;
      if (_baseAttackTimer <= 0) {
        _baseAttackTimer = definition.attackInterval;
        _strikeBase();
      }
    }
  }

  void _strikeBase() {
    game.gameManager.damageBase(definition.getScaledDamage(wave) * baseDamageMultiplier);
    game.baseBunker.triggerDamageFlash();

    // Stomp shockwave for boss
    if (definition.type == EnemyType.boss) {
      game.add(ShockwaveVFXComponent(position: position.clone(), color: GameColors.punchRed));
    }
  }

  void takeDamage(double damage, bool isCrit) {
    if (isDead) return;

    _hitFlashTimer = VisualFeedbackConfig.hitFlashDuration;
    _hitSquashTimer = VisualFeedbackConfig.hitSquashDuration;
    AudioManager.instance.playEnemyHit();

    double appliedDamage = damage;

    // Shield absorption with overflow (Clause 93)
    if (currentShield > 0) {
      if (currentShield >= appliedDamage) {
        currentShield -= appliedDamage;
        appliedDamage = 0;
      } else {
        appliedDamage -= currentShield;
        currentShield = 0;
        // Shield broken VFX
        game.add(
          ImpactFlashVFXComponent(
            position: position.clone(),
            color: GameColors.enemyShieldRing,
          ),
        );
      }
    }

    // Gameplay damage calculation is strictly applied immediately (Clause 848, 878)
    currentHp -= appliedDamage;

    // Damage Number Floater with throttling/batching (Clauses 768, 805)
    final activeTextsCount = game.world.children.whereType<DamageTextComponent>().length;
    if (_damageBatchTimer > 0 || activeTextsCount >= VisualFeedbackConfig.maxVisibleFloatingTexts) {
      _batchedDamage += damage;
      if (isCrit) _hasBatchedCrit = true;
      _damageBatchTimer = VisualFeedbackConfig.damageBatchWindowSeconds;
    } else {
      game.add(
        DamageTextComponent(
          text: isCrit ? 'CRIT!\n${damage.round()}' : '${damage.round()}',
          position: position.clone()..y -= 12,
          isCrit: isCrit,
        ),
      );
      _damageBatchTimer = VisualFeedbackConfig.damageBatchWindowSeconds;
    }

    if (currentHp <= 0) {
      _die();
    }
  }

  void _die() {
    if (isDead) return;
    isDead = true; // Immediate gameplay kill logic (Clause 750)
    _isDying = true;
    _deathElapsed = 0.0;

    // Flush any remaining batched damage text
    if (_batchedDamage > 0) {
      game.add(
        DamageTextComponent(
          text: _hasBatchedCrit ? 'CRIT!\n${_batchedDamage.round()}' : '${_batchedDamage.round()}',
          position: position.clone()..y -= 12,
          isCrit: _hasBatchedCrit,
        ),
      );
      _batchedDamage = 0.0;
    }

    // Camera impulse on Boss defeat (Clauses 783, 800)
    if (definition.type == EnemyType.boss) {
      game.triggerCameraShakePreset(CameraShakePreset.medium);
    }

    // Death particle puff (Clause 751: colored particles, no blood)
    game.add(
      DeathPuffVFXComponent(
        position: position.clone(),
        color: definition.baseColor,
        isLarge: definition.type == EnemyType.boss,
      ),
    );

    // Coin award & animated coin pop
    final rawReward = customCoinReward ?? definition.baseCoinReward;
    final coinReward = (rawReward * coinMultiplier).round();
    if (definition.type == EnemyType.boss) {
      game.gameManager.onBossDefeated(coinReward);
    } else {
      game.gameManager.onEnemyKilled(coinReward);
    }
    game.add(
      CoinComponent(
        spawnPosition: position.clone(),
        coinValue: coinReward,
      ),
    );
  }

  // --- 2.5D LOW-POLY MONSTER RENDERING ---
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final r = definition.radius * visualScale;

    // Drop shadow
    IsometricHelper.drawDropShadow(
      canvas: canvas,
      center: Offset(0, r * 0.9),
      radiusX: r * 1.1,
      radiusY: r * 0.55,
      opacity: _isDying ? 0.15 : 0.32,
    );

    canvas.save();

    // Archetype-tailored walk locomotion (Clauses 747–748)
    double bobY = 0.0;
    double swayX = 0.0;
    double leanAngle = 0.0;

    switch (definition.type) {
      case EnemyType.runner:
        bobY = sin(_walkCycle * 6.0) * 3.2;
        leanAngle = 0.22; // Distinct forward aggressive lean (Clause 1065)
        break;
      case EnemyType.tank:
        bobY = sin(_walkCycle * 2.2) * 1.6;
        swayX = sin(_walkCycle * 1.1) * 3.2; // Heavy armor lateral sway
        break;
      case EnemyType.swarm:
        bobY = -sin(_walkCycle * 8.0).abs() * 4.5; // Rapid skitter/hop
        break;
      case EnemyType.shielded:
        bobY = sin(_walkCycle * 3.5) * 2.0;
        break;
      case EnemyType.boss:
        bobY = sin(_walkCycle * 2.0) * 3.5; // Heavy stomping gait
        swayX = sin(_walkCycle * 1.0) * 2.2;
        break;
      case EnemyType.basic:
        bobY = sin(_walkCycle * 4.0) * 2.0; // Balanced walk
        break;
    }

    canvas.translate(swayX, bobY);
    if (leanAngle != 0.0) {
      canvas.rotate(leanAngle);
    }

    // Hit squash presentation (Clause 746, 1080: tangible impact reaction)
    if (_hitSquashTimer > 0) {
      final t = _hitSquashTimer / VisualFeedbackConfig.hitSquashDuration;
      final amp = (definition.type == EnemyType.boss || definition.type == EnemyType.tank) ? 0.025 : 0.055;
      canvas.scale(1.0 + (amp * t), 1.0 - (amp * t));
    }

    // Spawn presentation (Clause 749: scale 0.85 -> 1.0)
    if (_spawnElapsed < VisualFeedbackConfig.enemySpawnDuration) {
      final sp = (_spawnElapsed / VisualFeedbackConfig.enemySpawnDuration).clamp(0.0, 1.0);
      final spawnScale = 0.85 + (0.15 * sp);
      canvas.scale(spawnScale);
    }

    // Staged Death dissolve presentation (Clause 750: scale 1.0 -> 1.08 -> 0.70 + fade)
    if (_isDying) {
      final dp = (_deathElapsed / VisualFeedbackConfig.enemyDeathDissolveDuration).clamp(0.0, 1.0);
      double deathScale;
      if (dp < 0.3) {
        deathScale = 1.0 + (0.08 * (dp / 0.3));
      } else {
        deathScale = 1.08 - (0.38 * ((dp - 0.3) / 0.7));
      }
      canvas.scale(deathScale);
    }

    final enemyDef = EnemyArtAssets.definitions[definition.type];
    final sheetImg = (enemyDef != null) ? ArtAssetManager.getImage(enemyDef.walkAsset) : null;

    if (enemyDef != null && sheetImg != null) {
      // 1. Contact shadow (Clause 897, 944–946)
      final shadowW = enemyDef.shadowSize.x;
      final shadowH = enemyDef.shadowSize.y;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(0, enemyDef.visualSize.y * 0.40), width: shadowW, height: shadowH),
        Paint()..color = const Color(0xFF1A1D24).withValues(alpha: 0.24),
      );

      // 2. Animated Walk Frame (Clause 936–938: 6-frame loop)
      final frameW = sheetImg.width / 6.0;
      final frameH = sheetImg.height.toDouble();
      final currentFrame = ((_walkCycle * enemyDef.animationFps).toInt() % 6);
      final srcRect = Rect.fromLTWH(currentFrame * frameW, 0, frameW, frameH);
      final dstRect = Rect.fromCenter(center: Offset.zero, width: enemyDef.visualSize.x, height: enemyDef.visualSize.y);

      final spritePaint = Paint()..filterQuality = FilterQuality.medium;

      // Hit flash (Clause 745: 60ms white flash)
      if (_hitFlashTimer > 0) {
        spritePaint.colorFilter = const ColorFilter.mode(Colors.white, BlendMode.srcATop);
      }

      // Death fade (Clause 750)
      if (_isDying) {
        final dp = (_deathElapsed / VisualFeedbackConfig.enemyDeathDissolveDuration).clamp(0.0, 1.0);
        spritePaint.color = Colors.white.withValues(alpha: (1.0 - dp).clamp(0.0, 1.0));
      }

      canvas.drawImageRect(sheetImg, srcRect, dstRect, spritePaint);

      // 3. Shield Visual (Clause 941, 1065)
      if (enemyDef.shieldAsset != null && currentShield > 0 && !_isDying) {
        final shieldImg = ArtAssetManager.getImage(enemyDef.shieldAsset!);
        if (shieldImg != null) {
          final sSrc = Rect.fromLTWH(0, 0, shieldImg.width.toDouble(), shieldImg.height.toDouble());
          final sDst = Rect.fromCenter(
            center: const Offset(0, 4),
            width: enemyDef.visualSize.x * 0.82,
            height: enemyDef.visualSize.y * 0.82,
          );
          canvas.drawImageRect(shieldImg, sSrc, sDst, Paint()..filterQuality = FilterQuality.medium);
        }
      }

      // Health Bar (above monster)
      if (!_isDying) {
        _drawHealthBar(canvas, enemyDef.visualSize.y * 0.5);
      }
    } else {
      if (_hitFlashTimer > 0) {
        // White hit flash
        final flashPaint = Paint()..color = Colors.white;
        canvas.drawCircle(Offset.zero, r, flashPaint);
      } else {
        _drawMonsterBody(canvas, r);
      }

      // Shield Bubble if active
      if (currentShield > 0 && !_isDying) {
        _drawShieldBubble(canvas, r);
      }

      // Health Bar (above monster)
      if (!_isDying) {
        _drawHealthBar(canvas, r);
      }
    }

    canvas.restore();
  }

  void _drawMonsterBody(Canvas canvas, double r) {
    final type = definition.type;
    final baseColor = definition.baseColor;

    switch (type) {
      case EnemyType.basic:
        _drawBasicMutant(canvas, r, baseColor);
        break;
      case EnemyType.runner:
        _drawRunnerMutant(canvas, r, baseColor);
        break;
      case EnemyType.tank:
        _drawTankMutant(canvas, r, baseColor);
        break;
      case EnemyType.swarm:
        _drawSwarmMutant(canvas, r, baseColor);
        break;
      case EnemyType.shielded:
        _drawShieldedMutant(canvas, r, baseColor);
        break;
      case EnemyType.boss:
        _drawBossBrute(canvas, r, baseColor);
        break;
    }
  }

  void _drawBasicMutant(Canvas canvas, double r, Color color) {
    // Faceted diamond torso
    final body = Path()
      ..moveTo(0, -r)
      ..lineTo(r, 0)
      ..lineTo(0, r)
      ..lineTo(-r, 0)
      ..close();
    canvas.drawPath(body, Paint()..color = color);

    // Shaded side
    final shade = Path()
      ..moveTo(0, -r)
      ..lineTo(r, 0)
      ..lineTo(0, r)
      ..close();
    canvas.drawPath(shade, Paint()..color = Colors.black.withValues(alpha: 0.22));

    // Contour
    canvas.drawPath(
      body,
      Paint()
        ..color = GameColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );

    // Glowing menacing eye
    canvas.drawCircle(const Offset(0, -2), 3.0, Paint()..color = GameColors.acidYellow);
  }

  void _drawRunnerMutant(Canvas canvas, double r, Color color) {
    // Sharp angular dart silhouette
    final body = Path()
      ..moveTo(0, r * 1.1)
      ..lineTo(-r * 0.9, -r * 0.9)
      ..lineTo(0, -r * 0.4)
      ..lineTo(r * 0.9, -r * 0.9)
      ..close();
    canvas.drawPath(body, Paint()..color = color);

    canvas.drawPath(
      body,
      Paint()
        ..color = GameColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );

    // Twin red eyes
    canvas.drawCircle(Offset(-3, -2), 2.2, Paint()..color = GameColors.punchRed);
    canvas.drawCircle(Offset(3, -2), 2.2, Paint()..color = GameColors.punchRed);
  }

  void _drawTankMutant(Canvas canvas, double r, Color color) {
    // Hexagonal armored juggernaut
    final body = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * pi) / 3;
      final x = cos(angle) * r;
      final y = sin(angle) * r;
      if (i == 0) {
        body.moveTo(x, y);
      } else {
        body.lineTo(x, y);
      }
    }
    body.close();

    canvas.drawPath(body, Paint()..color = color);

    // Iron carapace plate
    canvas.drawCircle(Offset.zero, r * 0.6, Paint()..color = const Color(0xFF262626));
    canvas.drawCircle(
      Offset.zero,
      r * 0.6,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Thick border
    canvas.drawPath(
      body,
      Paint()
        ..color = GameColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2,
    );
  }

  void _drawSwarmMutant(Canvas canvas, double r, Color color) {
    // Tiny spiky bug
    canvas.drawCircle(Offset.zero, r, Paint()..color = color);
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..color = GameColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Mandibles
    final mandibles = Paint()
      ..color = GameColors.ink
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(-r * 0.6, r * 0.7), Offset(-r * 0.2, r * 1.3), mandibles);
    canvas.drawLine(Offset(r * 0.6, r * 0.7), Offset(r * 0.2, r * 1.3), mandibles);
  }

  void _drawShieldedMutant(Canvas canvas, double r, Color color) {
    _drawBasicMutant(canvas, r, color);
  }

  void _drawBossBrute(Canvas canvas, double r, Color color) {
    // Massive polyhedral warlord
    final body = Path()
      ..moveTo(0, -r)
      ..lineTo(r * 1.1, -r * 0.3)
      ..lineTo(r * 0.8, r * 0.9)
      ..lineTo(-r * 0.8, r * 0.9)
      ..lineTo(-r * 1.1, -r * 0.3)
      ..close();

    canvas.drawPath(body, Paint()..color = color);

    // Shoulder spikes
    final spikePaint = Paint()..color = GameColors.acidYellow;
    final leftSpike = Path()
      ..moveTo(-r * 1.1, -r * 0.3)
      ..lineTo(-r * 1.45, -r * 0.7)
      ..lineTo(-r * 0.8, -r * 0.6)
      ..close();
    canvas.drawPath(leftSpike, spikePaint);

    final rightSpike = Path()
      ..moveTo(r * 1.1, -r * 0.3)
      ..lineTo(r * 1.45, -r * 0.7)
      ..lineTo(r * 0.8, -r * 0.6)
      ..close();
    canvas.drawPath(rightSpike, spikePaint);

    // Contours
    canvas.drawPath(
      body,
      Paint()
        ..color = GameColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0,
    );

    // Skull crown insignia
    canvas.drawCircle(Offset(0, -r * 0.2), 6.0, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(0, -r * 0.2), 3.0, Paint()..color = GameColors.punchRed);
  }

  void _drawShieldBubble(Canvas canvas, double r) {
    final shieldPaint = Paint()
      ..color = GameColors.techBlue.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    final ringPaint = Paint()
      ..color = GameColors.enemyShieldRing
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawCircle(Offset.zero, r * 1.35, shieldPaint);
    canvas.drawCircle(Offset.zero, r * 1.35, ringPaint);
  }

  void _drawHealthBar(Canvas canvas, double r) {
    const barW = 32.0;
    const barH = 5.0;
    final topOffset = -r - 10.0;

    final bgRect = Rect.fromCenter(center: Offset(0, topOffset), width: barW, height: barH);
    canvas.drawRect(bgRect, Paint()..color = GameColors.ink);

    final hpPct = (currentHp / maxHp).clamp(0.0, 1.0);
    final fillRect = Rect.fromLTWH(
      bgRect.left + 1,
      bgRect.top + 1,
      (barW - 2) * hpPct,
      barH - 2,
    );

    final hpPaint = Paint()
      ..color = (hpPct > 0.4) ? GameColors.electricLime : GameColors.punchRed;
    canvas.drawRect(fillRect, hpPaint);
  }
}
