import 'dart:math';
import 'package:flutter/foundation.dart';
import '../constants/game_balance.dart';
import '../models/upgrade_data.dart';
import '../models/player_save.dart';

/// Manages active in-run Roguelite perks and meta-progression multipliers.
/// Enforces caps and tracks synergy modifiers (Clauses 88, 89, 91).
class UpgradeSystem extends ChangeNotifier {
  double damageMultiplier = 1.0;
  double attackSpeedMultiplier = 1.0;
  double rangeMultiplier = 1.0;
  double maxBaseHpBonus = 0.0;
  double critChanceBonus = 0.0;
  double coinBonusMultiplier = 1.0;
  double armorPiercingMultiplier = 1.0;

  final List<UpgradeCard> _chosenCards = [];
  List<UpgradeCard> get chosenCards => List.unmodifiable(_chosenCards);

  /// Initializes run with meta-progression perks from player save.
  void initFromSave(PlayerSave save) {
    _chosenCards.clear();
    // Clauses 106-111 permanent perks
    damageMultiplier = 1.0 + (save.permDamageLevel * 0.02);
    attackSpeedMultiplier = 1.0 + (save.permAttackSpeedLevel * 0.015);
    rangeMultiplier = 1.0;
    maxBaseHpBonus = (save.permBaseHpLevel * 50.0);
    critChanceBonus = (save.permCritLevel * 0.005);
    coinBonusMultiplier = 1.0 + (save.permBountyLevel * 0.02);
    armorPiercingMultiplier = 1.0;
    notifyListeners();
  }

  /// Selects 3 non-duplicate cards for the player to draft.
  List<UpgradeCard> drawThreeCards() {
    final pool = List<UpgradeCard>.from(UpgradeCard.pool);
    pool.shuffle(Random());
    return pool.take(3).toList();
  }

  /// Applies a selected perk to the active run.
  void applyUpgrade(UpgradeCard card) {
    _chosenCards.add(card);
    switch (card.type) {
      case UpgradeType.heavyAmmo:
        damageMultiplier += card.valueMultiplier;
        break;
      case UpgradeType.rapidFire:
        attackSpeedMultiplier += card.valueMultiplier;
        break;
      case UpgradeType.longBarrels:
        rangeMultiplier += card.valueMultiplier;
        break;
      case UpgradeType.criticalTraining:
        critChanceBonus = min(GameBalance.maxCritChanceCap, critChanceBonus + card.valueMultiplier);
        break;
      case UpgradeType.fortifiedBase:
        maxBaseHpBonus += card.valueMultiplier;
        break;
      case UpgradeType.fieldRepair:
        // Handled in GameManager to directly heal base
        break;
      case UpgradeType.bountyHunter:
        coinBonusMultiplier += card.valueMultiplier;
        break;
      case UpgradeType.armorPiercing:
        armorPiercingMultiplier += card.valueMultiplier;
        break;
    }
    notifyListeners();
  }
}
