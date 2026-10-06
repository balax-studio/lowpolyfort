extends Node

const RewardedAdService = preload("res://scripts/rewarded_ad_service.gd")

## Automated test runner for Phase 15: Rewarded Ads System Parity.
## Source of truth: Flutter lib/services/rewarded_ad_service.dart & lib/constants/ad_config.dart (Clauses 426–444, 470, 473, 555).

func _ready() -> void:
	print("==================================================")
	print("--- PHASE 15: REWARDED ADS PARITY TESTS ---")
	print("==================================================")

	var all_passed = true

	# Test 1: Config constants parity with Flutter AdConfig
	if RewardedAdService.MAX_REWARDED_PER_RUN != 2:
		print("FAIL: MAX_REWARDED_PER_RUN != 2")
		all_passed = false
	if RewardedAdService.REWARDED_DAILY_CAP != 5:
		print("FAIL: REWARDED_DAILY_CAP != 5")
		all_passed = false
	if RewardedAdService.UNLOCK_WAVE_MILESTONE != 3:
		print("FAIL: UNLOCK_WAVE_MILESTONE != 3")
		all_passed = false
	if RewardedAdService.SECOND_CHANCE_HP_PERCENT != 0.50:
		print("FAIL: SECOND_CHANCE_HP_PERCENT != 0.50")
		all_passed = false
	if RewardedAdService.SECOND_CHANCE_GRACE_SECONDS != 3.0:
		print("FAIL: SECOND_CHANCE_GRACE_SECONDS != 3.0")
		all_passed = false
	print("PASS: AdConfig constants strictly match Flutter")

	# Test 2: Supply Drop eligibility gates
	SaveManager.reset_all_progress()
	GameManager.current_mode = GameManager.GameMode.NORMAL
	GameManager.reset_run()
	GameManager.state = GameManager.GameState.PLAYING

	# Ineligible: Wave < 3 and tutorial not completed
	SaveManager.highest_wave = 1
	SaveManager.tutorial_completed = false
	if GameManager.can_offer_supply_drop():
		print("FAIL: Supply drop offered with wave < 3 and tutorial incomplete")
		all_passed = false
	else:
		print("PASS: Supply drop gated behind wave milestone and tutorial")

	# Eligible state
	SaveManager.highest_wave = 4
	SaveManager.tutorial_completed = true
	GameManager.coins = 10 # Cannot afford 100 coin unit
	GameManager.last_rewarded_ad_completed_timestamp = -1.0 # Expired cooldown

	if not GameManager.can_offer_supply_drop():
		print("FAIL: Supply drop not offered when eligible")
		all_passed = false
	else:
		print("PASS: Supply drop offered when player cannot afford unit")

	# Claim Supply Drop
	var prev_coins = GameManager.coins
	var expected_cost = GameManager.get_unit_cost()
	GameManager.claim_supply_drop()

	if GameManager.coins != prev_coins + expected_cost:
		print("FAIL: Supply drop did not award unit cost coins")
		all_passed = false
	if not GameManager.supply_drop_used_this_run:
		print("FAIL: supply_drop_used_this_run not set")
		all_passed = false
	if GameManager.run_rewarded_count != 1:
		print("FAIL: run_rewarded_count != 1")
		all_passed = false
	print("PASS: Supply drop successfully claimed and tracked")

	# Test 3: Second Chance 50% HP Revive
	GameManager.base_hp = 0.0
	GameManager.current_wave = 4
	GameManager.last_rewarded_ad_completed_timestamp = -1.0 # Force cooldown expired

	if not GameManager.can_offer_second_chance():
		print("FAIL: Second chance not offered at wave 4 with HP 0")
		all_passed = false
	else:
		print("PASS: Second chance offered at Base HP zero")

	GameManager.claim_second_chance()
	if GameManager.base_hp != 500.0:
		print("FAIL: Base HP after second chance %f != 500.0" % GameManager.base_hp)
		all_passed = false
	if GameManager.state != GameManager.GameState.PLAYING:
		print("FAIL: GameState not restored to PLAYING after second chance")
		all_passed = false
	if GameManager.run_rewarded_count != 2:
		print("FAIL: run_rewarded_count != 2")
		all_passed = false
	print("PASS: Second chance restored 50% max HP and resumed combat")

	# Test 4: Run Rewarded Cap (Max 2 per run)
	if GameManager.can_offer_extra_scrap():
		print("FAIL: Extra scrap offered after 2 ads already completed this run")
		all_passed = false
	else:
		print("PASS: Run cap (max 2 per run) strictly blocks 3rd ad")

	# Test 5: Extra Scrap in a fresh run
	GameManager.reset_run()
	GameManager.scrap_earned_this_run = 20
	SaveManager.total_scrap = 100
	GameManager.last_rewarded_ad_completed_timestamp = -1.0

	if not GameManager.can_offer_extra_scrap():
		print("FAIL: Extra scrap not offered on fresh run with scrap > 0")
		all_passed = false
	else:
		print("PASS: Extra scrap offered on Game Over summary")

	GameManager.claim_extra_scrap()
	if SaveManager.total_scrap != 120:
		print("FAIL: Total scrap %d != 120 after claiming extra scrap" % SaveManager.total_scrap)
		all_passed = false
	if not GameManager.extra_scrap_used_this_run:
		print("FAIL: extra_scrap_used_this_run != true")
		all_passed = false
	print("PASS: Extra scrap doubled reward and persisted to SaveManager")

	# Test 6: Daily Cap (5 per rolling 24h)
	# Add 5 completions to SaveManager
	for i in range(5):
		SaveManager.record_ad_completion()

	GameManager.reset_run()
	GameManager.scrap_earned_this_run = 10
	GameManager.last_rewarded_ad_completed_timestamp = -1.0

	if GameManager.can_offer_extra_scrap() or GameManager.can_offer_supply_drop():
		print("FAIL: Ad offered after 5 daily ads reached")
		all_passed = false
	else:
		print("PASS: Daily cap (5/rolling 24h) strictly enforced")

	# Clean up
	SaveManager.reset_all_progress()

	if all_passed:
		print(">>> ALL PHASE 15 PARITY TESTS PASSED! <<<")
		get_tree().quit(0)
	else:
		print(">>> SOME PHASE 15 PARITY TESTS FAILED! <<<")
		get_tree().quit(1)
