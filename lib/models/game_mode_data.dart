import 'dart:math';
import 'enemy_data.dart';

/// Supported game modes (Clauses 277–280).
/// Exactly 3 modes. All modes share the same 3x3 board and core combat engine.
enum GameMode {
  normal,
  chaos,
  bossRush,
}

/// The 6 Chaos Modifiers (Clauses 304–310).
enum ChaosModifierType {
  none,
  rushHour,
  toughCrowd,
  swarmWave,
  richWave,
  rapidFire,
  giants,
}

/// Lightweight data class specifying transient wave rule adjustments.
/// ponytail: simple immutable config without over-abstracted rule engine.
class ChaosModifier {
  final ChaosModifierType type;
  final String title;
  final String subtitle;
  final double enemyHpMultiplier;
  final double enemySpeedMultiplier;
  final double enemyCountMultiplier;
  final double enemyCoinMultiplier;
  final double unitAttackSpeedMultiplier;
  final double enemyScaleMultiplier;

  const ChaosModifier({
    required this.type,
    required this.title,
    required this.subtitle,
    this.enemyHpMultiplier = 1.0,
    this.enemySpeedMultiplier = 1.0,
    this.enemyCountMultiplier = 1.0,
    this.enemyCoinMultiplier = 1.0,
    this.unitAttackSpeedMultiplier = 1.0,
    this.enemyScaleMultiplier = 1.0,
  });

  static const ChaosModifier none = ChaosModifier(
    type: ChaosModifierType.none,
    title: 'NORMAL WAVE',
    subtitle: 'STANDARD RULES',
  );

  static const ChaosModifier rushHour = ChaosModifier(
    type: ChaosModifierType.rushHour,
    title: 'RUSH HOUR',
    subtitle: 'ENEMIES +30% SPEED',
    enemySpeedMultiplier: 1.30,
    enemyCoinMultiplier: 1.15,
  );

  static const ChaosModifier toughCrowd = ChaosModifier(
    type: ChaosModifierType.toughCrowd,
    title: 'TOUGH CROWD',
    subtitle: 'ENEMIES +35% HP',
    enemyHpMultiplier: 1.35,
    enemyCoinMultiplier: 1.20,
  );

  static const ChaosModifier swarmWave = ChaosModifier(
    type: ChaosModifierType.swarmWave,
    title: 'SWARM WAVE',
    subtitle: 'MORE ENEMIES • LESS HP',
    enemyCountMultiplier: 1.50,
    enemyHpMultiplier: 0.80,
  );

  static const ChaosModifier richWave = ChaosModifier(
    type: ChaosModifierType.richWave,
    title: 'RICH WAVE',
    subtitle: 'DOUBLE COINS',
    enemyHpMultiplier: 1.25,
    enemyCoinMultiplier: 2.00,
  );

  static const ChaosModifier rapidFire = ChaosModifier(
    type: ChaosModifierType.rapidFire,
    title: 'RAPID FIRE',
    subtitle: 'UNITS FIRE 50% FASTER',
    unitAttackSpeedMultiplier: 1.50,
    enemySpeedMultiplier: 1.15,
  );

  static const ChaosModifier giants = ChaosModifier(
    type: ChaosModifierType.giants,
    title: 'GIANTS',
    subtitle: 'FEWER • BIGGER • STRONGER',
    enemyCountMultiplier: 0.65,
    enemyHpMultiplier: 2.00,
    enemyScaleMultiplier: 1.40,
    enemySpeedMultiplier: 0.85,
    enemyCoinMultiplier: 1.50,
  );

  static const List<ChaosModifier> activePool = [
    rushHour,
    toughCrowd,
    swarmWave,
    richWave,
    rapidFire,
    giants,
  ];

  /// Resolves the modifier for a given Chaos wave (Clauses 311–314).
  /// Waves 1–10 follow an exact baseline sequence.
  /// Wave 11+ uses seeded random and guarantees no immediate duplicate.
  static ChaosModifier resolveForWave(int wave, {ChaosModifierType? previousType, int? customSeed}) {
    if (wave <= 1) return none;

    // Fixed sequence for waves 2–10 (Clause 312)
    switch (wave) {
      case 2:
        return rushHour;
      case 3:
        return rapidFire;
      case 4:
        return swarmWave;
      case 5:
        return toughCrowd;
      case 6:
        return richWave;
      case 7:
        return rushHour;
      case 8:
        return giants;
      case 9:
        return rapidFire;
      case 10:
        return richWave;
      default:
        // Wave 11+ seeded random selection avoiding immediate duplicate (Clause 313, 314)
        final rng = Random(customSeed ?? (wave * 7919));
        final eligible = activePool.where((m) => m.type != previousType).toList();
        return eligible[rng.nextInt(eligible.length)];
    }
  }
}

/// Specifications for Boss Rush rounds 1 through 5 (Clauses 324–337).
class BossRushRoundData {
  final int roundNumber;
  final double bossHpMultiplier;
  final double bossDamageMultiplier;
  final double bossSpeedMultiplier;
  final int bossCoinReward;
  final Map<EnemyType, int> supportRoster;

  const BossRushRoundData({
    required this.roundNumber,
    required this.bossHpMultiplier,
    required this.bossDamageMultiplier,
    required this.bossSpeedMultiplier,
    required this.bossCoinReward,
    required this.supportRoster,
  });

  static const List<BossRushRoundData> rounds = [
    BossRushRoundData(
      roundNumber: 1,
      bossHpMultiplier: 1.00,
      bossDamageMultiplier: 1.00,
      bossSpeedMultiplier: 1.00,
      bossCoinReward: 120,
      supportRoster: {},
    ),
    BossRushRoundData(
      roundNumber: 2,
      bossHpMultiplier: 1.35,
      bossDamageMultiplier: 1.10,
      bossSpeedMultiplier: 1.00,
      bossCoinReward: 140,
      supportRoster: {EnemyType.runner: 4},
    ),
    BossRushRoundData(
      roundNumber: 3,
      bossHpMultiplier: 1.75,
      bossDamageMultiplier: 1.20,
      bossSpeedMultiplier: 1.05,
      bossCoinReward: 160,
      supportRoster: {EnemyType.tank: 2, EnemyType.basic: 4},
    ),
    BossRushRoundData(
      roundNumber: 4,
      bossHpMultiplier: 2.25,
      bossDamageMultiplier: 1.35,
      bossSpeedMultiplier: 1.10,
      bossCoinReward: 180,
      supportRoster: {EnemyType.shielded: 3, EnemyType.swarm: 6},
    ),
    BossRushRoundData(
      roundNumber: 5,
      bossHpMultiplier: 3.00,
      bossDamageMultiplier: 1.50,
      bossSpeedMultiplier: 1.15,
      bossCoinReward: 250,
      supportRoster: {EnemyType.tank: 2, EnemyType.shielded: 2, EnemyType.runner: 6},
    ),
  ];

  static BossRushRoundData getRound(int roundNumber) {
    final index = (roundNumber - 1).clamp(0, rounds.length - 1);
    return rounds[index];
  }
}
