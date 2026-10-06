import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../constants/art_assets.dart';
import '../constants/game_balance.dart';
import '../constants/game_colors.dart';
import '../constants/visual_feedback_config.dart';
import '../models/hero_data.dart';
import '../models/enemy_data.dart';
import '../models/game_mode_data.dart';
import '../utils/isometric_helper.dart';
import '../utils/math_utils.dart';
import '../game/base_defense_game.dart';
import '../managers/audio_manager.dart';
import '../systems/combat_calculator.dart';
import 'defense_slot_component.dart';
import 'enemy_component.dart';
import 'bullet_component.dart';
import 'damage_text_component.dart';

/// A defender unit stationed in the 3x3 defense grid.
/// Handles 2.5D low-poly rendering, touch dragging, auto targeting, and weapon discharge.
///
/// ponytail: Pre-rendered low-poly composite rendering with procedural fallback.
class HeroComponent extends PositionComponent
    with DragCallbacks, HasGameReference<BaseDefenseGame> {
  final HeroDefinition definition;
  int level;
  DefenseSlotComponent slot;

  // Drag states & Juicy feel (Clauses 756–757)
  bool isDragging = false;
  Vector2 _dragTargetPos = Vector2.zero();
  bool _isReturning = false;
  double _returnElapsed = 0.0;
  Vector2 _returnStartPos = Vector2.zero();
  double _dragTilt = 0.0;

  // Idle Breathing & Offset (Clauses 736–737)
  late final double _idlePhaseOffset = Random().nextDouble() * 2 * pi;
  double _idleTimer = 0.0;

  // Visual cues (Clauses 59, 67)
  double _spawnAnimElapsed = 0.0;
  bool isMergeCandidate = false;
  double _candidatePulse = 0.0;

  // Combat states & Weapon Kickback (Clauses 738–743)
  double _scanCooldown = 0.0;
  double _attackCooldown = 0.0;
  double _muzzleFlashTimer = 0.0;
  double _recoilDistance = 0.0;
  double aimAngle = -pi / 2; // Current smoothly eased facing angle
  double _targetAimAngle = -pi / 2; // Target angle to ease toward
  EnemyComponent? currentTarget;

  HeroComponent({
    required this.definition,
    required this.level,
    required this.slot,
  }) : super(
          position: slot.position.clone(),
          size: Vector2(50, 56),
          anchor: Anchor.center,
          priority: 20,
        );

  HeroClass get heroClass => definition.heroClass;

  /// Power accent layer opacity scaling with level (Clause 928).
  double get powerAccentOpacity => UnitArtAssets.getPowerAccentOpacity(level);

  /// Resets attack and targeting cooldown so newly promoted unit strikes immediately (Clause 196)
  void resetAttackCooldown() {
    _attackCooldown = 0.0;
    _scanCooldown = 0.0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _idleTimer += dt;

    // Decay drag inertial tilt back to neutral (Clause 757)
    if (!isDragging && _dragTilt != 0.0) {
      if (_dragTilt.abs() < 0.01) {
        _dragTilt = 0.0;
      } else {
        _dragTilt -= _dragTilt * dt * 10.0;
      }
    }

    // Decay weapon kickback (Clauses 739–743)
    if (_recoilDistance > 0) {
      _recoilDistance = max(0.0, _recoilDistance - dt * 35.0);
    }

    // Clause 59: Spawn animation (0.6 -> 1.15 -> 1.0 scale over 0.28s)
    if (_spawnAnimElapsed < 0.28) {
      _spawnAnimElapsed += dt;
      final t = (_spawnAnimElapsed / 0.28).clamp(0.0, 1.0);
      double currentScale;
      if (t < 0.6) {
        currentScale = 0.6 + (0.55 * (t / 0.6)); // 0.6 to 1.15
      } else {
        currentScale = 1.15 - (0.15 * ((t - 0.6) / 0.4)); // 1.15 to 1.0
      }
      scale.setAll(currentScale);
    }

    if (isMergeCandidate) {
      _candidatePulse += dt * 6.0;
    } else {
      _candidatePulse = 0.0;
    }

    if (isDragging) {
      position.setFrom(_dragTargetPos);
      _updateSlotHoverStates();
      return;
    }

    if (_isReturning) {
      _returnElapsed += dt;
      final progress = (_returnElapsed / GameBalance.dragSpringReturnDurationSeconds).clamp(0.0, 1.0);
      final eased = MathUtils.easeOutCubic(progress);
      position.x = _returnStartPos.x + (slot.position.x - _returnStartPos.x) * eased;
      position.y = _returnStartPos.y + (slot.position.y - _returnStartPos.y) * eased;

      if (progress >= 1.0) {
        _isReturning = false;
        position.setFrom(slot.position);
        scale.setAll(1.0);
        priority = 20;
      }
      return;
    }

    // Auto-combat loop
    _attackCooldown -= dt;
    _scanCooldown -= dt;
    if (_muzzleFlashTimer > 0) {
      _muzzleFlashTimer -= dt;
    }

    // Smoothly ease aimAngle toward _targetAimAngle over 80–150ms (Clause 738)
    double angleDiff = (_targetAimAngle - aimAngle) % (2 * pi);
    if (angleDiff > pi) angleDiff -= 2 * pi;
    if (angleDiff < -pi) angleDiff += 2 * pi;
    final maxStep = (pi / VisualFeedbackConfig.targetingEaseDuration) * dt;
    if (angleDiff.abs() <= maxStep) {
      aimAngle = _targetAimAngle;
    } else {
      aimAngle += angleDiff.sign * maxStep;
    }

    // Clause 94: Target Lock persistence
    final maxRange = definition.getRangeAtLevel(level) * game.gameManager.upgrades.rangeMultiplier;

    if (currentTarget != null) {
      if (currentTarget!.isDead || !currentTarget!.isMounted) {
        currentTarget = null;
      } else {
        final dist = (currentTarget!.position - position).length;
        if (dist > maxRange) {
          currentTarget = null;
        } else {
          _targetAimAngle = MathUtils.angleBetween(
            Offset(position.x, position.y),
            Offset(currentTarget!.position.x, currentTarget!.position.y),
          );
        }
      }
    }

    // Periodic targeting scan only when target is null
    if (currentTarget == null && _scanCooldown <= 0) {
      _scanCooldown = GameBalance.targetScanInterval + (Random().nextDouble() * 0.04);
      _acquireTarget(maxRange);
    }

    // Auto-fire
    if (currentTarget != null && _attackCooldown <= 0) {
      _fireWeapon();
    }
  }

  void _acquireTarget(double maxRange) {
    final enemies = game.activeEnemies;
    if (enemies.isEmpty) {
      currentTarget = null;
      return;
    }

    final inRange = enemies.where((e) {
      if (e.isDead || !e.isMounted) return false;
      return (e.position - position).length <= maxRange;
    }).toList();

    if (inRange.isEmpty) {
      currentTarget = null;
      return;
    }

    // Apply target priority
    final priority = definition.defaultPriority;
    switch (priority) {
      case TargetPriority.first:
        inRange.sort((a, b) => b.position.y.compareTo(a.position.y));
        break;
      case TargetPriority.closest:
        inRange.sort((a, b) {
          final da = (a.position - position).length2;
          final db = (b.position - position).length2;
          return da.compareTo(db);
        });
        break;
      case TargetPriority.strongest:
        inRange.sort((a, b) => b.currentHp.compareTo(a.currentHp));
        break;
      case TargetPriority.lowestHp:
        inRange.sort((a, b) => a.currentHp.compareTo(b.currentHp));
        break;
      case TargetPriority.bossFirst:
        inRange.sort((a, b) {
          final isABoss = a.definition.type == EnemyType.boss;
          final isBBoss = b.definition.type == EnemyType.boss;
          if (isABoss && !isBBoss) return -1;
          if (!isABoss && isBBoss) return 1;
          return b.currentHp.compareTo(a.currentHp);
        });
        break;
    }

    currentTarget = inRange.first;
    _targetAimAngle = MathUtils.angleBetween(
      Offset(position.x, position.y),
      Offset(currentTarget!.position.x, currentTarget!.position.y),
    );
  }

  void _fireWeapon() {
    final baseSpeed = definition.attacksPerSecond;
    final speedMultiplier = game.gameManager.upgrades.attackSpeedMultiplier;
    final modeMultiplier = (game.gameManager.activeMode == GameMode.chaos)
        ? game.gameManager.activeChaosModifier.unitAttackSpeedMultiplier
        : 1.0;
    final finalRate = baseSpeed * speedMultiplier * modeMultiplier;
    _attackCooldown = 1.0 / max(0.2, finalRate);

    // Archetype-tailored kickback and muzzle flash (Clauses 740–743, 1078, 1079)
    switch (heroClass) {
      case HeroClass.rifleman:
        _muzzleFlashTimer = VisualFeedbackConfig.riflemanFlashDuration;
        _recoilDistance = 4.0;
        break;
      case HeroClass.shotgunner:
        _muzzleFlashTimer = VisualFeedbackConfig.shotgunnerFlashDuration;
        _recoilDistance = 7.5;
        break;
      case HeroClass.sniper:
        _muzzleFlashTimer = VisualFeedbackConfig.sniperFlashDuration;
        _recoilDistance = 11.0;
        break;
      case HeroClass.heavyGunner:
        _muzzleFlashTimer = VisualFeedbackConfig.heavyFlashDuration;
        _recoilDistance = 2.5;
        break;
    }

    AudioManager.instance.playUnitShoot();

    // Damage & critical calculation using centralized DamageCalculator (Clause 92)
    final resolution = DamageCalculator.calculate(
      baseDamage: definition.baseDamage,
      level: level,
      globalDamageMultiplier: game.gameManager.upgrades.damageMultiplier,
      critChance: definition.critChance + game.gameManager.upgrades.critChanceBonus,
      critMultiplier: definition.critMultiplier,
      targetType: currentTarget?.definition.type ?? EnemyType.basic,
      armorPiercingMultiplier: game.gameManager.upgrades.armorPiercingMultiplier,
    );

    // Ballistics
    final barrelOffset = Offset(
      position.x + cos(aimAngle) * 22,
      position.y + sin(aimAngle) * 22,
    );

    if (definition.projectileCount > 1) {
      // Shotgun spread cone
      final totalProjectiles = definition.projectileCount;
      final startAngle = aimAngle - (definition.spreadAngle / 2);
      final step = definition.spreadAngle / (totalProjectiles - 1);

      for (int i = 0; i < totalProjectiles; i++) {
        final angle = startAngle + (step * i);
        game.spawnBullet(
          BulletComponent(
            spawnPosition: Vector2(barrelOffset.dx, barrelOffset.dy),
            angle: angle,
            speed: definition.projectileSpeed,
            damage: resolution.damage,
            isCrit: resolution.isCrit,
            color: definition.themeColor,
            heroClass: heroClass,
          ),
        );
      }
    } else {
      // Single round
      game.spawnBullet(
        BulletComponent(
          spawnPosition: Vector2(barrelOffset.dx, barrelOffset.dy),
          angle: aimAngle,
          speed: definition.projectileSpeed,
          damage: resolution.damage,
          isCrit: resolution.isCrit,
          color: definition.themeColor,
          heroClass: heroClass,
        ),
      );
    }
  }

  // --- DRAG AND MERGE GESTURE HANDLERS ---
  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    isDragging = true;
    _isReturning = false;
    priority = 1000;
    scale.setAll(1.15); // Controlled juicy lift (Clause 756)
    _dragTargetPos = position.clone();
    _dragTilt = 0.0;

    // Clause 67: Highlight matching merge units on the field
    game.highlightMatchingUnits(heroClass, level, this);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!isDragging) return;
    _dragTargetPos += event.canvasDelta;

    // Inertial lean/tilt (Clause 757: 3–5 degrees opposite to drag direction)
    final tiltRad = (-event.canvasDelta.x * 0.04).clamp(
      -VisualFeedbackConfig.dragInertialTiltMaxDeg * pi / 180,
      VisualFeedbackConfig.dragInertialTiltMaxDeg * pi / 180,
    );
    _dragTilt = tiltRad;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (!isDragging) return;
    isDragging = false;

    // Clear highlights on field
    game.clearMatchingHighlights();

    // Reset slot hover highlights
    for (final s in game.defenseSlots) {
      s.highlightState = SlotHighlightState.none;
    }

    final targetSlot = _findBestSlotAt(position);

    if (targetSlot != null) {
      if (targetSlot == slot) {
        _snapBackToSlot();
      } else if (targetSlot.isEmpty) {
        // Move to empty slot
        slot.currentHero = null;
        slot = targetSlot;
        targetSlot.currentHero = this;
        _snapBackToSlot();
      } else {
        // Occupied slot -> Check merge condition
        final otherHero = targetSlot.currentHero!;
        if (otherHero.heroClass == heroClass && otherHero.level == level) {
          if (level < GameBalance.maxUnitLevel) {
            // Valid Merge!
            game.mergeUnits(sourceHero: this, targetHero: otherHero);
          } else {
            // Clause 69: MAX LEVEL reached! Disallow merge, show floating text
            game.add(
              DamageTextComponent(
                text: 'MAX LEVEL',
                position: targetSlot.position.clone()..y -= 25,
                isCrit: true,
              ),
            );
            _snapBackToSlot();
          }
        } else {
          // Incompatible unit or level -> ease return
          _snapBackToSlot();
        }
      }
    } else {
      _snapBackToSlot();
    }
  }

  void _updateSlotHoverStates() {
    final hoverSlot = _findBestSlotAt(position);

    for (final s in game.defenseSlots) {
      if (s == hoverSlot) {
        if (s == slot) {
          s.highlightState = SlotHighlightState.none;
        } else if (s.isEmpty) {
          s.highlightState = SlotHighlightState.validDrop;
        } else {
          final otherHero = s.currentHero!;
          if (otherHero.heroClass == heroClass &&
              otherHero.level == level &&
              level < GameBalance.maxUnitLevel) {
            s.highlightState = SlotHighlightState.validMerge;
          } else {
            s.highlightState = SlotHighlightState.invalidDrop;
          }
        }
      } else {
        s.highlightState = SlotHighlightState.none;
      }
    }
  }

  DefenseSlotComponent? _findBestSlotAt(Vector2 pos) {
    DefenseSlotComponent? best;
    double bestDist = 55.0; // Catchment radius

    for (final s in game.defenseSlots) {
      final d = (s.position - pos).length;
      if (d < bestDist) {
        bestDist = d;
        best = s;
      }
    }
    return best;
  }

  void _snapBackToSlot() {
    _isReturning = true;
    _returnElapsed = 0.0;
    _returnStartPos = position.clone();
  }

  /// Row-based visual scale per Clause 1061:
  /// back row (0): +20% (1.20)
  /// middle row (1): +28% (1.28)
  /// front row (2): +35% (1.35)
  double get visualRowScale {
    switch (slot.gridRow) {
      case 0:
        return 1.20;
      case 1:
        return 1.28;
      case 2:
        return 1.35;
      default:
        return 1.25;
    }
  }

  // --- 2.5D LOW-POLY RENDERING ---
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final w = size.x;
    final h = size.y;
    final rowScale = visualRowScale;

    // Idle breathing offset (Clause 736: 2–3px vertical movement)
    final idleBobY = isDragging
        ? 0.0
        : sin((_idleTimer / VisualFeedbackConfig.unitIdleBobDuration) * 2 * pi + _idlePhaseOffset) *
            VisualFeedbackConfig.unitIdleBobAmplitude;
    final elevY = isDragging ? -VisualFeedbackConfig.dragElevationY : 0.0;

    final unitDef = UnitArtAssets.definitions[heroClass];
    final bodyImg = (unitDef != null) ? ArtAssetManager.getImage(unitDef.bodyAsset) : null;
    final weaponImg = (unitDef != null) ? ArtAssetManager.getImage(unitDef.weaponAsset) : null;
    final accentImg = (unitDef != null) ? ArtAssetManager.getImage(unitDef.powerAccentAsset) : null;

    if (unitDef != null && bodyImg != null) {
      // 1. Separate contact shadow (Clause 897, 944–946)
      final shadowScale = isDragging ? 1.35 : 1.0;
      final shadowOpacity = isDragging ? 0.16 : 0.26;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, 10 + (isDragging ? 8.0 : 0.0)),
          width: unitDef.shadowSize.x * shadowScale * rowScale,
          height: unitDef.shadowSize.y * shadowScale * rowScale,
        ),
        Paint()..color = const Color(0xFF1A1D24).withValues(alpha: shadowOpacity),
      );

      // Merge candidate pulse
      if (isMergeCandidate && !isDragging) {
        final pulseRadius = 32.0 * rowScale + (sin(_candidatePulse).abs() * 5.0);
        final pulsePaint = Paint()
          ..color = GameColors.acidYellow
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5;
        canvas.drawCircle(const Offset(0, 0), pulseRadius, pulsePaint);
      }

      canvas.save();
      canvas.scale(rowScale);
      canvas.translate(0, idleBobY + elevY);
      if (_dragTilt != 0.0) {
        canvas.rotate(_dragTilt);
      }

      // 2. Pre-rendered Low-Poly Soldier Body (Clause 891: facing top of screen)
      final bodySrc = Rect.fromLTWH(0, 0, bodyImg.width.toDouble(), bodyImg.height.toDouble());
      final bodyDst = Rect.fromCenter(center: const Offset(0, -6), width: unitDef.bodySize.x, height: unitDef.bodySize.y);
      canvas.drawImageRect(bodyImg, bodySrc, bodyDst, Paint()..filterQuality = FilterQuality.medium);

      // 3. Power accent mask (Clause 927, 928)
      final accentAlpha = powerAccentOpacity;
      if (accentImg != null && accentAlpha > 0.0) {
        final accentSrc = Rect.fromLTWH(0, 0, accentImg.width.toDouble(), accentImg.height.toDouble());
        final accentPaint = Paint()
          ..filterQuality = FilterQuality.medium
          ..color = Colors.white.withValues(alpha: accentAlpha);
        canvas.drawImageRect(accentImg, accentSrc, bodyDst, accentPaint);
      }

      // 4. Weapon Sprite with Aim (-30° to +30°) and Recoil Kickback (Clause 920–924)
      if (weaponImg != null) {
        canvas.save();
        final sockX = unitDef.weaponSocketOffset.x;
        final sockY = unitDef.weaponSocketOffset.y;
        canvas.translate(sockX, sockY);

        final diffAngle = (aimAngle - (-pi / 2)).clamp(-0.55, 0.55);
        canvas.rotate(diffAngle);

        if (_recoilDistance > 0) {
          canvas.translate(0, _recoilDistance);
        }

        double wpnW = unitDef.bodySize.x * 0.55;
        double wpnH = unitDef.bodySize.y * 0.55;
        switch (heroClass) {
          case HeroClass.rifleman:
            wpnW = unitDef.bodySize.x * 0.52;
            wpnH = unitDef.bodySize.y * 0.56;
            break;
          case HeroClass.shotgunner:
            wpnW = unitDef.bodySize.x * 0.65;
            wpnH = unitDef.bodySize.y * 0.48;
            break;
          case HeroClass.sniper:
            wpnW = unitDef.bodySize.x * 0.42;
            wpnH = unitDef.bodySize.y * 0.72;
            break;
          case HeroClass.heavyGunner:
            wpnW = unitDef.bodySize.x * 0.70;
            wpnH = unitDef.bodySize.y * 0.64;
            break;
        }

        final wpnSrc = Rect.fromLTWH(0, 0, weaponImg.width.toDouble(), weaponImg.height.toDouble());
        final wpnDst = Rect.fromCenter(center: Offset.zero, width: wpnW, height: wpnH);
        canvas.drawImageRect(weaponImg, wpnSrc, wpnDst, Paint()..filterQuality = FilterQuality.medium);

        if (_muzzleFlashTimer > 0) {
          final flashCenter = Offset(unitDef.muzzleSocketOffset.x, unitDef.muzzleSocketOffset.y);
          _drawMuzzleStar(canvas, flashCenter);
        }

        canvas.restore();
      }

      // 5. Level & Tier Star Badge (Clause 929, 1064)
      _drawLevelBadge(canvas, w, h);

      canvas.restore();
    } else {
      // Drop shadow fallback
      final shadowScale = isDragging ? 1.35 : 1.0;
      IsometricHelper.drawDropShadow(
        canvas: canvas,
        center: Offset(0, h * 0.35 + (isDragging ? 8.0 : 0.0)),
        radiusX: (w * 0.42) * shadowScale * rowScale,
        radiusY: (h * 0.22) * shadowScale * rowScale,
        opacity: isDragging ? 0.20 : 0.28,
      );

      // Clause 67: Pulsing merge highlight contour when another identical unit is dragged
      if (isMergeCandidate && !isDragging) {
        final pulseRadius = (26.0 * rowScale) + (sin(_candidatePulse).abs() * 4.0);
        final pulsePaint = Paint()
          ..color = GameColors.acidYellow
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5;
        canvas.drawCircle(const Offset(0, 4), pulseRadius, pulsePaint);
      }

      // Wrap soldier & weapon in idle bob, drag elevation, and drag inertial tilt
      canvas.save();
      canvas.scale(rowScale);
      canvas.translate(0, idleBobY + elevY);
      if (_dragTilt != 0.0) {
        canvas.rotate(_dragTilt);
      }

      // Chunky Low-Poly Soldier Body
      _drawSoldier(canvas, w, h);

      // Aimed Weapon
      _drawWeapon(canvas, w, h);

      // Level & Tier Star Badge
      _drawLevelBadge(canvas, w, h);

      canvas.restore();
    }
  }

  void _drawSoldier(Canvas canvas, double w, double h) {
    // Torso / Body (faceted block)
    final bodyRect = Rect.fromCenter(center: const Offset(0, 4), width: 24, height: 26);
    final bodyRRect = RRect.fromRectAndRadius(bodyRect, const Radius.circular(5));

    final uniformPaint = Paint()..color = definition.themeColor;
    canvas.drawRRect(bodyRRect, uniformPaint);

    // Shading facet on torso
    final torsoShade = Path()
      ..moveTo(0, -9)
      ..lineTo(12, -9)
      ..lineTo(12, 17)
      ..lineTo(0, 17)
      ..close();
    canvas.drawPath(torsoShade, Paint()..color = Colors.black.withValues(alpha: 0.16));

    // Soldier Head (Faceted Chiseled Hexagon)
    final headCenter = const Offset(0, -14);
    _drawFacetedHead(canvas, headCenter);

    // Soldier Helmet / Cap / Level Visual Upgrades (Clause 66)
    _drawHeadgearAndArmor(canvas, headCenter);

    // Black Neo-Brutalist Contour
    final contourPaint = Paint()
      ..color = GameColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    canvas.drawRRect(bodyRRect, contourPaint);
  }

  void _drawFacetedHead(Canvas canvas, Offset center) {
    const r = 11.0;
    final pLeft = Path()
      ..moveTo(center.dx - r, center.dy)
      ..lineTo(center.dx, center.dy - r)
      ..lineTo(center.dx, center.dy + r)
      ..close();
    canvas.drawPath(pLeft, Paint()..color = GameColors.unitSkin);

    final pRight = Path()
      ..moveTo(center.dx, center.dy - r)
      ..lineTo(center.dx + r, center.dy)
      ..lineTo(center.dx, center.dy + r)
      ..close();
    canvas.drawPath(pRight, Paint()..color = GameColors.unitSkinShadow);

    // Head outline
    final headRect = Rect.fromCircle(center: center, radius: r);
    canvas.drawOval(
      headRect,
      Paint()
        ..color = GameColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  void _drawHeadgearAndArmor(Canvas canvas, Offset headCenter) {
    if (level == 1) {
      // L1: Cadet Cap
      final capPath = Path()
        ..moveTo(headCenter.dx - 12, headCenter.dy - 4)
        ..lineTo(headCenter.dx + 12, headCenter.dy - 4)
        ..lineTo(headCenter.dx + 4, headCenter.dy - 14)
        ..lineTo(headCenter.dx - 10, headCenter.dy - 12)
        ..close();
      canvas.drawPath(capPath, Paint()..color = GameColors.ink);
    } else if (level <= 3) {
      // L2-L3: Combat Helmet with Camo Trim
      final helmetRect = Rect.fromCenter(
        center: Offset(headCenter.dx, headCenter.dy - 4),
        width: 24,
        height: 16,
      );
      final helmetPaint = Paint()..color = const Color(0xFF334155);
      canvas.drawArc(helmetRect, pi, pi, true, helmetPaint);
      canvas.drawArc(
        helmetRect,
        pi,
        pi,
        true,
        Paint()
          ..color = GameColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );

      // Goggles
      final gogglePaint = Paint()..color = GameColors.acidYellow;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(headCenter.dx, headCenter.dy - 2), width: 14, height: 4),
        gogglePaint,
      );
    } else {
      // L4-L8: Cyber Visor & Heavy Armored Helmet
      final visorRect = Rect.fromCenter(
        center: Offset(headCenter.dx, headCenter.dy - 3),
        width: 18,
        height: 8,
      );
      canvas.drawRect(visorRect, Paint()..color = GameColors.techBlue);
      canvas.drawRect(
        visorRect,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      // Heavy Pauldrons (shoulder armor)
      final pauldronPaint = Paint()..color = GameColors.acidYellow;
      canvas.drawRect(const Rect.fromLTWH(-16, -2, 6, 12), pauldronPaint);
      canvas.drawRect(const Rect.fromLTWH(10, -2, 6, 12), pauldronPaint);
    }
  }

  void _drawWeapon(Canvas canvas, double w, double h) {
    canvas.save();
    canvas.translate(0, 4);
    canvas.rotate(aimAngle);

    // Weapon kickback (Clauses 739–743)
    if (_recoilDistance > 0) {
      canvas.translate(-_recoilDistance, 0);
    }

    // Gun barrel
    final gunLength = 16.0 + (level * 1.5);
    final gunWidth = 5.0 + (level > 4 ? 2.5 : 0.0);
    final gunRect = Rect.fromLTWH(4, -gunWidth / 2, gunLength, gunWidth);

    canvas.drawRect(gunRect, Paint()..color = GameColors.ink);

    // Level-up gold trim on weapon
    if (level >= 3) {
      final trimRect = Rect.fromLTWH(8, -gunWidth / 2, 4, gunWidth);
      canvas.drawRect(trimRect, Paint()..color = GameColors.acidYellow);
    }

    // Muzzle flash
    if (_muzzleFlashTimer > 0) {
      final flashCenter = Offset(gunLength + 8, 0);
      _drawMuzzleStar(canvas, flashCenter);
    }

    canvas.restore();
  }

  void _drawMuzzleStar(Canvas canvas, Offset center) {
    // Clause 1078: Archetype-specific muzzle flash geometry
    final flashPaint = Paint()..color = GameColors.muzzleFlash;
    final corePaint = Paint()..color = Colors.white;

    switch (heroClass) {
      case HeroClass.rifleman:
        // Balanced 5-point star
        final star = Path();
        const spikes = 5;
        const outerR = 14.0;
        const innerR = 5.5;
        for (int i = 0; i < spikes * 2; i++) {
          final r = (i % 2 == 0) ? outerR : innerR;
          final angle = (i * pi) / spikes;
          final x = center.dx + cos(angle) * r;
          final y = center.dy + sin(angle) * r;
          if (i == 0) {
            star.moveTo(x, y);
          } else {
            star.lineTo(x, y);
          }
        }
        star.close();
        canvas.drawPath(star, flashPaint);
        canvas.drawCircle(center, 4.0, corePaint);
        break;

      case HeroClass.shotgunner:
        // Wide fan blast
        final fan = Path()
          ..moveTo(center.dx - 12, center.dy)
          ..lineTo(center.dx - 16, center.dy - 16)
          ..lineTo(center.dx - 4, center.dy - 12)
          ..lineTo(center.dx, center.dy - 20)
          ..lineTo(center.dx + 4, center.dy - 12)
          ..lineTo(center.dx + 16, center.dy - 16)
          ..lineTo(center.dx + 12, center.dy)
          ..close();
        canvas.drawPath(fan, flashPaint);
        canvas.drawCircle(center, 5.0, corePaint);
        break;

      case HeroClass.sniper:
        // Long precision needle flash
        final needle = Path()
          ..moveTo(center.dx - 3, center.dy)
          ..lineTo(center.dx, center.dy - 24)
          ..lineTo(center.dx + 3, center.dy)
          ..lineTo(center.dx, center.dy + 4)
          ..close();
        canvas.drawPath(needle, flashPaint);
        canvas.drawCircle(center, 3.5, corePaint);
        break;

      case HeroClass.heavyGunner:
        // Compact rapid starburst
        final star = Path();
        const spikes = 4;
        const outerR = 10.0;
        const innerR = 4.0;
        for (int i = 0; i < spikes * 2; i++) {
          final r = (i % 2 == 0) ? outerR : innerR;
          final angle = (i * pi) / spikes;
          final x = center.dx + cos(angle) * r;
          final y = center.dy + sin(angle) * r;
          if (i == 0) {
            star.moveTo(x, y);
          } else {
            star.lineTo(x, y);
          }
        }
        star.close();
        canvas.drawPath(star, flashPaint);
        canvas.drawCircle(center, 3.0, corePaint);
        break;
    }
  }

  void _drawLevelBadge(Canvas canvas, double w, double h) {
    // Clause 1064: Compact military rank insignia pill, muted so it never overpowers the unit
    final badgeRect = Rect.fromCenter(center: Offset(0, h * 0.38), width: 22, height: 12);
    final badgeRRect = RRect.fromRectAndRadius(badgeRect, const Radius.circular(3));

    // Muted tactical border per tier
    Color tierBorder = Colors.white.withValues(alpha: 0.35);
    if (level >= 7) {
      tierBorder = GameColors.cyberPurple;
    } else if (level >= 5) {
      tierBorder = GameColors.acidYellow;
    } else if (level >= 3) {
      tierBorder = GameColors.electricLime;
    }

    // Tactical dark background
    final bgPaint = Paint()..color = const Color(0xDD0F172A);
    canvas.drawRRect(badgeRRect, bgPaint);

    final borderPaint = Paint()
      ..color = tierBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(badgeRRect, borderPaint);

    final textSpan = TextSpan(
      text: '★$level',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 8.0,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, h * 0.38 - textPainter.height / 2),
    );
  }
}
