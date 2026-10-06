import 'package:flutter/material.dart';
import '../constants/game_balance.dart';
import '../constants/game_colors.dart';

enum HeroClass {
  rifleman,
  shotgunner,
  sniper,
  heavyGunner,
}

enum TargetPriority {
  first,
  closest,
  strongest,
  lowestHp,
  bossFirst,
}

class HeroDefinition {
  final HeroClass heroClass;
  final String name;
  final String roleDescription;
  final Color themeColor;
  final double baseDamage;
  final double attacksPerSecond;
  final double range;
  final double projectileSpeed;
  final double critChance;
  final double critMultiplier;
  final TargetPriority defaultPriority;
  final int projectileCount;
  final double spreadAngle; // in radians
  final int unlockWaveRequirement;

  const HeroDefinition({
    required this.heroClass,
    required this.name,
    required this.roleDescription,
    required this.themeColor,
    required this.baseDamage,
    required this.attacksPerSecond,
    required this.range,
    required this.projectileSpeed,
    required this.critChance,
    required this.critMultiplier,
    required this.defaultPriority,
    required this.unlockWaveRequirement,
    this.projectileCount = 1,
    this.spreadAngle = 0.0,
  });

  /// Factory blueprints for each unit class matching Clauses 61–64 & 115
  static const Map<HeroClass, HeroDefinition> registry = {
    HeroClass.rifleman: HeroDefinition(
      heroClass: HeroClass.rifleman,
      name: 'Rifleman',
      roleDescription: 'Versatile frontline combatant with balanced range and fire rate.',
      themeColor: GameColors.riflemanUniform,
      baseDamage: 12.0,
      attacksPerSecond: 1.2,
      range: 280.0,
      projectileSpeed: 650.0,
      critChance: 0.05,
      critMultiplier: 1.75,
      defaultPriority: TargetPriority.first,
      unlockWaveRequirement: GameBalance.unlockWaveRifleman,
    ),
    HeroClass.shotgunner: HeroDefinition(
      heroClass: HeroClass.shotgunner,
      name: 'Shotgunner',
      roleDescription: 'Devastating close-range blast firing 5 spread pellets.',
      themeColor: GameColors.shotgunnerUniform,
      baseDamage: 9.0, // Per pellet (x5 = 45 burst)
      attacksPerSecond: 0.65,
      range: 150.0,
      projectileSpeed: 550.0,
      critChance: 0.03,
      critMultiplier: 1.5,
      defaultPriority: TargetPriority.closest,
      projectileCount: 5,
      spreadAngle: 0.38,
      unlockWaveRequirement: GameBalance.unlockWaveShotgunner,
    ),
    HeroClass.sniper: HeroDefinition(
      heroClass: HeroClass.sniper,
      name: 'Sniper',
      roleDescription: 'Extreme range anti-armor marksman targeting strongest threats.',
      themeColor: GameColors.sniperUniform,
      baseDamage: 55.0,
      attacksPerSecond: 0.45,
      range: 520.0,
      projectileSpeed: 1100.0,
      critChance: 0.12,
      critMultiplier: 2.0,
      defaultPriority: TargetPriority.strongest,
      unlockWaveRequirement: GameBalance.unlockWaveSniper,
    ),
    HeroClass.heavyGunner: HeroDefinition(
      heroClass: HeroClass.heavyGunner,
      name: 'Heavy Gunner',
      roleDescription: 'Continuous suppression fire decimating advancing hordes.',
      themeColor: GameColors.heavyGunnerUniform,
      baseDamage: 6.0,
      attacksPerSecond: 3.0,
      range: 250.0,
      projectileSpeed: 750.0,
      critChance: 0.04,
      critMultiplier: 1.5,
      defaultPriority: TargetPriority.first,
      unlockWaveRequirement: GameBalance.unlockWaveHeavyGunner,
    ),
  };

  /// Calculates scaled damage output for a unit at [level] (Clause 65)
  double getDamageAtLevel(int level) {
    return baseDamage * GameBalance.getHeroDamageMultiplier(level);
  }

  /// Calculates scaled attack speed for a unit at [level] (Clause 65)
  double getAttackSpeedAtLevel(int level) {
    return attacksPerSecond * GameBalance.getHeroAttackSpeedMultiplier(level);
  }

  /// Calculates scaled effective range for a unit at [level] (Clause 65)
  double getRangeAtLevel(int level) {
    return range * GameBalance.getHeroRangeMultiplier(level);
  }
}
