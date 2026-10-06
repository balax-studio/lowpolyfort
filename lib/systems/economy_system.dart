import 'package:flutter/foundation.dart';
import '../constants/game_balance.dart';

/// Handles in-run monetary calculations, unit purchasing formulas, and coin rewards.
class EconomySystem extends ChangeNotifier {
  int _coins = GameBalance.startingCoins;
  int _displayedCoins = GameBalance.startingCoins;
  int _unitPurchases = 0;
  int _totalCoinsEarnedThisRun = 0;

  int get coins => _coins;
  int get displayedCoins => _displayedCoins;
  int get unitPurchases => _unitPurchases;
  int get totalCoinsEarned => _totalCoinsEarnedThisRun;

  int get nextUnitCost => GameBalance.getUnitCost(_unitPurchases);
  int get lastUnitCost => _unitPurchases > 0 ? GameBalance.getUnitCost(_unitPurchases - 1) : GameBalance.unitBaseCost;
  bool get canAffordUnit => _coins >= nextUnitCost;

  void reset([int startingCoinBonus = 0, int? customBaseCoins]) {
    _coins = (customBaseCoins ?? GameBalance.startingCoins) + startingCoinBonus;
    _displayedCoins = _coins;
    _unitPurchases = 0;
    _totalCoinsEarnedThisRun = 0;
    notifyListeners();
  }

  bool buyUnit() {
    final cost = nextUnitCost;
    if (_coins >= cost) {
      _coins -= cost;
      _unitPurchases++;
      notifyListeners();
      return true;
    }
    return false;
  }

  void spend(int amount) {
    if (amount <= 0) return;
    _coins = (_coins - amount).clamp(0, 9999999);
    _displayedCoins = _coins;
    notifyListeners();
  }

  void addCoins(int amount) {
    if (amount <= 0) return;
    _coins += amount;
    _totalCoinsEarnedThisRun += amount;
    notifyListeners();
  }

  /// Incremental smooth count-up tick for HUD animations.
  void updateCoinCounter(double dt) {
    if (_displayedCoins != _coins) {
      final diff = _coins - _displayedCoins;
      final step = (diff * dt * 10).round();
      if (step.abs() < 1) {
        _displayedCoins += (diff > 0) ? 1 : -1;
      } else {
        _displayedCoins += step;
      }
      notifyListeners();
    }
  }

  void debugAddCoins(int amount) {
    _coins += amount;
    _totalCoinsEarnedThisRun += amount;
    notifyListeners();
  }
}
