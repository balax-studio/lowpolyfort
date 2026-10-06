import 'package:flutter/material.dart';
import '../constants/game_balance.dart';
import '../constants/game_colors.dart';

enum EnemyType {
  basic,
  runner,
  tank,
  swarm,
  shielded,
  boss,
}

class EnemyDefinition {
  final EnemyType type;
  final String name;
  final Color baseColor;
  final double baseHp;
  final double baseSpeed;
  final double baseDamage; // Damage dealt to base per hit
  final double attackInterval; // Seconds between strikes at base
  final int baseCoinReward;
  final double radius;
  final double baseShield;

  // Boss specific charge attributes (Clause 75)
  final double chargeSpeed;
  final double chargeDuration;
  final double chargeCooldown;

  const EnemyDefinition({
    required this.type,
    required this.name,
    required this.baseColor,
    required this.baseHp,
    required this.baseSpeed,
    required this.baseDamage,
    required this.attackInterval,
    required this.baseCoinReward,
    required this.radius,
    this.baseShield = 0.0,
    this.chargeSpeed = 0.0,
    this.chargeDuration = 0.0,
    this.chargeCooldown = 0.0,
  });

  /// Factory blueprints for each enemy horde type matching Clauses 70 & 75
  static const Map<EnemyType, EnemyDefinition> registry = {
    EnemyType.basic: EnemyDefinition(
      type: EnemyType.basic,
      name: 'Mutant Raider',
      baseColor: GameColors.enemyBasic,
      baseHp: 55.0,
      baseSpeed: 55.0,
      baseDamage: 15.0,
      attackInterval: 1.0,
      baseCoinReward: 5,
      radius: 14.0,
    ),
    EnemyType.runner: EnemyDefinition(
      type: EnemyType.runner,
      name: 'Scout Sprinter',
      baseColor: GameColors.enemyRunner,
      baseHp: 34.0,
      baseSpeed: 90.0,
      baseDamage: 10.0,
      attackInterval: 0.8,
      baseCoinReward: 4,
      radius: 11.0,
    ),
    EnemyType.tank: EnemyDefinition(
      type: EnemyType.tank,
      name: 'Iron Goliath',
      baseColor: GameColors.enemyTank,
      baseHp: 210.0,
      baseSpeed: 32.0,
      baseDamage: 35.0,
      attackInterval: 1.4,
      baseCoinReward: 15,
      radius: 20.0,
    ),
    EnemyType.swarm: EnemyDefinition(
      type: EnemyType.swarm,
      name: 'Swarm Crawler',
      baseColor: GameColors.enemySwarm,
      baseHp: 22.0,
      baseSpeed: 72.0,
      baseDamage: 6.0,
      attackInterval: 0.7,
      baseCoinReward: 2,
      radius: 9.0,
    ),
    EnemyType.shielded: EnemyDefinition(
      type: EnemyType.shielded,
      name: 'Barrier Warden',
      baseColor: GameColors.enemyShielded,
      baseHp: 120.0,
      baseShield: 80.0,
      baseSpeed: 43.0,
      baseDamage: 22.0,
      attackInterval: 1.1,
      baseCoinReward: 12,
      radius: 15.0,
    ),
    EnemyType.boss: EnemyDefinition(
      type: EnemyType.boss,
      name: 'Brute Warlord',
      baseColor: GameColors.enemyBoss,
      baseHp: 1200.0,
      baseSpeed: 24.0,
      chargeSpeed: 55.0,
      chargeDuration: 1.2,
      chargeCooldown: 7.0,
      baseDamage: 65.0,
      attackInterval: 1.8,
      baseCoinReward: 100,
      radius: 30.0,
    ),
  };

  /// Computes scaled HP for wave number (Clause 71: 1 + wave * 0.12)
  double getScaledHp(int wave) {
    return (baseHp * GameBalance.getWaveEnemyHpMultiplier(wave)).roundToDouble();
  }

  /// Computes scaled speed for wave number
  double getScaledSpeed(int wave) {
    return baseSpeed * GameBalance.getWaveEnemySpeedMultiplier(wave);
  }

  /// Computes scaled shield capacity for wave number
  double getScaledShield(int wave) {
    if (baseShield <= 0) return 0.0;
    return (baseShield * GameBalance.getWaveEnemyHpMultiplier(wave)).roundToDouble();
  }

  /// Computes scaled base damage for wave number (Clause 642)
  double getScaledDamage(int wave) {
    return (baseDamage * GameBalance.getWaveEnemyDamageMultiplier(wave)).roundToDouble();
  }
}
