import 'package:flutter/material.dart';
import '../constants/game_colors.dart';

enum UpgradeRarity {
  common,
  rare,
  epic,
  legendary,
}

enum UpgradeType {
  heavyAmmo, // +15% damage
  rapidFire, // +10% attack speed
  longBarrels, // +12% range
  criticalTraining, // +5% crit chance
  fortifiedBase, // +200 max HP & current HP
  fieldRepair, // +30% max HP heal
  bountyHunter, // +15% coins
  armorPiercing, // +20% damage to Tank & Shielded
}

class UpgradeCard {
  final String id;
  final String title;
  final String description;
  final UpgradeRarity rarity;
  final UpgradeType type;
  final double valueMultiplier;
  final IconData icon;

  const UpgradeCard({
    required this.id,
    required this.title,
    required this.description,
    required this.rarity,
    required this.type,
    required this.valueMultiplier,
    required this.icon,
  });

  Color get rarityColor {
    switch (rarity) {
      case UpgradeRarity.common:
        return Colors.white;
      case UpgradeRarity.rare:
        return GameColors.techBlue;
      case UpgradeRarity.epic:
        return GameColors.cyberPurple;
      case UpgradeRarity.legendary:
        return GameColors.acidYellow;
    }
  }

  String get rarityLabel {
    switch (rarity) {
      case UpgradeRarity.common:
        return 'COMMON';
      case UpgradeRarity.rare:
        return 'RARE';
      case UpgradeRarity.epic:
        return 'EPIC';
      case UpgradeRarity.legendary:
        return 'LEGENDARY';
    }
  }

  /// Preset deck of Roguelite in-run tactical upgrades matching Clause 88
  static const List<UpgradeCard> pool = [
    UpgradeCard(
      id: 'heavy_ammo',
      title: 'HEAVY AMMO',
      description: '+15% UNIT DAMAGE',
      rarity: UpgradeRarity.common,
      type: UpgradeType.heavyAmmo,
      valueMultiplier: 0.15,
      icon: Icons.whatshot,
    ),
    UpgradeCard(
      id: 'rapid_fire',
      title: 'RAPID FIRE',
      description: '+10% ATTACK SPEED',
      rarity: UpgradeRarity.common,
      type: UpgradeType.rapidFire,
      valueMultiplier: 0.10,
      icon: Icons.speed,
    ),
    UpgradeCard(
      id: 'long_barrels',
      title: 'LONG BARRELS',
      description: '+12% WEAPON RANGE',
      rarity: UpgradeRarity.rare,
      type: UpgradeType.longBarrels,
      valueMultiplier: 0.12,
      icon: Icons.straighten,
    ),
    UpgradeCard(
      id: 'critical_training',
      title: 'CRITICAL TRAINING',
      description: '+5% CRITICAL CHANCE',
      rarity: UpgradeRarity.rare,
      type: UpgradeType.criticalTraining,
      valueMultiplier: 0.05,
      icon: Icons.track_changes,
    ),
    UpgradeCard(
      id: 'fortified_base',
      title: 'FORTIFIED BASE',
      description: '+200 BASE HP & REPAIR',
      rarity: UpgradeRarity.common,
      type: UpgradeType.fortifiedBase,
      valueMultiplier: 200.0,
      icon: Icons.security,
    ),
    UpgradeCard(
      id: 'field_repair',
      title: 'FIELD REPAIR',
      description: '+30% BASE HP REPAIR',
      rarity: UpgradeRarity.rare,
      type: UpgradeType.fieldRepair,
      valueMultiplier: 0.30,
      icon: Icons.build,
    ),
    UpgradeCard(
      id: 'bounty_hunter',
      title: 'BOUNTY HUNTER',
      description: '+15% ENEMY COIN REWARDS',
      rarity: UpgradeRarity.rare,
      type: UpgradeType.bountyHunter,
      valueMultiplier: 0.15,
      icon: Icons.monetization_on,
    ),
    UpgradeCard(
      id: 'armor_piercing',
      title: 'ARMOR PIERCING',
      description: '+20% VS TANK & SHIELDED',
      rarity: UpgradeRarity.epic,
      type: UpgradeType.armorPiercing,
      valueMultiplier: 0.20,
      icon: Icons.gavel,
    ),
  ];
}
