import 'dart:math';
import '../constants/game_balance.dart';
import '../models/hero_data.dart';
import '../models/enemy_data.dart';

/// Pure logic calculators separated from Flame components for deterministic
/// unit testing, safety, and single-source truth. (Clauses 65, 92, 158)
class CombatCalculators {
  CombatCalculators._();
}

/// Unit purchase cost progression (Clause 56)
class UnitCostCalculator {
  UnitCostCalculator._();

  static int calculateCost(int purchaseCount) {
    return GameBalance.getUnitCost(purchaseCount);
  }
}

/// Level-based stat scaling for defenders (Clause 65)
class UnitStatsCalculator {
  UnitStatsCalculator._();

  static double getDamage(double baseDamage, int level) {
    return baseDamage * GameBalance.getHeroDamageMultiplier(level);
  }

  static double getAttackSpeed(double baseSpeed, int level) {
    return baseSpeed * GameBalance.getHeroAttackSpeedMultiplier(level);
  }

  static double getRange(double baseRange, int level) {
    return baseRange * GameBalance.getHeroRangeMultiplier(level);
  }
}

/// Centralized damage resolution formula (Clause 92)
class DamageResolution {
  final double damage;
  final bool isCrit;

  const DamageResolution({required this.damage, required this.isCrit});
}

class DamageCalculator {
  DamageCalculator._();

  static DamageResolution calculate({
    required double baseDamage,
    required int level,
    required double globalDamageMultiplier,
    required double critChance,
    required double critMultiplier,
    required EnemyType targetType,
    double armorPiercingMultiplier = 1.0, // Bonus from Armor Piercing perk against Tank/Shielded
    Random? rng,
  }) {
    final random = rng ?? Random();
    final levelMult = UnitStatsCalculator.getDamage(1.0, level);

    // Target type modifier (Clause 88: Armor Piercing +20% vs Tank and Shielded)
    double targetTypeModifier = 1.0;
    if (targetType == EnemyType.tank || targetType == EnemyType.shielded) {
      targetTypeModifier = armorPiercingMultiplier;
    }

    final subtotal = baseDamage * levelMult * globalDamageMultiplier * targetTypeModifier;

    // Critical roll capped at 75% (Clause 89)
    final effectiveCrit = critChance.clamp(0.0, GameBalance.maxCritChanceCap);
    final isCrit = random.nextDouble() < effectiveCrit;
    final finalDamage = isCrit ? (subtotal * critMultiplier) : subtotal;

    return DamageResolution(
      damage: (finalDamage * 10).round() / 10, // Clean 1 decimal rounding
      isCrit: isCrit,
    );
  }
}

/// Merge validation rules (Clauses 67, 69, 159)
class MergeValidator {
  MergeValidator._();

  static bool canMerge({
    required HeroClass sourceClass,
    required int sourceLevel,
    required HeroClass targetClass,
    required int targetLevel,
  }) {
    if (sourceClass != targetClass) return false;
    if (sourceLevel != targetLevel) return false;
    if (sourceLevel >= GameBalance.maxUnitLevel) return false;
    return true;
  }
}

/// Scrap meta-progression currency formula (Clause 104)
class ScrapRewardCalculator {
  ScrapRewardCalculator._();

  static int calculateScrap({required int waveReached, required int bossesDefeated}) {
    return GameBalance.calculateScrapReward(waveReached, bossesDefeated);
  }
}

/// Wave difficulty progression (Clauses 71, 72)
class WaveDifficultyCalculator {
  WaveDifficultyCalculator._();

  static int getEnemyCount(int wave) {
    return GameBalance.getWaveEnemyCount(wave);
  }

  static double getHpMultiplier(int wave) {
    return GameBalance.getWaveEnemyHpMultiplier(wave);
  }
}
