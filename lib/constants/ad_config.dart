/// Central configuration for Rewarded Ads monetization (Clauses 434–435, 440–444, 446, 470, 473, 555).
/// Holds calibrated test IDs, pacing limits, and reward formulas.
class AdConfig {
  AdConfig._();

  // Official Google AdMob sample test unit IDs (Clauses 434-435)
  static const String androidRewardedTestAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const String iosRewardedTestAdUnitId = 'ca-app-pub-3940256099942544/1712485313';

  // Monetization frequency caps & pacing (Clauses 440-444)
  static const int maxRewardedPerRun = 2; // Max 2 completed rewarded ads per run
  static const int rewardedDailyCap = 5; // Max 5 completed ads in rolling 24 hours
  static const int rewardedGlobalCooldownSeconds = 60; // 60s cooldown between ad starts

  // Second Chance formulas (Clauses 470, 473, 558)
  static const double secondChanceHpPercent = 0.50; // Restores 50% max Base HP
  static const double secondChanceGraceSeconds = 3.0; // 3.0s enemy freeze upon return

  // Unlocking milestone (Clauses 446-447, 563-564)
  static const int unlockWaveMilestone = 3; // Unlocked after Normal Mode Wave 3 completed
}
