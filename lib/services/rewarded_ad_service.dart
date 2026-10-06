import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../constants/ad_config.dart';
import '../models/rewarded_placement.dart';
import '../managers/audio_manager.dart';
import 'analytics_service.dart';

/// Centralized Rewarded Ad service (Clauses 430–439, 498–505, 539–541).
/// Manages SDK initialization, preloading, presentation callbacks, and audio ducking.
/// Includes a platform-safe fallback driver for desktop, web, and automated tests.
class RewardedAdService {
  static final RewardedAdService instance = RewardedAdService._();
  RewardedAdService._();

  RewardedAd? _rewardedAd;
  bool _isLoading = false;
  bool _isShowingAd = false;
  bool _isInitialized = false;

  // Mock driver support for unit tests and non-mobile platforms
  bool _mockDriverEnabled = false;
  bool _mockAdReady = true;

  bool get isShowingAd => _isShowingAd;

  bool get isAdReady {
    if (_mockDriverEnabled || !isMobilePlatform) {
      return _mockAdReady && !_isShowingAd;
    }
    return _rewardedAd != null && !_isShowingAd;
  }

  bool get isMobilePlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Enables or configures the mock driver for automated tests or desktop preview
  void setMockDriver({required bool enabled, bool adReady = true}) {
    _mockDriverEnabled = enabled;
    _mockAdReady = adReady;
  }

  /// Initializes Mobile Ads SDK and preloads the first ad (Clauses 436, 437)
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    if (!isMobilePlatform) {
      // Desktop / Web / Headless Test Harness fallback
      _mockDriverEnabled = true;
      return;
    }

    try {
      await MobileAds.instance.initialize();
      loadAd();
    } catch (_) {
      // Fail-safe: offline or SDK failure must never crash the game (Clause 539)
    }
  }

  String get _adUnitId {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AdConfig.androidRewardedTestAdUnitId;
    } else {
      return AdConfig.iosRewardedTestAdUnitId;
    }
  }

  /// Preloads a rewarded ad instance in the background (Clause 437)
  void loadAd() {
    if (_mockDriverEnabled || !isMobilePlatform) return;
    if (_isLoading || _rewardedAd != null) return;

    _isLoading = true;
    try {
      RewardedAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isLoading = false;
          },
          onAdFailedToLoad: (error) {
            _rewardedAd = null;
            _isLoading = false;
          },
        ),
      );
    } catch (_) {
      _isLoading = false;
    }
  }

  /// Presents a rewarded ad with lifecycle safeguards, audio ducking, and callbacks (Clauses 498-505)
  Future<void> showAd({
    required RewardedPlacement placement,
    required void Function() onUserEarnedReward,
    void Function()? onAdDismissed,
    void Function(String error)? onAdFailed,
    bool simulateRewardInMock = true,
  }) async {
    if (_isShowingAd) return; // Double-tap guard (Clause 501)
    if (!isAdReady) {
      onAdFailed?.call('Ad not ready');
      return;
    }

    _isShowingAd = true;
    // Duck game audio during ad presentation (Clause 548)
    AudioManager.instance.pauseMusic();

    AnalyticsService.instance.logRewardedOfferShown(placement.name);
    AnalyticsService.instance.logRewardedOfferClicked(placement.name);

    if (_mockDriverEnabled || !isMobilePlatform) {
      // Synchronous/immediate mock flow for testing & development
      if (simulateRewardInMock) {
        AnalyticsService.instance.logRewardedAdCompleted(placement.name);
        AnalyticsService.instance.logRewardedRewardGranted(placement.name, placement.name);
        onUserEarnedReward();
      }
      _isShowingAd = false;
      AudioManager.instance.resumeMusic();
      onAdDismissed?.call();
      return;
    }

    final ad = _rewardedAd;
    if (ad == null) {
      _isShowingAd = false;
      AudioManager.instance.resumeMusic();
      onAdFailed?.call('No loaded ad available');
      loadAd();
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        ad.dispose();
        _rewardedAd = null;
        AudioManager.instance.resumeMusic();
        onAdDismissed?.call();
        // Automatically preload the next ad (Clause 437)
        loadAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
        ad.dispose();
        _rewardedAd = null;
        AudioManager.instance.resumeMusic();
        onAdFailed?.call(error.message);
        loadAd();
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (_, reward) {
          AnalyticsService.instance.logRewardedAdCompleted(placement.name);
          AnalyticsService.instance.logRewardedRewardGranted(placement.name, placement.name);
          onUserEarnedReward();
        },
      );
    } catch (e) {
      _isShowingAd = false;
      ad.dispose();
      _rewardedAd = null;
      AudioManager.instance.resumeMusic();
      onAdFailed?.call(e.toString());
      loadAd();
    }
  }

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
