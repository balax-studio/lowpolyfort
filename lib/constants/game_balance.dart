import 'dart:math';

/// Central game balance parameters and dynamic scaling formulas.
/// Exactly calibrated to Clauses 51–177. No hardcoded gameplay magic numbers.
class GameBalance {
  GameBalance._();

  // --- BASE & DEFENSE (Clause 56) ---
  static const double baseStartingHp = 1000.0;
  static const double baseDamageFlashDuration = 0.2;

  // --- ECONOMY (Clauses 56, 57) ---
  static const int startingCoins = 150;
  static const int unitBaseCost = 50;
  static const double unitCostMultiplier = 1.10; // cost = ceil(50 * (1.10 ^ purchaseCount))

  static int getUnitCost(int purchaseCount) {
    final raw = unitBaseCost * pow(unitCostMultiplier, purchaseCount);
    // Epsilon correction prevents IEEE-754 drift (e.g. 55.00000000000001) from bumping ceil
    return (raw - 1e-9).ceil();
  }

  // --- PROGRESSION & METAGAME (Clauses 69, 86, 104, 115) ---
  static const int maxUnitLevel = 8;
  static const int bossInterval = 5; // Boss spawns on wave 5, 10, 15, 20...
  static const int upgradeInterval = 3; // Roguelite 3-card pick on wave 3, 6, 9, 12, 15...
  static const int scrapPerWave = 3;
  static const int scrapPerBoss = 10;

  static int calculateScrapReward(int waveReached, int bossesDefeated) {
    // Clause 104: floor(waveReached * 3) + bossesDefeated * 10
    return (waveReached * scrapPerWave) + (bossesDefeated * scrapPerBoss);
  }

  // --- GAME MODES BALANCE (Clauses 320, 326, 329, 343, 347, 348) ---
  static const double chaosScrapMultiplier = 1.10; // +10% Scrap bonus in Chaos
  static const int bossRushStartingCoins = 300; // Extra start coins to assemble frontline
  static const int bossRushTotalRounds = 5;
  static const double bossRushInitialPrepSeconds = 8.0;
  static const double bossRushInterRoundPrepSeconds = 3.0;
  static const int bossRushScrapPerBoss = 8;
  static const int bossRushCompletionBonus = 10;
  static const int bossRushMaxScrap = 50;

  static int calculateChaosScrapReward(int waveReached, int bossesDefeated) {
    final base = calculateScrapReward(waveReached, bossesDefeated);
    return (base * chaosScrapMultiplier).floor();
  }

  static int calculateBossRushScrapReward(int bossesDefeated) {
    final base = bossesDefeated * bossRushScrapPerBoss;
    final bonus = (bossesDefeated >= bossRushTotalRounds) ? bossRushCompletionBonus : 0;
    return min(bossRushMaxScrap, base + bonus);
  }

  // Permanent upgrade costs by tier (Clauses 646, 647)
  static const int maxPermUpgradeLevel = 5;
  static const List<int> permUpgradeCosts = [25, 50, 100, 175, 300];

  static int getPermanentUpgradeCost(int currentLevel) {
    if (currentLevel < permUpgradeCosts.length) {
      return permUpgradeCosts[currentLevel];
    }
    return permUpgradeCosts.last;
  }

  // Unit unlock milestones (Clause 115)
  static const int unlockWaveRifleman = 1;
  static const int unlockWaveShotgunner = 5;
  static const int unlockWaveSniper = 10;
  static const int unlockWaveHeavyGunner = 15;

  // --- WAVES & PACING (Clauses 71, 72, 83, 84, 85, 634-643) ---
  static const int maxEnemiesAlive = 40; // Clause 83, 636 soft cap
  static const double waveCountdownSeconds = 1.5; // Snappy Wave 1 onboarding (Clause 271)
  static const double waveShortBannerSeconds = 0.8; // Quick subsequent wave banner (Clause 84)
  static const double waveClearIntermissionSeconds = 1.2; // Brisk breather without locking player (Clause 85, 216)
  static const double spawnIntervalStart = 0.85; // Clause 83, 637
  static const double spawnIntervalMin = 0.35; // Clause 637

  static double getWaveSpawnInterval(int wave) {
    // Clause 637: max(0.85 - 0.02 * (wave - 1), 0.35)
    return max(spawnIntervalStart - (0.02 * (wave - 1)), spawnIntervalMin);
  }

  static int getWaveEnemyCount(int wave) {
    // Clause 634: min(5 + wave * 2, 45)
    return min(5 + (wave * 2), 45);
  }

  static double getWaveEnemyHpMultiplier(int wave) {
    // Clauses 638–641: 3-tier HP multiplier capped at 8.00x
    if (wave <= 20) {
      return 1.0 + (wave * 0.12);
    } else if (wave <= 40) {
      return 3.40 + ((wave - 20) * 0.08);
    } else {
      return min(5.00 + ((wave - 40) * 0.05), 8.00);
    }
  }

  static double getWaveEnemyDamageMultiplier(int wave) {
    // Clause 642: 3-tier Base damage multiplier capped at 3.50x
    if (wave <= 20) {
      return 1.0 + (wave * 0.05);
    } else if (wave <= 40) {
      return 2.00 + ((wave - 20) * 0.035);
    } else {
      return min(2.70 + ((wave - 40) * 0.02), 3.50);
    }
  }

  static double getWaveEnemySpeedMultiplier(int wave) {
    // Clause 643: Normal mode enemy movement speed does not scale with wave
    return 1.0;
  }

  // --- TIMERS & COMBAT (Clauses 65, 68, 89) ---
  static const double targetScanInterval = 0.16; // 6 times/sec scan
  static const double mergeDurationSeconds = 0.50; // Clause 68: 0.4 - 0.65s
  static const double dragSpringReturnDurationSeconds = 0.20;
  static const double floatingTextDurationSeconds = 0.85;
  static const double maxCritChanceCap = 0.75; // Clause 89: 75% cap

  // Unit scaling multipliers (Clause 65)
  static double getHeroDamageMultiplier(int level) {
    return pow(1.75, level - 1).toDouble();
  }

  static double getHeroAttackSpeedMultiplier(int level) {
    return pow(1.04, level - 1).toDouble();
  }

  static double getHeroRangeMultiplier(int level) {
    return pow(1.02, level - 1).toDouble();
  }
}
