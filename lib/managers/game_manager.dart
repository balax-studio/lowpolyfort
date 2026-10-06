import 'dart:math';
import 'package:flutter/foundation.dart';
import '../constants/game_balance.dart';
import '../constants/ad_config.dart';
import '../models/upgrade_data.dart';
import '../models/game_mode_data.dart';
import '../models/rewarded_placement.dart';
import '../services/rewarded_ad_service.dart';
import '../systems/economy_system.dart';
import '../systems/upgrade_system.dart';
import '../systems/save_system.dart';
import '../services/analytics_service.dart';
import 'audio_manager.dart';

import '../systems/goal_presentation_service.dart';

enum GameState {
  menu,
  tutorial,
  preparingWave,
  playing,
  upgradeSelection,
  paused,
  awaitingSecondChance,
  gameOver,
}

/// Central state manager coordinating the Flame simulation with Flutter UI overlays.
class GameManager extends ChangeNotifier {
  static final GameManager instance = GameManager._();
  factory GameManager() => instance;
  GameManager._();

  GameState _state = GameState.menu;
  GameState get state => _state;

  final EconomySystem economy = EconomySystem();
  final UpgradeSystem upgrades = UpgradeSystem();

  // Mode state (Clauses 277–280)
  GameMode _activeMode = GameMode.normal;
  GameMode get activeMode => _activeMode;

  ChaosModifier _activeChaosModifier = ChaosModifier.none;
  ChaosModifier get activeChaosModifier => _activeChaosModifier;

  int _bossRushRound = 1;
  int get bossRushRound => _bossRushRound;

  bool _isBossRushVictory = false;
  bool get isBossRushVictory => _isBossRushVictory;

  String? _newModeUnlockedBannerText;
  String? get newModeUnlockedBannerText => _newModeUnlockedBannerText;
  double _newModeUnlockedTimer = 0.0;

  int _currentWave = 1;
  int get currentWave => _currentWave;

  double _baseHp = GameBalance.baseStartingHp;
  double _maxBaseHp = GameBalance.baseStartingHp;
  double get baseHp => _baseHp;
  double get maxBaseHp => _maxBaseHp;
  double get baseHpPercentage => (_maxBaseHp > 0) ? (_baseHp / _maxBaseHp).clamp(0.0, 1.0) : 0.0;

  int _killsThisRun = 0;
  int get killsThisRun => _killsThisRun;

  int _bossesDefeatedThisRun = 0;
  int get bossesDefeatedThisRun => _bossesDefeatedThisRun;

  int _scrapEarnedThisRun = 0;
  int get scrapEarnedThisRun => _scrapEarnedThisRun;

  double _countdownRemaining = 0.0;
  double get countdownRemaining => _countdownRemaining;

  bool _isBossIncoming = false;
  bool get isBossIncoming => _isBossIncoming;

  bool _showMidWaveWarning = false;
  bool get showMidWaveWarning => _showMidWaveWarning;
  double _midWaveWarningTimer = 0.0;

  String? _bossDefeatedBannerText;
  String? get bossDefeatedBannerText => _bossDefeatedBannerText;
  double _bossDefeatedTimer = 0.0;

  // Live in-combat New Best celebration (Clauses 199–201)
  String? _liveNewBestBannerText;
  String? get liveNewBestBannerText => _liveNewBestBannerText;
  double _liveNewBestTimer = 0.0;
  bool _justCelebratedHighScore = false;

  bool _isNewHighScore = false;
  bool get isNewHighScore => _isNewHighScore;

  // --- REWARDED ADS MONETIZATION STATE (Clauses 422–597) ---
  static int _runSequence = 0;
  String _currentRunId = '';
  String get currentRunId => _currentRunId;

  int _runRewardedCount = 0;
  int get runRewardedCount => _runRewardedCount;

  bool _supplyDropUsedThisRun = false;
  bool get supplyDropUsedThisRun => _supplyDropUsedThisRun;

  bool _secondChanceUsedThisRun = false;
  bool get secondChanceUsedThisRun => _secondChanceUsedThisRun;

  bool _extraScrapUsedThisRun = false;
  bool get extraScrapUsedThisRun => _extraScrapUsedThisRun;

  bool _extraScrapAwardedThisRun = false;
  bool get extraScrapAwardedThisRun => _extraScrapAwardedThisRun;

  int? _lastRewardedAdCompletedTimestamp;

  bool _isGracePeriodActive = false;
  bool get isGracePeriodActive => _isGracePeriodActive;
  double _gracePeriodRemaining = 0.0;
  double get gracePeriodRemaining => _gracePeriodRemaining;

  int _pendingSupplyCoins = 0;
  int get pendingSupplyCoins => _pendingSupplyCoins;

  bool _isRewardedAdShowing = false;
  bool get isRewardedAdShowing => _isRewardedAdShowing;
  double? _savedPrepCountdown;

  bool Function()? hasEmptySlotCheck;

  bool get isGlobalCooldownExpired {
    if (_lastRewardedAdCompletedTimestamp == null) return true;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final elapsedSec = (now - _lastRewardedAdCompletedTimestamp!) / 1000.0;
    return elapsedSec >= AdConfig.rewardedGlobalCooldownSeconds;
  }

  bool get canOfferSupplyDrop {
    final save = SaveSystem.currentSave;
    if (save.highestWave < AdConfig.unlockWaveMilestone || !save.tutorialCompleted) return false;
    if (!RewardedAdService.instance.isAdReady) return false;
    if (save.completedAdsInRolling24h >= AdConfig.rewardedDailyCap) return false;
    if (_runRewardedCount >= AdConfig.maxRewardedPerRun) return false;
    if (!isGlobalCooldownExpired) return false;
    if (_supplyDropUsedThisRun) return false;
    if (_state != GameState.preparingWave) return false;
    if (economy.coins >= economy.nextUnitCost) return false;
    if (hasEmptySlotCheck != null && !hasEmptySlotCheck!()) return false;
    if (_activeMode != GameMode.bossRush && _isBossIncoming) return false;
    return true;
  }

  bool get canOfferSecondChance {
    final save = SaveSystem.currentSave;
    if (save.highestWave < AdConfig.unlockWaveMilestone || !save.tutorialCompleted) return false;
    if (!RewardedAdService.instance.isAdReady) return false;
    if (save.completedAdsInRolling24h >= AdConfig.rewardedDailyCap) return false;
    if (_runRewardedCount >= AdConfig.maxRewardedPerRun) return false;
    if (!isGlobalCooldownExpired) return false;
    if (_secondChanceUsedThisRun) return false;
    if (_isBossRushVictory) return false;
    if (_activeMode == GameMode.bossRush) {
      return _bossRushRound >= 1;
    } else {
      return _currentWave >= 3;
    }
  }

  bool get canOfferExtraScrap {
    final save = SaveSystem.currentSave;
    if (save.highestWave < AdConfig.unlockWaveMilestone) return false;
    if (!RewardedAdService.instance.isAdReady) return false;
    if (save.completedAdsInRolling24h >= AdConfig.rewardedDailyCap) return false;
    if (_runRewardedCount >= AdConfig.maxRewardedPerRun) return false;
    if (!isGlobalCooldownExpired) return false;
    if (_extraScrapUsedThisRun) return false;
    if (_scrapEarnedThisRun <= 0) return false;
    return true;
  }

  List<String> _newUnitsUnlockedThisRun = [];
  List<String> get newUnitsUnlockedThisRun => List.unmodifiable(_newUnitsUnlockedThisRun);

  List<UpgradeCard> _pendingUpgrades = [];
  List<UpgradeCard> get pendingUpgrades => _pendingUpgrades;

  int _tutorialStep = 0; // 0 = not active, 1 = Buy 1st, 2 = Buy 2nd, 3 = Merge, 4 = Ready
  int get tutorialStep => _tutorialStep;

  /// Single dynamic Next Goal resolved via GoalPresentationService (Clauses 180–183)
  NextGoalInfo get nextGoal => GoalPresentationService.resolveNextGoal(
        currentWave: _currentWave,
        highestWave: SaveSystem.currentSave.highestWave,
        save: SaveSystem.currentSave,
      );

  /// Waves remaining until next boss encounter (Clause 123)
  int get wavesUntilNextBoss {
    final nextBossWave = ((_currentWave / GameBalance.bossInterval).ceil()) * GameBalance.bossInterval;
    final diff = nextBossWave - _currentWave;
    return diff == 0 ? GameBalance.bossInterval : diff;
  }

  /// Skips the preparation countdown and immediately enters active combat (Clauses 329–330, 343)
  void skipPrepCountdown() {
    if (_state == GameState.preparingWave) {
      _countdownRemaining = 0.0;
      _state = GameState.playing;
      notifyListeners();
    }
  }

  /// Starts a fresh combat run for the specified mode (Clauses 281, 299, 326).
  void startRun({GameMode mode = GameMode.normal, bool forceTutorial = false}) {
    _activeMode = mode;
    _isBossRushVictory = false;
    _bossRushRound = 1;
    final save = SaveSystem.currentSave;
    upgrades.initFromSave(save);

    // Clause 107 & 326: Starting Cash
    final startingCoinBonus = save.permStartingCoinsLevel * 10;
    if (_activeMode == GameMode.bossRush) {
      economy.reset(startingCoinBonus, GameBalance.bossRushStartingCoins);
    } else {
      economy.reset(startingCoinBonus);
    }

    _maxBaseHp = GameBalance.baseStartingHp + upgrades.maxBaseHpBonus;
    _baseHp = _maxBaseHp;
    _currentWave = 1;
    _killsThisRun = 0;
    _bossesDefeatedThisRun = 0;
    _scrapEarnedThisRun = 0;
    _isBossIncoming = (_activeMode == GameMode.bossRush) || (_currentWave % GameBalance.bossInterval == 0);
    _showMidWaveWarning = false;
    _bossDefeatedBannerText = null;
    _liveNewBestBannerText = null;
    _newModeUnlockedBannerText = null;
    _justCelebratedHighScore = false;
    _isNewHighScore = false;
    _newUnitsUnlockedThisRun = [];

    _activeChaosModifier = ChaosModifier.none;

    // Reset run-scoped rewarded ad states (Clauses 441, 503, 580, 581)
    _currentRunId = '${DateTime.now().microsecondsSinceEpoch}_${++_runSequence}';
    _runRewardedCount = 0;
    _supplyDropUsedThisRun = false;
    _secondChanceUsedThisRun = false;
    _extraScrapUsedThisRun = false;
    _extraScrapAwardedThisRun = false;
    _isGracePeriodActive = false;
    _gracePeriodRemaining = 0.0;
    _pendingSupplyCoins = 0;
    _isRewardedAdShowing = false;
    _savedPrepCountdown = null;

    if (!save.tutorialCompleted && _activeMode == GameMode.normal || forceTutorial) {
      _state = GameState.tutorial;
      _tutorialStep = 1;
    } else {
      _state = GameState.preparingWave;
      _countdownRemaining = (_activeMode == GameMode.bossRush)
          ? GameBalance.bossRushInitialPrepSeconds
          : GameBalance.waveCountdownSeconds;
    }

    AnalyticsService.instance.logGameStarted();
    AnalyticsService.instance.logModeStarted(_activeMode.name);

    notifyListeners();
  }

  void advanceTutorialStep(int newStep) {
    _tutorialStep = newStep;
    if (_tutorialStep > 3) {
      // Tutorial completed
      final save = SaveSystem.currentSave.copyWith(tutorialCompleted: true);
      SaveSystem.save(save);
      _state = GameState.preparingWave;
      _countdownRemaining = GameBalance.waveCountdownSeconds;
      AnalyticsService.instance.logTutorialCompleted();
    }
    notifyListeners();
  }

  void updateCountdown(double dt) {
    // Tick Second Chance enemy grace period (Clauses 473, 474)
    if (_isGracePeriodActive) {
      _gracePeriodRemaining -= dt;
      if (_gracePeriodRemaining <= 0) {
        _isGracePeriodActive = false;
        notifyListeners();
      }
    }

    // Freeze countdown while rewarded ad is displaying (Clause 461)
    if (_isRewardedAdShowing) return;

    if (_state == GameState.preparingWave) {
      _countdownRemaining -= dt;
      if (_countdownRemaining <= 0) {
        _countdownRemaining = 0;
        _state = GameState.playing;
        AnalyticsService.instance.logWaveStarted(_currentWave, _activeMode.name);
        notifyListeners();
      }
    }

    if (_showMidWaveWarning) {
      _midWaveWarningTimer -= dt;
      if (_midWaveWarningTimer <= 0) {
        _showMidWaveWarning = false;
        notifyListeners();
      }
    }

    if (_newModeUnlockedBannerText != null) {
      _newModeUnlockedTimer -= dt;
      if (_newModeUnlockedTimer <= 0) {
        _newModeUnlockedBannerText = null;
        notifyListeners();
      }
    }

    if (_bossDefeatedBannerText != null) {
      _bossDefeatedTimer -= dt;
      if (_bossDefeatedTimer <= 0) {
        _bossDefeatedBannerText = null;
        notifyListeners();
      }
    }

    if (_liveNewBestBannerText != null) {
      _liveNewBestTimer -= dt;
      if (_liveNewBestTimer <= 0) {
        _liveNewBestBannerText = null;
        notifyListeners();
      }
    }
  }

  void triggerMidWaveBossWarning() {
    _showMidWaveWarning = true;
    _midWaveWarningTimer = 1.4;
    AudioManager.instance.playBossWarning();
    AnalyticsService.instance.logBossStarted(_currentWave);
    notifyListeners();
  }

  void onWaveCleared() {
    AudioManager.instance.playCoin();
    AnalyticsService.instance.logWaveCompleted(_currentWave, _activeMode.name);

    // In Boss Rush: check victory or advance round (Clauses 331, 342, 346)
    if (_activeMode == GameMode.bossRush) {
      if (_bossRushRound >= GameBalance.bossRushTotalRounds) {
        _triggerBossRushVictory();
        return;
      } else {
        _bossRushRound++;
        _currentWave = _bossRushRound;
        _pendingUpgrades = upgrades.drawThreeCards();
        _state = GameState.upgradeSelection;
        notifyListeners();
        return;
      }
    }

    _currentWave++;

    // In Chaos: roll next modifier (resetting previous, Clauses 301–314, 373)
    if (_activeMode == GameMode.chaos) {
      _activeChaosModifier = ChaosModifier.resolveForWave(
        _currentWave,
        previousType: _activeChaosModifier.type,
      );
    }

    // Live In-Combat New Best Wave celebration (Clauses 199–201)
    final save = SaveSystem.currentSave;
    final currentBest = (_activeMode == GameMode.chaos) ? save.bestChaosWave : save.highestWave;
    if (currentBest > 1 && _currentWave > currentBest && !_justCelebratedHighScore) {
      _justCelebratedHighScore = true;
      _liveNewBestBannerText = '★ NEW BEST: WAVE $_currentWave! ★';
      _liveNewBestTimer = 2.2;
      AudioManager.instance.playMerge();
    }

    // Check if Roguelite upgrade should trigger (every 3 waves: 3, 6, 9, 12... Clause 86)
    if ((_currentWave - 1) % GameBalance.upgradeInterval == 0) {
      _pendingUpgrades = upgrades.drawThreeCards();
      _state = GameState.upgradeSelection;
    } else {
      _prepareNextWave();
    }
    notifyListeners();
  }

  void chooseUpgrade(UpgradeCard card) {
    upgrades.applyUpgrade(card);
    AnalyticsService.instance.logUpgradeSelected(card.type.name);

    if (card.type == UpgradeType.fortifiedBase) {
      _maxBaseHp += card.valueMultiplier;
      _baseHp = (_baseHp + card.valueMultiplier).clamp(0.0, _maxBaseHp);
    } else if (card.type == UpgradeType.fieldRepair) {
      final healAmount = _maxBaseHp * card.valueMultiplier;
      _baseHp = (_baseHp + healAmount).clamp(0.0, _maxBaseHp);
    }

    _pendingUpgrades = [];
    _prepareNextWave();
    notifyListeners();
  }

  void _prepareNextWave() {
    if (_activeMode == GameMode.bossRush) {
      _isBossIncoming = true;
      _state = GameState.preparingWave;
      _countdownRemaining = GameBalance.bossRushInterRoundPrepSeconds; // 3.0s
    } else {
      _isBossIncoming = (_currentWave % GameBalance.bossInterval == 0);
      if (_isBossIncoming) {
        AudioManager.instance.playBossWarning();
      }
      _state = GameState.preparingWave;
      // Clause 84: Wave 1 full countdown, subsequent waves short banner
      _countdownRemaining = (_currentWave == 1)
          ? GameBalance.waveCountdownSeconds
          : GameBalance.waveShortBannerSeconds;
    }
  }

  void onEnemyKilled(int coinReward) {
    _killsThisRun++;
    final bonus = (coinReward * upgrades.coinBonusMultiplier).round();
    economy.addCoins(bonus);
    notifyListeners();
  }

  void onBossDefeated(int coinReward) {
    _bossesDefeatedThisRun++;
    _killsThisRun++;
    final bonus = (coinReward * upgrades.coinBonusMultiplier).round();
    economy.addCoins(bonus);

    _bossDefeatedBannerText = '+$bonus';
    _bossDefeatedTimer = 1.0;
    AnalyticsService.instance.logBossDefeated(_currentWave);

    // Check mode unlocks in NORMAL mode only (Clauses 283–288)
    if (_activeMode == GameMode.normal) {
      final save = SaveSystem.currentSave;
      if (_currentWave == 5 && !save.chaosUnlocked) {
        final updated = save.copyWith(chaosUnlocked: true);
        SaveSystem.save(updated);
        _newModeUnlockedBannerText = 'NEW MODE UNLOCKED!\nCHAOS';
        _newModeUnlockedTimer = 2.5;
        AudioManager.instance.playMerge();
      } else if (_currentWave == 10 && !save.bossRushUnlocked) {
        final updated = save.copyWith(bossRushUnlocked: true);
        SaveSystem.save(updated);
        _newModeUnlockedBannerText = 'NEW MODE UNLOCKED!\nBOSS RUSH';
        _newModeUnlockedTimer = 2.5;
        AudioManager.instance.playMerge();
      }
    }

    notifyListeners();
  }

  void damageBase(double damage) {
    if (_state != GameState.playing && _state != GameState.preparingWave) return;

    _baseHp = (_baseHp - damage).clamp(0.0, _maxBaseHp);
    AudioManager.instance.playBaseDamage();

    if (_baseHp <= 0) {
      if (canOfferSecondChance) {
        _state = GameState.awaitingSecondChance;
      } else {
        _triggerGameOver();
      }
    }
    notifyListeners();
  }

  void _triggerGameOver() {
    _state = GameState.gameOver;
    AudioManager.instance.playGameOver();

    final save = SaveSystem.currentSave;
    int finalScrap = 0;
    bool isNewBest = false;

    if (_activeMode == GameMode.normal) {
      finalScrap = GameBalance.calculateScrapReward(_currentWave, _bossesDefeatedThisRun);
      isNewBest = _currentWave > save.highestWave;
    } else if (_activeMode == GameMode.chaos) {
      finalScrap = GameBalance.calculateChaosScrapReward(_currentWave, _bossesDefeatedThisRun);
      isNewBest = _currentWave > save.bestChaosWave;
    } else {
      finalScrap = GameBalance.calculateBossRushScrapReward(_bossesDefeatedThisRun);
      isNewBest = _bossesDefeatedThisRun > save.bestBossRushRound;
    }
    _scrapEarnedThisRun = finalScrap;
    _isNewHighScore = isNewBest;

    // Unit unlock milestones are ONLY evaluated in NORMAL mode (Clauses 290, 322, 350)
    _newUnitsUnlockedThisRun = [];
    final finalHighestNormal = (_activeMode == GameMode.normal) ? max(save.highestWave, _currentWave) : save.highestWave;
    final finalHighestChaos = (_activeMode == GameMode.chaos) ? max(save.bestChaosWave, _currentWave) : save.bestChaosWave;
    final finalBestBossRush = (_activeMode == GameMode.bossRush) ? max(save.bestBossRushRound, _bossesDefeatedThisRun) : save.bestBossRushRound;

    if (_activeMode == GameMode.normal) {
      if (finalHighestNormal >= GameBalance.unlockWaveShotgunner && !save.announcedUnitUnlocks.contains('Shotgunner')) {
        _newUnitsUnlockedThisRun.add('Shotgunner');
      }
      if (finalHighestNormal >= GameBalance.unlockWaveSniper && !save.announcedUnitUnlocks.contains('Sniper')) {
        _newUnitsUnlockedThisRun.add('Sniper');
      }
      if (finalHighestNormal >= GameBalance.unlockWaveHeavyGunner && !save.announcedUnitUnlocks.contains('Heavy Gunner')) {
        _newUnitsUnlockedThisRun.add('Heavy Gunner');
      }
    }

    final updatedAnnounced = List<String>.from(save.announcedUnitUnlocks)..addAll(_newUnitsUnlockedThisRun);

    final updatedSave = save.copyWith(
      totalScrap: save.totalScrap + _scrapEarnedThisRun,
      highestWave: finalHighestNormal,
      bestChaosWave: finalHighestChaos,
      bestBossRushRound: finalBestBossRush,
      totalKills: save.totalKills + _killsThisRun,
      totalBossesKilled: save.totalBossesKilled + _bossesDefeatedThisRun,
      runsPlayed: save.runsPlayed + 1,
      announcedUnitUnlocks: updatedAnnounced,
    );
    SaveSystem.save(updatedSave);

    AnalyticsService.instance.logGameOver(_currentWave, _activeMode.name, _scrapEarnedThisRun);
    AnalyticsService.instance.logModeFinished(_activeMode.name, false, _currentWave);

    notifyListeners();
  }

  void _triggerBossRushVictory() {
    _state = GameState.gameOver;
    _isBossRushVictory = true;
    AudioManager.instance.playMerge();

    final save = SaveSystem.currentSave;
    _bossesDefeatedThisRun = GameBalance.bossRushTotalRounds; // 5
    _scrapEarnedThisRun = GameBalance.calculateBossRushScrapReward(5); // 50
    _isNewHighScore = 5 > save.bestBossRushRound;

    final updatedSave = save.copyWith(
      totalScrap: save.totalScrap + _scrapEarnedThisRun,
      bestBossRushRound: 5,
      totalKills: save.totalKills + _killsThisRun,
      totalBossesKilled: save.totalBossesKilled + _bossesDefeatedThisRun,
      runsPlayed: save.runsPlayed + 1,
    );
    SaveSystem.save(updatedSave);

    AnalyticsService.instance.logModeFinished('bossRush', true, 5);

    notifyListeners();
  }

  void healBase(double amount) {
    _baseHp = (_baseHp + amount).clamp(0.0, _maxBaseHp);
    notifyListeners();
  }

  void returnToMenu() {
    _state = GameState.menu;
    notifyListeners();
  }

  void pauseGame() {
    if (_state == GameState.playing || _state == GameState.preparingWave) {
      _state = GameState.paused;
      notifyListeners();
    }
  }

  void resumeGame() {
    if (_state == GameState.paused) {
      _state = GameState.playing;
      notifyListeners();
    }
  }

  // --- DEBUG METHODS ---
  void debugSkipWave() {
    onWaveCleared();
  }

  void debugKillBase() {
    damageBase(_baseHp);
  }

  // ponytail: debug helper to simulate 60s cooldown expiration in test harnesses
  void debugResetAdCooldown() {
    _lastRewardedAdCompletedTimestamp = null;
  }

  // --- REWARDED ADS ACTIONS (Clauses 449–491, 556–561) ---

  /// Claims Supply Drop coin aid (Clauses 449–461)
  void claimSupplyDrop() {
    if (!canOfferSupplyDrop || _isRewardedAdShowing) return;
    _isRewardedAdShowing = true;
    final targetRunId = _currentRunId;
    _pendingSupplyCoins = economy.nextUnitCost;

    // Clause 461: Pause Boss Rush preparation timer while ad is showing
    if (_activeMode == GameMode.bossRush && _state == GameState.preparingWave) {
      _savedPrepCountdown = _countdownRemaining;
    }

    RewardedAdService.instance.showAd(
      placement: RewardedPlacement.supplyDrop,
      onUserEarnedReward: () {
        if (_currentRunId != targetRunId || _supplyDropUsedThisRun) return;
        economy.addCoins(_pendingSupplyCoins);
        _supplyDropUsedThisRun = true;
        _recordSuccessfulAd();
      },
      onAdDismissed: () {
        _isRewardedAdShowing = false;
        if (_savedPrepCountdown != null) {
          _countdownRemaining = _savedPrepCountdown!;
          _savedPrepCountdown = null;
        }
        notifyListeners();
      },
      onAdFailed: (error) {
        _isRewardedAdShowing = false;
        if (_savedPrepCountdown != null) {
          _countdownRemaining = _savedPrepCountdown!;
          _savedPrepCountdown = null;
        }
        notifyListeners();
      },
    );
  }

  /// Claims Second Chance 50% HP revive and activates 3.0s grace period (Clauses 462–480)
  void claimSecondChance() {
    if (!canOfferSecondChance || _isRewardedAdShowing) return;
    _isRewardedAdShowing = true;
    final targetRunId = _currentRunId;

    RewardedAdService.instance.showAd(
      placement: RewardedPlacement.secondChance,
      onUserEarnedReward: () {
        if (_currentRunId != targetRunId || _secondChanceUsedThisRun) return;
        _baseHp = (_maxBaseHp * AdConfig.secondChanceHpPercent).ceilToDouble();
        _isGracePeriodActive = true;
        _gracePeriodRemaining = AdConfig.secondChanceGraceSeconds;
        _state = GameState.playing;
        _secondChanceUsedThisRun = true;
        _recordSuccessfulAd();
      },
      onAdDismissed: () {
        _isRewardedAdShowing = false;
        notifyListeners();
      },
      onAdFailed: (error) {
        _isRewardedAdShowing = false;
        notifyListeners();
      },
    );
  }

  /// Rejects Second Chance and transitions immediately to Game Over (Clause 469)
  void dismissSecondChance() {
    _secondChanceUsedThisRun = true;
    _triggerGameOver();
  }

  /// Claims Extra Scrap (2x run scrap) and immediately persists to storage (Clauses 481–491, 542–544)
  void claimExtraScrap() {
    if (!canOfferExtraScrap || _isRewardedAdShowing) return;
    _isRewardedAdShowing = true;
    final targetRunId = _currentRunId;

    RewardedAdService.instance.showAd(
      placement: RewardedPlacement.extraScrap,
      onUserEarnedReward: () {
        if (_currentRunId != targetRunId || _extraScrapUsedThisRun) return;
        final extraScrap = _scrapEarnedThisRun;
        final save = SaveSystem.currentSave;
        SaveSystem.save(save.copyWith(totalScrap: save.totalScrap + extraScrap));
        _extraScrapUsedThisRun = true;
        _extraScrapAwardedThisRun = true;
        _recordSuccessfulAd();
      },
      onAdDismissed: () {
        _isRewardedAdShowing = false;
        notifyListeners();
      },
      onAdFailed: (error) {
        _isRewardedAdShowing = false;
        notifyListeners();
      },
    );
  }

  void _recordSuccessfulAd() {
    _runRewardedCount++;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    _lastRewardedAdCompletedTimestamp = now;
    final save = SaveSystem.currentSave.withAdCompletion(now);
    SaveSystem.save(save);
    _isRewardedAdShowing = false;
    notifyListeners();
  }
}
