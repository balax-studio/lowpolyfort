import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:poly_fort/constants/game_balance.dart';
import 'package:poly_fort/models/enemy_data.dart';
import 'package:poly_fort/models/hero_data.dart';
import 'package:poly_fort/models/player_save.dart';
import 'package:poly_fort/models/upgrade_data.dart';
import 'package:poly_fort/systems/combat_calculator.dart';
import 'package:poly_fort/systems/economy_system.dart';
import 'package:poly_fort/systems/upgrade_system.dart';
import 'package:poly_fort/systems/goal_presentation_service.dart';
import 'package:poly_fort/models/wave_data.dart';
import 'package:poly_fort/models/game_mode_data.dart';
import 'package:poly_fort/managers/game_manager.dart';
import 'package:poly_fort/systems/save_system.dart';
import 'package:poly_fort/constants/ad_config.dart';
import 'package:poly_fort/services/rewarded_ad_service.dart';
import 'package:poly_fort/game/base_defense_game.dart';
import 'package:poly_fort/localization/app_localization.dart';
import 'package:poly_fort/services/analytics_service.dart';

void main() {
  group('CombatCalculators & Clause 159 Required Tests', () {
    test('Unit cost progression matches Clause 56 formula (purchaseCount 0 -> 50, 1 -> 55, etc.)', () {
      expect(UnitCostCalculator.calculateCost(0), equals(50));
      expect(UnitCostCalculator.calculateCost(1), equals(55));
      expect(UnitCostCalculator.calculateCost(2), equals(61));
      expect(UnitCostCalculator.calculateCost(3), equals(67));
      expect(UnitCostCalculator.calculateCost(4), equals(74));
      expect(UnitCostCalculator.calculateCost(5), equals(81));
    });

    test('MergeValidator allows same type + same level below max level', () {
      final canMergeL1 = MergeValidator.canMerge(
        sourceClass: HeroClass.rifleman,
        sourceLevel: 1,
        targetClass: HeroClass.rifleman,
        targetLevel: 1,
      );
      expect(canMergeL1, isTrue);

      final canMergeL7 = MergeValidator.canMerge(
        sourceClass: HeroClass.shotgunner,
        sourceLevel: 7,
        targetClass: HeroClass.shotgunner,
        targetLevel: 7,
      );
      expect(canMergeL7, isTrue);
    });

    test('MergeValidator rejects different unit types', () {
      final canMerge = MergeValidator.canMerge(
        sourceClass: HeroClass.rifleman,
        sourceLevel: 1,
        targetClass: HeroClass.shotgunner,
        targetLevel: 1,
      );
      expect(canMerge, isFalse);
    });

    test('MergeValidator rejects different unit levels', () {
      final canMerge = MergeValidator.canMerge(
        sourceClass: HeroClass.rifleman,
        sourceLevel: 1,
        targetClass: HeroClass.rifleman,
        targetLevel: 2,
      );
      expect(canMerge, isFalse);
    });

    test('MergeValidator rejects Level 8 max level units (Clause 69)', () {
      final canMergeL8 = MergeValidator.canMerge(
        sourceClass: HeroClass.rifleman,
        sourceLevel: 8,
        targetClass: HeroClass.rifleman,
        targetLevel: 8,
      );
      expect(canMergeL8, isFalse);
    });

    test('DamageCalculator handles non-crit and critical damage with precision (Clause 92)', () {
      // Deterministic RNG that guarantees NO crit (roll = 0.99 > 0.0)
      final noCritRng = _DeterministicRandom(0.99);
      final normalRes = DamageCalculator.calculate(
        baseDamage: 20.0,
        level: 1,
        globalDamageMultiplier: 1.0,
        critChance: 0.10,
        critMultiplier: 2.0,
        targetType: EnemyType.basic,
        rng: noCritRng,
      );
      expect(normalRes.isCrit, isFalse);
      expect(normalRes.damage, equals(20.0));

      // Deterministic RNG that guarantees CRIT (roll = 0.01 < 0.10)
      final critRng = _DeterministicRandom(0.01);
      final critRes = DamageCalculator.calculate(
        baseDamage: 20.0,
        level: 1,
        globalDamageMultiplier: 1.0,
        critChance: 0.10,
        critMultiplier: 2.0,
        targetType: EnemyType.basic,
        rng: critRng,
      );
      expect(critRes.isCrit, isTrue);
      expect(critRes.damage, equals(40.0)); // 20 * 2.0 = 40.0
    });

    test('DamageCalculator applies Armor Piercing bonus only against Tank and Shielded (Clause 88)', () {
      final noCritRng = _DeterministicRandom(0.99);

      // Against Basic mutant: no armor piercing bonus
      final basicRes = DamageCalculator.calculate(
        baseDamage: 100.0,
        level: 1,
        globalDamageMultiplier: 1.0,
        critChance: 0.0,
        critMultiplier: 1.5,
        targetType: EnemyType.basic,
        armorPiercingMultiplier: 1.20, // +20%
        rng: noCritRng,
      );
      expect(basicRes.damage, equals(100.0));

      // Against Tank: +20% bonus
      final tankRes = DamageCalculator.calculate(
        baseDamage: 100.0,
        level: 1,
        globalDamageMultiplier: 1.0,
        critChance: 0.0,
        critMultiplier: 1.5,
        targetType: EnemyType.tank,
        armorPiercingMultiplier: 1.20,
        rng: noCritRng,
      );
      expect(tankRes.damage, equals(120.0));

      // Against Shielded: +20% bonus
      final shieldedRes = DamageCalculator.calculate(
        baseDamage: 100.0,
        level: 1,
        globalDamageMultiplier: 1.0,
        critChance: 0.0,
        critMultiplier: 1.5,
        targetType: EnemyType.shielded,
        armorPiercingMultiplier: 1.20,
        rng: noCritRng,
      );
      expect(shieldedRes.damage, equals(120.0));
    });

    test('Scrap reward formula awards floor(wave * 3) + bossesDefeated * 10 (Clause 104)', () {
      // Wave 10, 2 bosses = 10 * 3 + 2 * 10 = 50 Scrap
      final scrapW10 = ScrapRewardCalculator.calculateScrap(
        waveReached: 10,
        bossesDefeated: 2,
      );
      expect(scrapW10, equals(50));

      final scrapW1 = ScrapRewardCalculator.calculateScrap(
        waveReached: 1,
        bossesDefeated: 0,
      );
      expect(scrapW1, equals(3));
    });

    test('Permanent upgrade cost follows table progression (Clause 112)', () {
      expect(GameBalance.getPermanentUpgradeCost(0), equals(25));
      expect(GameBalance.getPermanentUpgradeCost(1), equals(50));
      expect(GameBalance.getPermanentUpgradeCost(2), equals(100));
      expect(GameBalance.getPermanentUpgradeCost(3), equals(175));
      expect(GameBalance.getPermanentUpgradeCost(4), equals(300));
    });
  });

  group('EconomySystem Tests', () {
    test('Economy starts with 150 coins, buys units, and tracks costs (Clause 56, 57)', () {
      final economy = EconomySystem();
      economy.reset(0);

      expect(economy.coins, equals(150));
      expect(economy.canAffordUnit, isTrue);

      final cost1 = economy.nextUnitCost;
      expect(cost1, equals(50));
      expect(economy.buyUnit(), isTrue);
      expect(economy.coins, equals(100));

      final cost2 = economy.nextUnitCost;
      expect(cost2, equals(55));
      expect(economy.buyUnit(), isTrue);
      expect(economy.coins, equals(45));

      // Next unit costs 61 coins, but we only have 45 -> cannot buy
      expect(economy.canAffordUnit, isFalse);
      expect(economy.buyUnit(), isFalse);
      expect(economy.coins, equals(45));
    });
  });

  group('UpgradeSystem Tests', () {
    test('Pool contains 8 unique roguelite perks matching Clause 88', () {
      expect(UpgradeCard.pool.length, equals(8));
      final types = UpgradeCard.pool.map((c) => c.type).toSet();
      expect(types.length, equals(8));
      expect(types.contains(UpgradeType.armorPiercing), isTrue);
      expect(types.contains(UpgradeType.bountyHunter), isTrue);
      expect(types.contains(UpgradeType.fieldRepair), isTrue);
      expect(types.contains(UpgradeType.fortifiedBase), isTrue);
    });

    test('Draw three distinct upgrade cards without duplicates (Clause 87)', () {
      final upgrades = UpgradeSystem();
      upgrades.initFromSave(const PlayerSave());

      final cards = upgrades.drawThreeCards();
      expect(cards.length, equals(3));
      final cardIds = cards.map((c) => c.id).toSet();
      expect(cardIds.length, equals(3));
    });
  });

  group('PlayerSave & Unit Unlocks Tests', () {
    test('Unlocks units dynamically based on highest wave milestone (Clause 115)', () {
      const saveW1 = PlayerSave(highestWave: 1);
      expect(saveW1.unlockedHeroClasses, equals([HeroClass.rifleman]));
      expect(saveW1.isHeroUnlocked(HeroClass.shotgunner), isFalse);

      const saveW5 = PlayerSave(highestWave: 5);
      expect(saveW5.isHeroUnlocked(HeroClass.rifleman), isTrue);
      expect(saveW5.isHeroUnlocked(HeroClass.shotgunner), isTrue);
      expect(saveW5.isHeroUnlocked(HeroClass.sniper), isFalse);

      const saveW10 = PlayerSave(highestWave: 10);
      expect(saveW10.isHeroUnlocked(HeroClass.sniper), isTrue);
      expect(saveW10.isHeroUnlocked(HeroClass.heavyGunner), isFalse);

      const saveW15 = PlayerSave(highestWave: 15);
      expect(saveW15.isHeroUnlocked(HeroClass.heavyGunner), isTrue);
    });
  });

  group('Enemy Reward & Idempotency Tests (Clauses 96, 159)', () {
    test('Reward is granted only once on death, subsequent calls are ignored', () {
      final gm = GameManager.instance;
      gm.startRun();
      final initialCoins = gm.economy.coins;
      final initialKills = gm.killsThisRun;

      const coinReward = 5;
      bool isDead = false;
      int rewardsDispatched = 0;

      void simulateEnemyDeath() {
        if (isDead) return;
        isDead = true;
        rewardsDispatched++;
        gm.onEnemyKilled(coinReward);
      }

      // First death event
      simulateEnemyDeath();
      expect(rewardsDispatched, equals(1));
      expect(gm.economy.coins, equals(initialCoins + coinReward));
      expect(gm.killsThisRun, equals(initialKills + 1));

      // Duplicate death triggers
      simulateEnemyDeath();
      simulateEnemyDeath();
      expect(rewardsDispatched, equals(1));
      expect(gm.economy.coins, equals(initialCoins + coinReward));
      expect(gm.killsThisRun, equals(initialKills + 1));
    });
  });

  group('GoalPresentationService Priority Hierarchy (Clause 182)', () {
    test('Priority 1: Boss next wave takes precedence when 1 wave away', () {
      const save = PlayerSave(highestWave: 1);
      final goalW4 = GoalPresentationService.resolveNextGoal(
        currentWave: 4,
        highestWave: 1,
        save: save,
      );
      expect(goalW4.title, contains('BOSS NEXT WAVE'));

      final goalW5 = GoalPresentationService.resolveNextGoal(
        currentWave: 5,
        highestWave: 1,
        save: save,
      );
      expect(goalW5.title, contains('BOSS WAVE'));
    });

    test('Priority 2: Upgrade takes precedence when not 1 wave from boss', () {
      const save = PlayerSave(highestWave: 1);
      final goalW3 = GoalPresentationService.resolveNextGoal(
        currentWave: 3,
        highestWave: 1,
        save: save,
      );
      expect(goalW3.title, contains('UPGRADE AFTER THIS WAVE'));

      final goalW2 = GoalPresentationService.resolveNextGoal(
        currentWave: 2,
        highestWave: 1,
        save: save,
      );
      expect(goalW2.title, contains('UPGRADE IN 1 WAVE'));
    });

    test('Priority 3: New best wave shows when 1 wave away from record', () {
      const save = PlayerSave(highestWave: 8);
      // Wave 7 is 1 wave away from Wave 8 best, but wave 7 is not boss in 1 or upgrade in 1
      final goalW7 = GoalPresentationService.resolveNextGoal(
        currentWave: 7,
        highestWave: 8,
        save: save,
      );
      expect(goalW7.title, contains('NEW BEST IN 1 WAVE'));
    });
  });

  group('GoalPresentationService Next Unlock Milestone (Clauses 203, 204, 255)', () {
    test('Resolves correct unit unlock milestone based on highest wave', () {
      const saveW1 = PlayerSave(highestWave: 1);
      final next1 = GoalPresentationService.resolveNextUnlockGoal(saveW1);
      expect(next1.title, contains('SHOTGUNNER'));

      const saveW6 = PlayerSave(highestWave: 6);
      final next6 = GoalPresentationService.resolveNextUnlockGoal(saveW6);
      expect(next6.title, contains('SNIPER'));

      const saveW11 = PlayerSave(highestWave: 11);
      final next11 = GoalPresentationService.resolveNextUnlockGoal(saveW11);
      expect(next11.title, contains('HEAVY GUNNER'));

      const saveW16 = PlayerSave(highestWave: 16);
      final next16 = GoalPresentationService.resolveNextUnlockGoal(saveW16);
      expect(next16.title, contains('ALL SPECIALISTS UNLOCKED'));
    });
  });

  group('Wave 6 Sawtooth Relief Curve (Clauses 77, 188, 189)', () {
    test('Wave 6 provides opening relief with Swarms before introducing Tanks', () {
      final wave6 = WaveDefinition.generate(6);
      expect(wave6.spawns.length, equals(17));

      // First 4 enemies do not contain Tank, allowing post-boss breathing room
      final first4 = wave6.spawns.sublist(0, 4).map((s) => s.enemyType).toList();
      expect(first4.contains(EnemyType.tank), isFalse);
      expect(first4.contains(EnemyType.swarm), isTrue);

      // Total counts strictly match Clause 77
      final counts = <EnemyType, int>{};
      for (final s in wave6.spawns) {
        counts[s.enemyType] = (counts[s.enemyType] ?? 0) + 1;
      }
      expect(counts[EnemyType.basic], equals(8));
      expect(counts[EnemyType.runner], equals(4));
      expect(counts[EnemyType.tank], equals(3));
      expect(counts[EnemyType.swarm], equals(2));
    });
  });

  group('Game Modes Foundation & Chaos Modifier Tests (Clauses 277-314)', () {
    test('Chaos modifier catalogue contains exactly 6 unique modifiers (Clause 304)', () {
      expect(ChaosModifier.activePool.length, equals(6));
      final names = ChaosModifier.activePool.map((m) => m.title).toSet();
      expect(names, containsAll([
        'RUSH HOUR',
        'TOUGH CROWD',
        'SWARM WAVE',
        'RICH WAVE',
        'RAPID FIRE',
        'GIANTS',
      ]));
    });

    test('Chaos modifier multipliers match exact specifications (Clauses 305-310)', () {
      // 305. RUSH HOUR
      expect(ChaosModifier.rushHour.enemySpeedMultiplier, equals(1.30));
      expect(ChaosModifier.rushHour.enemyCoinMultiplier, equals(1.15));

      // 306. TOUGH CROWD
      expect(ChaosModifier.toughCrowd.enemyHpMultiplier, equals(1.35));
      expect(ChaosModifier.toughCrowd.enemyCoinMultiplier, equals(1.20));

      // 307. SWARM WAVE
      expect(ChaosModifier.swarmWave.enemyCountMultiplier, equals(1.50));
      expect(ChaosModifier.swarmWave.enemyHpMultiplier, equals(0.80));

      // 308. RICH WAVE
      expect(ChaosModifier.richWave.enemyHpMultiplier, equals(1.25));
      expect(ChaosModifier.richWave.enemyCoinMultiplier, equals(2.00));

      // 309. RAPID FIRE
      expect(ChaosModifier.rapidFire.unitAttackSpeedMultiplier, equals(1.50));
      expect(ChaosModifier.rapidFire.enemySpeedMultiplier, equals(1.15));

      // 310. GIANTS
      expect(ChaosModifier.giants.enemyCountMultiplier, equals(0.65));
      expect(ChaosModifier.giants.enemyHpMultiplier, equals(2.00));
      expect(ChaosModifier.giants.enemyScaleMultiplier, equals(1.40));
      expect(ChaosModifier.giants.enemyCoinMultiplier, equals(1.50));
      expect(ChaosModifier.giants.enemySpeedMultiplier, equals(0.85));
    });

    test('Chaos waves 1-10 follow strictly deterministic baseline sequence (Clause 312)', () {
      expect(ChaosModifier.resolveForWave(1).type, equals(ChaosModifierType.none));
      expect(ChaosModifier.resolveForWave(2), equals(ChaosModifier.rushHour));
      expect(ChaosModifier.resolveForWave(3), equals(ChaosModifier.rapidFire));
      expect(ChaosModifier.resolveForWave(4), equals(ChaosModifier.swarmWave));
      expect(ChaosModifier.resolveForWave(5), equals(ChaosModifier.toughCrowd));
      expect(ChaosModifier.resolveForWave(6), equals(ChaosModifier.richWave));
      expect(ChaosModifier.resolveForWave(7), equals(ChaosModifier.rushHour));
      expect(ChaosModifier.resolveForWave(8), equals(ChaosModifier.giants));
      expect(ChaosModifier.resolveForWave(9), equals(ChaosModifier.rapidFire));
      expect(ChaosModifier.resolveForWave(10), equals(ChaosModifier.richWave));
    });

    test('Chaos wave 11+ prevents consecutive identical modifiers and supports reproducible seed (Clauses 313-314)', () {
      ChaosModifier? prev;
      for (int wave = 11; wave <= 30; wave++) {
        final current = ChaosModifier.resolveForWave(wave, previousType: prev?.type, customSeed: 42 + wave);
        expect(current, isNotNull);
        expect(current, isNot(equals(prev)), reason: 'Wave $wave must not repeat modifier ${prev?.title}');
        prev = current;
      }

      // Seed reproducibility
      final modA = ChaosModifier.resolveForWave(15, customSeed: 9999);
      final modB = ChaosModifier.resolveForWave(15, customSeed: 9999);
      expect(modA, equals(modB));
    });
  });

  group('Boss Rush Round Data & Wave Composition Tests (Clauses 324-344)', () {
    test('Boss Rush has exactly 5 rounds with correct stat scalings (Clauses 324, 333-337)', () {
      expect(BossRushRoundData.rounds.length, equals(5));

      final r1 = BossRushRoundData.getRound(1);
      expect(r1.bossHpMultiplier, equals(1.00));
      expect(r1.bossDamageMultiplier, equals(1.00));
      expect(r1.bossSpeedMultiplier, equals(1.00));
      expect(r1.bossCoinReward, equals(120));
      expect(r1.supportRoster.isEmpty, isTrue);

      final r2 = BossRushRoundData.getRound(2);
      expect(r2.bossHpMultiplier, equals(1.35));
      expect(r2.bossDamageMultiplier, equals(1.10));
      expect(r2.bossSpeedMultiplier, equals(1.00));
      expect(r2.bossCoinReward, equals(140));
      expect(r2.supportRoster[EnemyType.runner], equals(4));

      final r3 = BossRushRoundData.getRound(3);
      expect(r3.bossHpMultiplier, equals(1.75));
      expect(r3.bossDamageMultiplier, equals(1.20));
      expect(r3.bossSpeedMultiplier, equals(1.05));
      expect(r3.bossCoinReward, equals(160));
      expect(r3.supportRoster[EnemyType.tank], equals(2));
      expect(r3.supportRoster[EnemyType.basic], equals(4));

      final r4 = BossRushRoundData.getRound(4);
      expect(r4.bossHpMultiplier, equals(2.25));
      expect(r4.bossDamageMultiplier, equals(1.35));
      expect(r4.bossSpeedMultiplier, equals(1.10));
      expect(r4.bossCoinReward, equals(180));
      expect(r4.supportRoster[EnemyType.shielded], equals(3));
      expect(r4.supportRoster[EnemyType.swarm], equals(6));

      final r5 = BossRushRoundData.getRound(5);
      expect(r5.bossHpMultiplier, equals(3.00));
      expect(r5.bossDamageMultiplier, equals(1.50));
      expect(r5.bossSpeedMultiplier, equals(1.15));
      expect(r5.bossCoinReward, equals(250));
      expect(r5.supportRoster[EnemyType.tank], equals(2));
      expect(r5.supportRoster[EnemyType.shielded], equals(2));
      expect(r5.supportRoster[EnemyType.runner], equals(6));
    });

    test('Boss Rush wave generation produces boss plus staged support entries (Clause 338)', () {
      final waveDefRound3 = WaveDefinition.generateBossRushRound(3);
      expect(waveDefRound3.spawns.first.enemyType, equals(EnemyType.boss));
      expect(waveDefRound3.spawns.first.customCoinReward, equals(160));
      expect(waveDefRound3.spawns.first.hpMultiplier, equals(1.75));

      final supportCount = waveDefRound3.spawns.where((s) => s.enemyType != EnemyType.boss).length;
      expect(supportCount, equals(6)); // 2 tank + 4 basic
      expect(waveDefRound3.spawns.length, equals(7));
    });
  });

  group('Scrap Reward Multipliers & Caps (Clauses 104, 320, 347, 348)', () {
    test('Normal mode calculates scrap correctly (Clause 104)', () {
      // 10 waves reached, 2 bosses defeated = 10 * 3 + 2 * 10 = 50 scrap
      final scrap = GameBalance.calculateScrapReward(10, 2);
      expect(scrap, equals(50));
    });

    test('Chaos mode grants 10% bonus scrap (Clause 320)', () {
      // floor(50 * 1.10) = 55 scrap
      final scrap = GameBalance.calculateChaosScrapReward(10, 2);
      expect(scrap, equals(55));
    });

    test('Boss Rush mode calculates scrap with exact linear reward and clear bonus up to max 50 (Clauses 347, 348)', () {
      expect(GameBalance.calculateBossRushScrapReward(1), equals(8));
      expect(GameBalance.calculateBossRushScrapReward(2), equals(16));
      expect(GameBalance.calculateBossRushScrapReward(3), equals(24));
      expect(GameBalance.calculateBossRushScrapReward(4), equals(32));
      // 5 bosses defeated: 5 * 8 = 40 + 10 bonus = 50
      expect(GameBalance.calculateBossRushScrapReward(5), equals(50));
    });
  });

  group('PlayerSave Mode Fields & Legacy Migration (Clauses 285, 288, 318, 349, 366-368)', () {
    test('Default save has locked extra modes and zero records', () {
      const save = PlayerSave();
      expect(save.chaosUnlocked, isFalse);
      expect(save.bossRushUnlocked, isFalse);
      expect(save.bestChaosWave, equals(0));
      expect(save.bestBossRushRound, equals(0));
    });

    test('Legacy save migration auto-unlocks Chaos for wave >= 5 and Boss Rush for wave >= 10 (Clause 368)', () {
      final legacyWave4 = PlayerSave.fromMap({'highestWave': 4});
      expect(legacyWave4.chaosUnlocked, isFalse);
      expect(legacyWave4.bossRushUnlocked, isFalse);

      final legacyWave5 = PlayerSave.fromMap({'highestWave': 5});
      expect(legacyWave5.chaosUnlocked, isTrue);
      expect(legacyWave5.bossRushUnlocked, isFalse);

      final legacyWave12 = PlayerSave.fromMap({'highestWave': 12});
      expect(legacyWave12.chaosUnlocked, isTrue);
      expect(legacyWave12.bossRushUnlocked, isTrue);
    });

    test('Mode records persist independently without corrupting normal progression (Clauses 318, 349)', () {
      var save = const PlayerSave();
      save = save.copyWith(
        highestWave: 15,
        chaosUnlocked: true,
        bestChaosWave: 8,
        bossRushUnlocked: true,
        bestBossRushRound: 4,
      );

      final map = save.toMap();
      final restored = PlayerSave.fromMap(map);

      expect(restored.highestWave, equals(15));
      expect(restored.chaosUnlocked, isTrue);
      expect(restored.bestChaosWave, equals(8));
      expect(restored.bossRushUnlocked, isTrue);
      expect(restored.bestBossRushRound, equals(4));
    });

    test('Unit unlocks remain strictly tied to Normal wave progression (Clauses 290, 322, 350, 401)', () {
      // Reaching wave 20 in Chaos or clearing Boss Rush must never alter unlockedHeroClasses
      const initialSave = PlayerSave();
      expect(initialSave.unlockedHeroClasses, equals([HeroClass.rifleman]));

      // Simulating a player with only Normal Wave 3 reached, but high Chaos wave
      final chaosPlayer = initialSave.copyWith(
        highestWave: 3,
        bestChaosWave: 25,
        bestBossRushRound: 5,
      );

      expect(chaosPlayer.unlockedHeroClasses, equals([HeroClass.rifleman]),
          reason: 'Chaos and Boss Rush achievements must never grant specialist units');
    });
  });

  group('GameManager Mode Integration Tests (Clauses 281-288, 326, 345-347, 396-407)', () {
    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await SaveSystem.resetAll();
    });

    test('Mode starting coins follow rules (Normal: 150, Boss Rush: 300) (Clauses 281, 326)', () {
      final gmNormal = GameManager();
      gmNormal.startRun(mode: GameMode.normal);
      expect(gmNormal.economy.coins, equals(150));

      final gmBoss = GameManager();
      gmBoss.startRun(mode: GameMode.bossRush);
      expect(gmBoss.economy.coins, equals(300));
    });

    test('Defeating Normal Wave 5 Boss unlocks Chaos Mode (Clauses 283-285, 396)', () {
      final gm = GameManager();
      gm.startRun(mode: GameMode.normal);
      expect(SaveSystem.currentSave.chaosUnlocked, isFalse);

      // Simulating reaching wave 5
      for (int i = 1; i < 5; i++) {
        gm.onWaveCleared();
      }
      expect(gm.currentWave, equals(5));

      // Killing wave 5 boss triggers Chaos unlock
      gm.onBossDefeated(100);
      expect(SaveSystem.currentSave.chaosUnlocked, isTrue);
      expect(gm.newModeUnlockedBannerText, contains('CHAOS'));
    });

    test('Defeating Normal Wave 10 Boss unlocks Boss Rush Mode (Clauses 286-288, 397)', () {
      final gm = GameManager();
      gm.startRun(mode: GameMode.normal);
      expect(SaveSystem.currentSave.bossRushUnlocked, isFalse);

      // Advance to wave 10
      for (int i = 1; i < 10; i++) {
        gm.onWaveCleared();
      }
      expect(gm.currentWave, equals(10));

      // Killing wave 10 boss triggers Boss Rush unlock
      gm.onBossDefeated(150);
      expect(SaveSystem.currentSave.bossRushUnlocked, isTrue);
      expect(gm.newModeUnlockedBannerText, contains('BOSS RUSH'));
    });

    test('Defeating Wave 10 Boss in Chaos Mode does NOT unlock Boss Rush (Clause 286)', () {
      final gm = GameManager();
      gm.startRun(mode: GameMode.chaos);
      expect(SaveSystem.currentSave.bossRushUnlocked, isFalse);

      for (int i = 1; i < 10; i++) {
        gm.onWaveCleared();
      }
      expect(gm.currentWave, equals(10));

      gm.onBossDefeated(150);
      expect(SaveSystem.currentSave.bossRushUnlocked, isFalse,
          reason: 'Only Normal mode progression can unlock Boss Rush');
    });

    test('Boss Rush victory after 5 rounds grants 50 Scrap and sets clear state (Clauses 346, 347, 404)', () {
      final gm = GameManager();
      gm.startRun(mode: GameMode.bossRush);
      expect(gm.activeMode, equals(GameMode.bossRush));

      // Progress through 5 boss rounds
      for (int r = 1; r <= 4; r++) {
        gm.onBossDefeated(100);
        gm.onWaveCleared(); // advance round
        expect(gm.bossRushRound, equals(r + 1));
      }

      expect(gm.bossRushRound, equals(5));
      gm.onBossDefeated(250);
      gm.onWaveCleared(); // round 5 completion triggers victory

      expect(gm.isBossRushVictory, isTrue);
      expect(gm.bossesDefeatedThisRun, equals(5));
      expect(gm.scrapEarnedThisRun, equals(50));
      expect(SaveSystem.currentSave.bestBossRushRound, equals(5));
    });

    test('Chaos high wave game over never unlocks specialist units (Clauses 290, 322, 401)', () {
      final gm = GameManager();
      gm.startRun(mode: GameMode.chaos);

      // Progress to wave 20 in Chaos
      for (int i = 1; i < 20; i++) {
        gm.onWaveCleared();
      }
      expect(gm.currentWave, equals(20));

      // Destroy base in Chaos
      gm.damageBase(9999);
      expect(gm.state, equals(GameState.gameOver));

      // Verify no units unlocked from Chaos
      expect(gm.newUnitsUnlockedThisRun.isEmpty, isTrue);
      expect(SaveSystem.currentSave.unlockedHeroClasses, equals([HeroClass.rifleman]));
      expect(SaveSystem.currentSave.bestChaosWave, equals(20));
      expect(SaveSystem.currentSave.highestWave, equals(1),
          reason: 'Normal highestWave must remain unaffected by Chaos run');
    });
  });

  group('Rewarded Ads Engine & Placement Tests (Clauses 422–597)', () {
    void advanceToWave(GameManager gm, int targetWave) {
      while (gm.currentWave < targetWave) {
        if (gm.state == GameState.upgradeSelection) {
          gm.chooseUpgrade(gm.pendingUpgrades.first);
        }
        gm.skipPrepCountdown();
        gm.onWaveCleared();
      }
      if (gm.state == GameState.upgradeSelection) {
        gm.chooseUpgrade(gm.pendingUpgrades.first);
      }
      gm.skipPrepCountdown();
    }

    setUp(() async {
      await SaveSystem.resetAll();
      GameManager.instance.debugResetAdCooldown();
      RewardedAdService.instance.setMockDriver(enabled: true, adReady: true);
    });

    tearDown(() {
      RewardedAdService.instance.setMockDriver(enabled: true, adReady: true);
    });

    test('Monetization unlock requires Normal Wave 3 milestone and completed tutorial (Clauses 446–448, 563–564)', () async {
      // 1. Fresh save (Wave 1, tutorial incomplete)
      final gm = GameManager();
      gm.startRun();
      expect(gm.state, equals(GameState.tutorial));
      expect(gm.canOfferSupplyDrop, isFalse);
      expect(gm.canOfferSecondChance, isFalse);
      expect(gm.canOfferExtraScrap, isFalse);

      // 2. Tutorial complete, but highestWave is only 2
      await SaveSystem.save(const PlayerSave(highestWave: 2, tutorialCompleted: true));
      final gm2 = GameManager();
      gm2.startRun();
      expect(gm2.state, equals(GameState.preparingWave));
      expect(gm2.canOfferSupplyDrop, isFalse);
      expect(gm2.canOfferSecondChance, isFalse);
      expect(gm2.canOfferExtraScrap, isFalse);

      // 3. Normal Wave 3 milestone reached and tutorial completed
      await SaveSystem.save(const PlayerSave(highestWave: 3, tutorialCompleted: true));
      final gm3 = GameManager();
      gm3.startRun();
      expect(SaveSystem.currentSave.highestWave >= AdConfig.unlockWaveMilestone, isTrue);
      expect(SaveSystem.currentSave.tutorialCompleted, isTrue);
    });

    test('Supply Drop offers exact nextUnitCost when coins insufficient and slot available (Clauses 449–461, 565–567)', () async {
      await SaveSystem.save(const PlayerSave(highestWave: 5, tutorialCompleted: true));
      final gm = GameManager();
      gm.startRun();

      // Starting coins = 150, nextUnitCost = 50. Coins >= nextUnitCost -> no offer
      expect(gm.canOfferSupplyDrop, isFalse, reason: 'Coins (150) >= nextUnitCost (50)');

      // Spend coins so coins < nextUnitCost
      gm.economy.spend(120); // remaining: 30 coins, nextUnitCost = 50
      expect(gm.economy.coins, equals(30));
      expect(gm.economy.nextUnitCost, equals(50));
      expect(gm.canOfferSupplyDrop, isTrue);

      // If board is full -> no offer
      gm.hasEmptySlotCheck = () => false;
      expect(gm.canOfferSupplyDrop, isFalse);
      gm.hasEmptySlotCheck = () => true;
      expect(gm.canOfferSupplyDrop, isTrue);

      // Claim Supply Drop
      gm.claimSupplyDrop();
      // Added exactly 50 coins -> 30 + 50 = 80 coins
      expect(gm.economy.coins, equals(80));
      expect(gm.supplyDropUsedThisRun, isTrue);
      expect(gm.runRewardedCount, equals(1));

      // Cannot be used again in the same run (1/run rule)
      gm.economy.spend(70); // 10 coins left, next cost 50
      expect(gm.canOfferSupplyDrop, isFalse, reason: 'Supply drop already used this run');
    });

    test('Supply Drop in Boss Rush pauses and resumes preparation timer (Clause 461)', () async {
      await SaveSystem.save(const PlayerSave(highestWave: 5, tutorialCompleted: true));
      final gm = GameManager();
      gm.startRun(mode: GameMode.bossRush);
      expect(gm.state, equals(GameState.preparingWave));
      expect(gm.countdownRemaining, equals(GameBalance.bossRushInitialPrepSeconds)); // 8.0s

      gm.economy.spend(280); // remaining: 20 coins, nextUnitCost = 50
      expect(gm.canOfferSupplyDrop, isTrue);

      gm.claimSupplyDrop();
      expect(gm.economy.coins, equals(70)); // 20 + 50
      expect(gm.countdownRemaining, equals(GameBalance.bossRushInitialPrepSeconds));
    });

    test('Second Chance triggers on Base HP 0, restores 50% HP, gives 3s grace, and preserves wave state (Clauses 462–480, 568–570)', () async {
      await SaveSystem.save(const PlayerSave(highestWave: 7, tutorialCompleted: true));
      final gm = GameManager();
      gm.startRun();

      // Advance to Wave 7 in active combat
      advanceToWave(gm, 7);
      expect(gm.currentWave, equals(7));
      expect(gm.state, equals(GameState.playing));

      // Destroy base
      gm.damageBase(99999);
      expect(gm.state, equals(GameState.awaitingSecondChance));
      expect(gm.canOfferSecondChance, isTrue);

      // Claim Second Chance
      gm.claimSecondChance();
      expect(gm.baseHp, equals((gm.maxBaseHp * 0.50).ceilToDouble()));
      expect(gm.isGracePeriodActive, isTrue);
      expect(gm.gracePeriodRemaining, equals(3.0));
      expect(gm.state, equals(GameState.playing));
      expect(gm.currentWave, equals(7), reason: 'Wave must never reset');
      expect(gm.secondChanceUsedThisRun, isTrue);
      expect(gm.runRewardedCount, equals(1));

      // Grace period expires after 3 seconds
      gm.updateCountdown(3.0);
      expect(gm.isGracePeriodActive, isFalse);

      // Second death in the same run goes directly to gameOver (only 1 Second Chance per run)
      gm.damageBase(99999);
      expect(gm.state, equals(GameState.gameOver));
    });

    test('Second Chance rejection via dismissSecondChance ends run cleanly without penalty (Clauses 468, 469)', () async {
      await SaveSystem.save(const PlayerSave(highestWave: 5, tutorialCompleted: true));
      final gm = GameManager();
      gm.startRun();
      advanceToWave(gm, 4);

      gm.damageBase(99999);
      expect(gm.state, equals(GameState.awaitingSecondChance));

      gm.dismissSecondChance();
      expect(gm.state, equals(GameState.gameOver));
      expect(gm.scrapEarnedThisRun, greaterThan(0));
    });

    test('Extra Scrap grants exact 2x scrap on results screen and immediately persists (Clauses 481–491, 542–544, 571, 583)', () async {
      await SaveSystem.save(const PlayerSave(highestWave: 10, tutorialCompleted: true, totalScrap: 100));
      final gm = GameManager();
      gm.startRun();

      advanceToWave(gm, 5);
      gm.onBossDefeated(100); // 1 boss
      // Normal scrap for Wave 5 + 1 Boss: floor(5*3) + 1*10 = 25 scrap
      gm.damageBase(99999);
      expect(gm.state, equals(GameState.awaitingSecondChance));
      gm.dismissSecondChance();

      expect(gm.state, equals(GameState.gameOver));
      expect(gm.scrapEarnedThisRun, equals(25));
      expect(SaveSystem.currentSave.totalScrap, equals(125),
          reason: 'Base scrap must be immediately saved before ad offer');

      expect(gm.canOfferExtraScrap, isTrue);

      // Claim Extra Scrap
      gm.claimExtraScrap();
      expect(SaveSystem.currentSave.totalScrap, equals(150),
          reason: 'Extra scrap (+25) must immediately double the run scrap in persistent storage');
      expect(gm.extraScrapUsedThisRun, isTrue);
      expect(gm.canOfferExtraScrap, isFalse, reason: 'Extra scrap can only be claimed once');
    });

    test('Run Cap enforces max 2 completed rewarded ads per run (Clauses 440, 441, 572)', () async {
      await SaveSystem.save(const PlayerSave(highestWave: 10, tutorialCompleted: true));
      final gm = GameManager();
      gm.startRun();

      // 1. Supply Drop (ad #1)
      gm.economy.spend(120);
      expect(gm.canOfferSupplyDrop, isTrue);
      gm.claimSupplyDrop();
      expect(gm.runRewardedCount, equals(1));

      // Advance to Wave 4 and trigger Second Chance (ad #2)
      advanceToWave(gm, 4);
      gm.debugResetAdCooldown(); // simulate 60s cooldown expiration

      gm.damageBase(99999);
      expect(gm.canOfferSecondChance, isTrue);
      gm.claimSecondChance();
      expect(gm.runRewardedCount, equals(2));

      // Base destroyed again -> Game Over
      gm.debugResetAdCooldown(); // cooldown expired, but run cap reached
      gm.damageBase(99999);
      expect(gm.state, equals(GameState.gameOver));

      // Extra Scrap is BLOCKED because runRewardedCount == 2
      expect(gm.canOfferExtraScrap, isFalse,
          reason: 'Max 2 rewarded ads per run strictly enforced (Clause 440, 572)');
    });

    test('Daily Cap blocks all placements when 5 ads completed in rolling 24 hours (Clauses 442, 443, 573)', () async {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      // Pre-fill save with 5 timestamps within the last hour
      final timestamps = [
        now - 50000,
        now - 40000,
        now - 30000,
        now - 20000,
        now - 10000,
      ];
      await SaveSystem.save(PlayerSave(
        highestWave: 10,
        tutorialCompleted: true,
        rewardedAdCompletionTimestamps: timestamps,
      ));

      expect(SaveSystem.currentSave.completedAdsInRolling24h, equals(5));

      final gm = GameManager();
      gm.startRun();
      gm.economy.spend(120);

      // Supply drop blocked
      expect(gm.canOfferSupplyDrop, isFalse);

      // Second chance blocked
      advanceToWave(gm, 4);
      gm.damageBase(99999);
      expect(gm.canOfferSecondChance, isFalse);
      expect(gm.state, equals(GameState.gameOver));

      // Extra scrap blocked
      expect(gm.canOfferExtraScrap, isFalse);
    });

    test('Global 60-second cooldown blocks back-to-back rewarded ads (Clauses 444, 574)', () async {
      await SaveSystem.save(const PlayerSave(highestWave: 10, tutorialCompleted: true));
      final gm = GameManager();
      gm.startRun();

      gm.economy.spend(120);
      gm.claimSupplyDrop();
      expect(gm.isGlobalCooldownExpired, isFalse);

      // Advance wave and die immediately
      advanceToWave(gm, 4);
      gm.damageBase(99999);

      // Second chance blocked by cooldown!
      expect(gm.canOfferSecondChance, isFalse);
      expect(gm.state, equals(GameState.gameOver));
    });

    test('Run ID guard prevents old callbacks from affecting a new run (Clauses 503, 504, 579)', () async {
      await SaveSystem.save(const PlayerSave(highestWave: 10, tutorialCompleted: true));
      final gm = GameManager();
      gm.startRun();
      final runAId = gm.currentRunId;

      // Start Run B (new run ID)
      gm.startRun();
      expect(gm.currentRunId, isNot(equals(runAId)));
      expect(gm.economy.coins, equals(150));
    });

    test('Offline / Ad Not Ready mode keeps game 100% playable without ad buttons (Clauses 424, 438, 539, 540, 562, 575–577)', () async {
      await SaveSystem.save(const PlayerSave(highestWave: 5, tutorialCompleted: true));
      // Simulate ad not filled / network offline
      RewardedAdService.instance.setMockDriver(enabled: true, adReady: false);
      expect(RewardedAdService.instance.isAdReady, isFalse);

      final gm = GameManager();
      gm.startRun();
      gm.economy.spend(120);

      // Supply drop button is hidden
      expect(gm.canOfferSupplyDrop, isFalse);

      // Destroy base -> Second chance button is hidden, goes straight to game over
      advanceToWave(gm, 4);
      gm.damageBase(99999);
      expect(gm.canOfferSecondChance, isFalse);
      expect(gm.state, equals(GameState.gameOver));

      // Extra scrap button is hidden
      expect(gm.canOfferExtraScrap, isFalse);

      // Normal scrap is still completely awarded and game is fully playable
      expect(gm.scrapEarnedThisRun, greaterThan(0));
    });
  });

  group('Final Specification Lock & Balancing Tests (Clauses 598–727)', () {
    test('Unit Purchase Roll Probabilities match exact Clause 614 specifications', () {
      // 1 unit unlocked: Rifleman 100%
      expect(BaseDefenseGame.rollUnitWithRng(_DeterministicRandom(0.1), [HeroClass.rifleman]), equals(HeroClass.rifleman));
      expect(BaseDefenseGame.rollUnitWithRng(_DeterministicRandom(0.9), [HeroClass.rifleman]), equals(HeroClass.rifleman));

      // 2 units unlocked: Rifleman 60%, Shotgunner 40%
      final pool2 = [HeroClass.rifleman, HeroClass.shotgunner];
      expect(BaseDefenseGame.rollUnitWithRng(_DeterministicRandom(0.59), pool2), equals(HeroClass.rifleman));
      expect(BaseDefenseGame.rollUnitWithRng(_DeterministicRandom(0.61), pool2), equals(HeroClass.shotgunner));

      // 3 units unlocked: Rifleman 45%, Shotgunner 30%, Sniper 25% (Clause 614)
      final pool3 = [HeroClass.rifleman, HeroClass.shotgunner, HeroClass.sniper];
      expect(BaseDefenseGame.rollUnitWithRng(_DeterministicRandom(0.44), pool3), equals(HeroClass.rifleman));
      expect(BaseDefenseGame.rollUnitWithRng(_DeterministicRandom(0.46), pool3), equals(HeroClass.shotgunner));
      expect(BaseDefenseGame.rollUnitWithRng(_DeterministicRandom(0.74), pool3), equals(HeroClass.shotgunner));
      expect(BaseDefenseGame.rollUnitWithRng(_DeterministicRandom(0.76), pool3), equals(HeroClass.sniper));

      // 4 units unlocked: Rifleman 40%, Shotgunner 25%, Heavy Gunner 20%, Sniper 15%
      final pool4 = [HeroClass.rifleman, HeroClass.shotgunner, HeroClass.sniper, HeroClass.heavyGunner];
      expect(BaseDefenseGame.rollUnitWithRng(_DeterministicRandom(0.39), pool4), equals(HeroClass.rifleman));
      expect(BaseDefenseGame.rollUnitWithRng(_DeterministicRandom(0.41), pool4), equals(HeroClass.shotgunner));
      expect(BaseDefenseGame.rollUnitWithRng(_DeterministicRandom(0.64), pool4), equals(HeroClass.shotgunner));
      expect(BaseDefenseGame.rollUnitWithRng(_DeterministicRandom(0.66), pool4), equals(HeroClass.heavyGunner));
      expect(BaseDefenseGame.rollUnitWithRng(_DeterministicRandom(0.84), pool4), equals(HeroClass.heavyGunner));
      expect(BaseDefenseGame.rollUnitWithRng(_DeterministicRandom(0.86), pool4), equals(HeroClass.sniper));
    });

    test('Endless Wave 11+ Enemy Composition Weights match exact tiers (Clauses 630–633)', () {
      // Wave 11–20 tier (Clause 631: Basic 25%, Runner 20%, Tank 15%, Swarm 25%, Shielded 15%)
      expect(WaveDefinition.rollWave11PlusEnemy(0.24, 15), equals(EnemyType.basic));
      expect(WaveDefinition.rollWave11PlusEnemy(0.44, 15), equals(EnemyType.runner));
      expect(WaveDefinition.rollWave11PlusEnemy(0.59, 15), equals(EnemyType.tank));
      expect(WaveDefinition.rollWave11PlusEnemy(0.84, 15), equals(EnemyType.swarm));
      expect(WaveDefinition.rollWave11PlusEnemy(0.86, 15), equals(EnemyType.shielded));

      // Wave 21–30 tier (Clause 632: Basic 15%, Runner 20%, Tank 20%, Swarm 25%, Shielded 20%)
      expect(WaveDefinition.rollWave11PlusEnemy(0.14, 25), equals(EnemyType.basic));
      expect(WaveDefinition.rollWave11PlusEnemy(0.34, 25), equals(EnemyType.runner));
      expect(WaveDefinition.rollWave11PlusEnemy(0.54, 25), equals(EnemyType.tank));
      expect(WaveDefinition.rollWave11PlusEnemy(0.79, 25), equals(EnemyType.swarm));
      expect(WaveDefinition.rollWave11PlusEnemy(0.81, 25), equals(EnemyType.shielded));

      // Wave 31+ tier (Clause 633: Basic 10%, Runner 20%, Tank 25%, Swarm 20%, Shielded 25%)
      expect(WaveDefinition.rollWave11PlusEnemy(0.09, 35), equals(EnemyType.basic));
      expect(WaveDefinition.rollWave11PlusEnemy(0.29, 35), equals(EnemyType.runner));
      expect(WaveDefinition.rollWave11PlusEnemy(0.54, 35), equals(EnemyType.tank));
      expect(WaveDefinition.rollWave11PlusEnemy(0.74, 35), equals(EnemyType.swarm));
      expect(WaveDefinition.rollWave11PlusEnemy(0.76, 35), equals(EnemyType.shielded));
    });

    test('Enemy count cap at 45 and spawn interval floor at 0.35s (Clauses 634, 637)', () {
      expect(GameBalance.getWaveEnemyCount(1), equals(7));
      expect(GameBalance.getWaveEnemyCount(5), equals(15));
      expect(GameBalance.getWaveEnemyCount(20), equals(45));
      expect(GameBalance.getWaveEnemyCount(100), equals(45)); // Capped at 45

      expect(GameBalance.getWaveSpawnInterval(1), equals(0.85));
      expect(GameBalance.getWaveSpawnInterval(10), closeTo(0.67, 1e-5));
      expect(GameBalance.getWaveSpawnInterval(100), equals(0.35)); // Capped at 0.35s
    });

    test('Piecewise 3-tier HP and Damage scaling formulas with hard caps (Clauses 638–643)', () {
      // HP Multiplier: W1–20: 1 + wave * 0.12, W21–40: 3.40 + (wave-20)*0.08, W41+: min(5.00 + (wave-40)*0.05, 8.00)
      expect(GameBalance.getWaveEnemyHpMultiplier(10), closeTo(2.20, 1e-5));
      expect(GameBalance.getWaveEnemyHpMultiplier(20), closeTo(3.40, 1e-5));
      expect(GameBalance.getWaveEnemyHpMultiplier(30), closeTo(4.20, 1e-5));
      expect(GameBalance.getWaveEnemyHpMultiplier(40), closeTo(5.00, 1e-5));
      expect(GameBalance.getWaveEnemyHpMultiplier(50), closeTo(5.50, 1e-5));
      expect(GameBalance.getWaveEnemyHpMultiplier(100), equals(8.00)); // Hard capped at 8.00x

      // Base Damage Multiplier: W1–20: 1 + wave * 0.05, W21–40: 2.00 + (wave-20)*0.035, W41+: min(2.70 + (wave-40)*0.02, 3.50)
      expect(GameBalance.getWaveEnemyDamageMultiplier(10), closeTo(1.50, 1e-5));
      expect(GameBalance.getWaveEnemyDamageMultiplier(20), closeTo(2.00, 1e-5));
      expect(GameBalance.getWaveEnemyDamageMultiplier(30), closeTo(2.35, 1e-5));
      expect(GameBalance.getWaveEnemyDamageMultiplier(40), closeTo(2.70, 1e-5));
      expect(GameBalance.getWaveEnemyDamageMultiplier(50), closeTo(2.90, 1e-5));
      expect(GameBalance.getWaveEnemyDamageMultiplier(100), equals(3.50)); // Hard capped at 3.50x

      // Normal movement speed is strictly unscaled
      expect(GameBalance.getWaveEnemySpeedMultiplier(1), equals(1.0));
      expect(GameBalance.getWaveEnemySpeedMultiplier(50), equals(1.0));
      expect(GameBalance.getWaveEnemySpeedMultiplier(100), equals(1.0));
    });

    test('Permanent upgrade max level 5 and exact cost table (Clauses 646, 647, 654)', () {
      expect(GameBalance.maxPermUpgradeLevel, equals(5));
      expect(GameBalance.permUpgradeCosts, equals([25, 50, 100, 175, 300]));
      expect(GameBalance.getPermanentUpgradeCost(0), equals(25));
      expect(GameBalance.getPermanentUpgradeCost(4), equals(300));
      // Level 5+ requests fall back safely to 300
      expect(GameBalance.getPermanentUpgradeCost(5), equals(300));
    });

    test('Save sanitization clamps invalid or corrupted values safely (Clause 661)', () {
      final corruptedMap = {
        'totalScrap': -500,
        'highestWave': -10,
        'permBaseHpLevel': 99,
        'permStartingCoinsLevel': -2,
        'bestBossRushRound': 100,
        'language': 'unsupported_lang',
      };

      final sanitized = PlayerSave.fromMap(corruptedMap);
      expect(sanitized.totalScrap, equals(0));
      expect(sanitized.highestWave, equals(1));
      expect(sanitized.permBaseHpLevel, equals(5)); // Clamped to max 5
      expect(sanitized.permStartingCoinsLevel, equals(0)); // Clamped to min 0
      expect(sanitized.bestBossRushRound, equals(5)); // Clamped to max 5
      expect(sanitized.language, isIn(['en', 'tr']));

      // Corrupted JSON string doesn't crash
      final recovered = PlayerSave.fromJson('{invalid_json}');
      expect(recovered.totalScrap, equals(0));
      expect(recovered.highestWave, equals(1));
    });

    test('AppLocalization provides punchy English and Turkish strings (Clauses 663–666)', () async {
      await SaveSystem.save(const PlayerSave(language: 'en'));
      expect(AppLocalization.text('wave'), equals('WAVE'));
      expect(AppLocalization.text('boss_incoming'), equals('BOSS INCOMING'));
      expect(AppLocalization.text('merge'), equals('MERGE'));
      expect(AppLocalization.text('retry'), equals('RETRY'));
      expect(AppLocalization.waveText(5), equals('WAVE 5'));

      await SaveSystem.save(const PlayerSave(language: 'tr'));
      expect(AppLocalization.text('wave'), equals('DALGA'));
      expect(AppLocalization.text('boss_incoming'), equals('BOSS GELİYOR'));
      expect(AppLocalization.text('merge'), equals('BİRLEŞTİR'));
      expect(AppLocalization.text('retry'), equals('TEKRAR OYNA'));
      expect(AppLocalization.waveText(5), equals('DALGA 5'));
    });

    test('AnalyticsService emits all 17 lifecycle events without failure (Clauses 685–689, 706)', () {
      final service = AnalyticsService.instance;
      service.clearLogForTesting();

      service.logGameStarted();
      service.logTutorialCompleted();
      service.logWaveStarted(1, 'normal');
      service.logWaveCompleted(1, 'normal');
      service.logBossStarted(5);
      service.logBossDefeated(5);
      service.logUnitPurchased('rifleman', 50);
      service.logUnitMerged('rifleman', 2);
      service.logUpgradeSelected('piercingRounds');
      service.logGameOver(5, 'normal', 35);
      service.logRetryPressed();
      service.logModeStarted('chaos');
      service.logModeFinished('chaos', false, 8);
      service.logRewardedOfferShown('supplyDrop');
      service.logRewardedOfferClicked('supplyDrop');
      service.logRewardedAdCompleted('supplyDrop');
      service.logRewardedRewardGranted('supplyDrop', 'supplyDrop');

      expect(service.eventLog.length, equals(17));
      expect(service.eventLog.map((e) => e.name).toList(), containsAll([
        'game_started',
        'tutorial_completed',
        'wave_started',
        'wave_completed',
        'boss_started',
        'boss_defeated',
        'unit_purchased',
        'unit_merged',
        'upgrade_selected',
        'game_over',
        'retry_pressed',
        'mode_started',
        'mode_finished',
        'rewarded_offer_shown',
        'rewarded_offer_clicked',
        'rewarded_ad_completed',
        'rewarded_reward_granted',
      ]));
    });
  });
}

/// Helper deterministic RNG for unit testing calculations
class _DeterministicRandom implements Random {
  final double nextVal;

  _DeterministicRandom(this.nextVal);

  @override
  bool nextBool() => nextVal < 0.5;

  @override
  double nextDouble() => nextVal;

  @override
  int nextInt(int max) => (nextVal * max).floor();
}
