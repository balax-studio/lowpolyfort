import 'package:flutter/foundation.dart';

/// Recorded telemetry event structure for tracking and testing.
class AnalyticsEvent {
  final String name;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;

  AnalyticsEvent(this.name, [this.parameters = const {}])
      : timestamp = DateTime.now();

  @override
  String toString() => '$name: $parameters';
}

/// Decoupled, fail-safe analytics telemetry engine (Clauses 685–689, 706).
/// Emits exactly the 17 core lifecycle events. Failure never interrupts or crashes gameplay.
class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._();
  AnalyticsService._();

  final List<AnalyticsEvent> _eventLog = [];

  /// In-memory log of dispatched events (retained for verification & telemetry inspection).
  List<AnalyticsEvent> get eventLog => List.unmodifiable(_eventLog);

  void clearLogForTesting() {
    _eventLog.clear();
  }

  void _log(String eventName, [Map<String, dynamic> params = const {}]) {
    try {
      final event = AnalyticsEvent(eventName, params);
      _eventLog.add(event);
      if (kDebugMode) {
        debugPrint('[Analytics] $eventName $params');
      }
    } catch (_) {
      // Clause 687, 706: Analytics failures must NEVER cause a crash or alter gameplay state.
    }
  }

  // --- 17 CORE ANALYTICS EVENTS (Clause 688) ---

  void logGameStarted() => _log('game_started');

  void logTutorialCompleted() => _log('tutorial_completed');

  void logWaveStarted(int wave, String mode) => _log('wave_started', {'wave': wave, 'mode': mode});

  void logWaveCompleted(int wave, String mode) => _log('wave_completed', {'wave': wave, 'mode': mode});

  void logBossStarted(int wave) => _log('boss_started', {'wave': wave});

  void logBossDefeated(int wave) => _log('boss_defeated', {'wave': wave});

  void logUnitPurchased(String unitClass, int cost) => _log('unit_purchased', {'class': unitClass, 'cost': cost});

  void logUnitMerged(String unitClass, int newLevel) => _log('unit_merged', {'class': unitClass, 'new_level': newLevel});

  void logUpgradeSelected(String upgradeKey) => _log('upgrade_selected', {'upgrade_key': upgradeKey});

  void logGameOver(int wave, String mode, int scrapEarned) =>
      _log('game_over', {'wave': wave, 'mode': mode, 'scrap': scrapEarned});

  void logRetryPressed() => _log('retry_pressed');

  void logModeStarted(String mode) => _log('mode_started', {'mode': mode});

  void logModeFinished(String mode, bool victory, int score) =>
      _log('mode_finished', {'mode': mode, 'victory': victory, 'score': score});

  void logRewardedOfferShown(String placement) => _log('rewarded_offer_shown', {'placement': placement});

  void logRewardedOfferClicked(String placement) => _log('rewarded_offer_clicked', {'placement': placement});

  void logRewardedAdCompleted(String placement) => _log('rewarded_ad_completed', {'placement': placement});

  void logRewardedRewardGranted(String placement, dynamic reward) =>
      _log('rewarded_reward_granted', {'placement': placement, 'reward': reward});
}
