class_name RewardedAdService
extends RefCounted

## Centralized Rewarded Ad service and AdConfig constants.
## Source of truth: Flutter lib/services/rewarded_ad_service.dart & lib/constants/ad_config.dart (Clauses 426–444, 470, 473, 555).

# Official Google AdMob sample test unit IDs (Clauses 434-435)
const ANDROID_REWARDED_TEST_AD_UNIT_ID = "ca-app-pub-3940256099942544/5224354917"
const IOS_REWARDED_TEST_AD_UNIT_ID = "ca-app-pub-3940256099942544/1712485313"

# Monetization frequency caps & pacing (Clauses 440-444)
const MAX_REWARDED_PER_RUN: int = 2 # Max 2 completed rewarded ads per run
const REWARDED_DAILY_CAP: int = 5 # Max 5 completed ads in rolling 24 hours
const REWARDED_GLOBAL_COOLDOWN_SECONDS: float = 60.0 # 60s cooldown between ad starts

# Second Chance formulas (Clauses 470, 473, 558)
const SECOND_CHANCE_HP_PERCENT: float = 0.50 # Restores 50% max Base HP
const SECOND_CHANCE_GRACE_SECONDS: float = 3.0 # 3.0s enemy freeze upon return

# Unlocking milestone (Clauses 446-447, 563-564)
const UNLOCK_WAVE_MILESTONE: int = 3 # Unlocked after Normal Mode Wave 3 completed

# Strictly permitted Rewarded Ad placements (Clauses 426, 432)
enum RewardedPlacement {
	SUPPLY_DROP,
	SECOND_CHANCE,
	EXTRA_SCRAP
}

static var _mock_driver_enabled: bool = true
static var _mock_ad_ready: bool = true
static var _is_showing_ad: bool = false

static func is_ad_ready() -> bool:
	return _mock_ad_ready and not _is_showing_ad

static func set_mock_driver(enabled: bool, ad_ready: bool = true) -> void:
	_mock_driver_enabled = enabled
	_mock_ad_ready = ad_ready

static func show_ad(
	placement: RewardedPlacement,
	on_reward: Callable,
	on_dismiss: Callable = Callable(),
	on_failed: Callable = Callable()
) -> void:
	if _is_showing_ad:
		return
	if not is_ad_ready():
		if on_failed.is_valid():
			on_failed.call("Ad not ready")
		return

	_is_showing_ad = true

	# Immediate mock presentation for test harness / desktop (Clauses 498-505)
	if on_reward.is_valid():
		on_reward.call()

	_is_showing_ad = false
	if on_dismiss.is_valid():
		on_dismiss.call()
