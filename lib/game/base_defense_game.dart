import 'dart:math';
import 'package:flame/camera.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../constants/art_assets.dart';
import '../constants/game_config.dart';
import '../models/hero_data.dart';
import '../models/enemy_data.dart';
import '../models/game_mode_data.dart';
import '../managers/game_manager.dart';
import '../managers/camera_feedback_manager.dart';
import '../systems/save_system.dart';
import '../services/analytics_service.dart';
import '../components/arena_background_component.dart';
import '../components/base_component.dart';
import '../components/defense_slot_component.dart';
import '../components/hero_component.dart';
import '../components/enemy_component.dart';
import '../components/bullet_component.dart';
import '../components/vfx_component.dart';
import '../components/damage_text_component.dart';
import '../components/coin_component.dart';
import '../systems/merge_system.dart';
import '../systems/wave_system.dart';

/// The central FlameGame coordinating 2.5D rendering, entity simulation, and gestures.
class BaseDefenseGame extends FlameGame with DragCallbacks {
  final GameManager gameManager;

  late final ArenaBackgroundComponent background;
  late final BaseComponent baseBunker;
  late final MergeSystem mergeSystem;
  late final WaveSystem waveSystem;
  final CameraFeedbackManager cameraManager = CameraFeedbackManager();

  final List<DefenseSlotComponent> defenseSlots = [];
  final List<EnemyComponent> activeEnemies = [];
  final List<BulletComponent> activeBullets = [];

  final Random _random = Random();

  BaseDefenseGame({required this.gameManager})
      : super(
          camera: CameraComponent.withFixedResolution(
            width: GameConfig.virtualWidth,
            height: GameConfig.virtualHeight,
          ),
        );

  @override
  Color backgroundColor() => const Color(0xFF151515);

  bool get isBoardFull => defenseSlots.every((s) => !s.isEmpty);

  /// Checks if any two units on the board can be merged (Clause 165)
  bool get hasPossibleMerge {
    final heroes = defenseSlots.map((s) => s.currentHero).whereType<HeroComponent>().toList();
    for (int i = 0; i < heroes.length; i++) {
      for (int j = i + 1; j < heroes.length; j++) {
        if (heroes[i].heroClass == heroes[j].heroClass &&
            heroes[i].level == heroes[j].level &&
            heroes[i].level < 8) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Preload all pre-rendered low-poly 2.5D assets (Clause 1009)
    Flame.images.prefix = '';
    await ArtAssetManager.preloadAll();

    mergeSystem = MergeSystem(this);
    waveSystem = WaveSystem(this);
    gameManager.hasEmptySlotCheck = () => !isBoardFull;

    // 1. Battlefield ground and terrain props
    background = ArenaBackgroundComponent();
    world.add(background);

    // 2. Fortified Command Bunker at bottom
    baseBunker = BaseComponent();
    world.add(baseBunker);

    // 3. 3x3 Tactical Defense Grid (9 slots centered above bunker)
    _setupDefenseGrid();
  }

  void _setupDefenseGrid() {
    const gridCols = GameConfig.gridCols;
    const gridRows = GameConfig.gridRows;
    const slotW = GameConfig.slotWidth;
    const slotH = GameConfig.slotHeight;
    const spaceX = GameConfig.slotSpacingX;
    const spaceY = GameConfig.slotSpacingY;

    final totalGridW = (gridCols * slotW) + ((gridCols - 1) * spaceX);
    final startX = (GameConfig.virtualWidth - totalGridW) / 2 + (slotW / 2);
    const startY = 515.0; // Directly above bunker

    int index = 0;
    for (int r = 0; r < gridRows; r++) {
      for (int c = 0; c < gridCols; c++) {
        final posX = startX + c * (slotW + spaceX);
        final posY = startY + r * (slotH + spaceY);

        final slot = DefenseSlotComponent(
          slotIndex: index++,
          gridRow: r,
          gridCol: c,
          position: Vector2(posX, posY),
        );
        defenseSlots.add(slot);
        world.add(slot);
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Screen Shake update (Clauses 799–801)
    cameraManager.update(dt);
    final offset = cameraManager.currentOffset;
    camera.viewfinder.position = Vector2(
      GameConfig.virtualWidth / 2 + offset.x,
      GameConfig.virtualHeight / 2 + offset.y,
    );

    // Clean departed entities
    activeEnemies.removeWhere((e) => e.isDead || !e.isMounted);
    activeBullets.removeWhere((b) => !b.isMounted);

    // Wave progression update
    waveSystem.update(dt);

    // Coin counter interpolation in HUD
    gameManager.economy.updateCoinCounter(dt);
  }

  void triggerCameraShake(double intensity, double duration) {
    cameraManager.trigger(intensity: intensity, duration: duration);
  }

  void triggerCameraShakePreset(CameraShakePreset preset) {
    cameraManager.triggerPreset(preset);
  }

  /// Highlights all matching units on the field when a unit is dragged (Clause 67)
  void highlightMatchingUnits(HeroClass heroClass, int level, HeroComponent source) {
    for (final s in defenseSlots) {
      final h = s.currentHero;
      if (h != null && h != source && h.heroClass == heroClass && h.level == level) {
        h.isMergeCandidate = true;
      }
    }
  }

  /// Clears merge highlight outlines
  void clearMatchingHighlights() {
    for (final s in defenseSlots) {
      if (s.currentHero != null) {
        s.currentHero!.isMergeCandidate = false;
      }
    }
  }

  /// Buys and deploys a unit to the first open defense slot.
  /// Follows unlocked unit pool and weighted rolls (Clause 166).
  bool buyAndSpawnUnit({HeroClass? forceClass}) {
    // Find first vacant slot
    DefenseSlotComponent? openSlot;
    for (final s in defenseSlots) {
      if (s.isEmpty) {
        openSlot = s;
        break;
      }
    }

    if (openSlot == null) return false;

    // Check economy
    if (!gameManager.economy.canAffordUnit) return false;

    gameManager.economy.buyUnit();

    // Determine unit class based on unlocked progression pool (Clause 166)
    HeroClass chosenClass = forceClass ?? _rollUnlockedUnit();

    final def = HeroDefinition.registry[chosenClass]!;
    final hero = HeroComponent(
      definition: def,
      level: 1,
      slot: openSlot,
    );

    openSlot.currentHero = hero;
    openSlot.triggerSpawnRing();
    world.add(hero);

    AnalyticsService.instance.logUnitPurchased(chosenClass.name, gameManager.economy.lastUnitCost);

    // Check tutorial progression
    if (gameManager.tutorialStep == 1) {
      gameManager.advanceTutorialStep(2);
    } else if (gameManager.tutorialStep == 2) {
      gameManager.advanceTutorialStep(3);
    }

    return true;
  }

  HeroClass _rollUnlockedUnit() {
    return rollUnitWithRng(_random, SaveSystem.currentSave.unlockedHeroClasses);
  }

  /// Deterministic unit roll helper supporting reproducible testing & seeded RNG (Clauses 614, 618)
  static HeroClass rollUnitWithRng(Random rng, List<HeroClass> unlocked) {
    if (unlocked.isEmpty) return HeroClass.rifleman;
    if (unlocked.length == 1) return unlocked.first;

    final roll = rng.nextDouble();
    if (unlocked.length == 2) {
      // Clause 614: Rifleman 60%, Shotgunner 40%
      return (roll < 0.60) ? HeroClass.rifleman : HeroClass.shotgunner;
    } else if (unlocked.length == 3) {
      // Clause 614: Rifleman 45%, Shotgunner 30%, Sniper 25%
      if (roll < 0.45) return HeroClass.rifleman;
      if (roll < 0.75) return HeroClass.shotgunner;
      return HeroClass.sniper;
    } else {
      // Clause 614: Rifleman 40%, Shotgunner 25%, Heavy Gunner 20%, Sniper 15%
      if (roll < 0.40) return HeroClass.rifleman;
      if (roll < 0.65) return HeroClass.shotgunner;
      if (roll < 0.85) return HeroClass.heavyGunner;
      return HeroClass.sniper;
    }
  }

  /// Spawns a free unit (for debug or initial load)
  void debugAddUnit(HeroClass heroClass, int level) {
    DefenseSlotComponent? openSlot;
    for (final s in defenseSlots) {
      if (s.isEmpty) {
        openSlot = s;
        break;
      }
    }
    if (openSlot == null) return;

    final def = HeroDefinition.registry[heroClass]!;
    final hero = HeroComponent(
      definition: def,
      level: level,
      slot: openSlot,
    );
    openSlot.currentHero = hero;
    world.add(hero);
  }

  void mergeUnits({
    required HeroComponent sourceHero,
    required HeroComponent targetHero,
  }) {
    AnalyticsService.instance.logUnitMerged(targetHero.heroClass.name, targetHero.level + 1);
    mergeSystem.executeMerge(
      sourceHero: sourceHero,
      targetHero: targetHero,
    );
  }

  void addEnemy(EnemyComponent enemy) {
    activeEnemies.add(enemy);
    world.add(enemy);
  }

  void spawnBullet(BulletComponent bullet) {
    activeBullets.add(bullet);
    world.add(bullet);
  }

  /// Fully resets the arena for a fresh run, preventing lingering entities or leaks (Clause 103, 362–365, 406–407, 866–867).
  void resetGameForNewRun({GameMode? mode}) {
    AnalyticsService.instance.logRetryPressed();

    // Reset camera shake and viewfinder (Clause 866)
    cameraManager.reset();
    camera.viewfinder.position = Vector2(GameConfig.virtualWidth / 2, GameConfig.virtualHeight / 2);

    // 1. Remove all active bullets and enemies
    for (final e in activeEnemies) {
      e.removeFromParent();
    }
    activeEnemies.clear();

    for (final b in activeBullets) {
      b.removeFromParent();
    }
    activeBullets.clear();

    // Clean all lingering VFX, damage numbers, and coins (Clause 866)
    world.children.whereType<ImpactFlashVFXComponent>().forEach((c) => c.removeFromParent());
    world.children.whereType<DeathPuffVFXComponent>().forEach((c) => c.removeFromParent());
    world.children.whereType<MergeBurstVFXComponent>().forEach((c) => c.removeFromParent());
    world.children.whereType<ShockwaveVFXComponent>().forEach((c) => c.removeFromParent());
    world.children.whereType<DamageTextComponent>().forEach((c) => c.removeFromParent());
    world.children.whereType<CoinComponent>().forEach((c) => c.removeFromParent());

    // 2. Remove all heroes and clear slots
    for (final s in defenseSlots) {
      if (s.currentHero != null) {
        s.currentHero!.removeFromParent();
        s.currentHero = null;
      }
      s.highlightState = SlotHighlightState.none;
    }

    // 3. Reset systems
    waveSystem.reset();

    // 4. Start manager run with target mode
    final targetMode = mode ?? gameManager.activeMode;
    gameManager.startRun(mode: targetMode);

    // 5. Pre-deploy initial recruit unit for instant action if tutorial completed
    if (gameManager.tutorialStep == 0) {
      debugAddUnit(HeroClass.rifleman, 1);
    }
  }

  // --- DEBUG CHEATS (Clause 148) ---
  void debugKillAllEnemies() {
    for (final e in List<EnemyComponent>.from(activeEnemies)) {
      e.takeDamage(99999, true);
    }
  }

  void debugSpawnBoss() {
    final bossDef = EnemyDefinition.registry[EnemyType.boss]!;
    final boss = EnemyComponent(
      definition: bossDef,
      wave: gameManager.currentWave,
      laneIndex: 2,
      spawnPosition: Vector2(GameConfig.virtualWidth / 2, GameConfig.topSpawnY),
    );
    addEnemy(boss);
  }

  void debugClearUnits() {
    for (final s in defenseSlots) {
      if (s.currentHero != null) {
        s.currentHero!.removeFromParent();
        s.currentHero = null;
      }
    }
  }
}
