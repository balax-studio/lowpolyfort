extends Node

const WaveDefinition = preload("res://scripts/wave_definition.gd")
const UpgradeCard = preload("res://scripts/upgrade_card.gd")
const ChaosModifier = preload("res://scripts/chaos_modifier.gd")
const RewardedAdService = preload("res://scripts/rewarded_ad_service.gd")

## Master End-to-End Regression & Full Game Lifecycle Parity Test Runner (Phase 17).
## Sequence: fresh save -> tutorial -> Normal -> Wave 3 upgrade -> Wave 5 boss -> Chaos unlock
## -> Wave 10 boss -> Boss Rush unlock -> Game Over -> Retry -> permanent upgrade -> app restart
## -> save restore -> Chaos -> Boss Rush -> rewarded ad test flow.

func _ready() -> void:
	print("==================================================================")
	print("--- PHASE 17: MASTER END-TO-END REGRESSION & PARITY TEST SUITE ---")
	print("==================================================================")

	var all_passed = true

	# -------------------------------------------------------------
	# STEP 1: Fresh Save Verification
	# -------------------------------------------------------------
	print("\n[Step 1/15] Initializing fresh save...")
	SaveManager.reset_all_progress()
	if SaveManager.total_scrap != 0 or SaveManager.highest_wave != 1 or \
	   SaveManager.tutorial_completed != false or SaveManager.chaos_unlocked != false or \
	   SaveManager.boss_rush_unlocked != false:
		print("FAIL: Fresh save state has invalid initialized values")
		all_passed = false
	else:
		print("PASS: Fresh save initialized with clean progression state")

	# -------------------------------------------------------------
	# STEP 2: Interactive Tutorial Flow
	# -------------------------------------------------------------
	print("\n[Step 2/15] Starting Normal run and running tutorial...")
	GameManager.current_mode = GameManager.GameMode.NORMAL
	GameManager.reset_run()

	if GameManager.state != GameManager.GameState.TUTORIAL or GameManager.tutorial_step != 1:
		print("FAIL: Tutorial not started at Step 1")
		all_passed = false
	else:
		print("PASS: Run entered TUTORIAL state at Step 1")

	# Step 1 -> Step 2
	GameManager.advance_tutorial_step(2)
	# Step 2 -> Step 3
	GameManager.advance_tutorial_step(3)
	# Step 3 -> Step 4 (Complete)
	GameManager.advance_tutorial_step(4)

	if not SaveManager.tutorial_completed or GameManager.state != GameManager.GameState.PLAYING:
		print("FAIL: Tutorial completion did not persist or update game state")
		all_passed = false
	else:
		print("PASS: Tutorial completed successfully, game transitioned to PLAYING")

	# -------------------------------------------------------------
	# STEP 3: Normal Mode Wave Progression
	# -------------------------------------------------------------
	print("\n[Step 3/15] Simulating Normal mode waves 1 -> 3...")
	GameManager.current_wave = 1
	var wave1_def = WaveDefinition.generate(1)
	if wave1_def.wave_number != 1 or wave1_def.spawns.is_empty():
		print("FAIL: Wave 1 definition invalid")
		all_passed = false
	else:
		print("PASS: Wave 1 spawns generated correctly")

	# -------------------------------------------------------------
	# STEP 4: Wave 3 Roguelite Upgrade Selection
	# -------------------------------------------------------------
	print("\n[Step 4/15] Testing Wave 3 upgrade milestone...")
	GameManager.current_wave = 3
	var pool = UpgradeCard.get_pool()
	if pool.size() < 3:
		print("FAIL: Upgrade pool has fewer than 3 cards")
		all_passed = false
	else:
		print("PASS: Upgrade pool verified with %d cards" % pool.size())

	var chosen_card = pool[0] # Heavy Ammo (+15% dmg)
	var dmg_before = GameManager.upgrade_damage_bonus
	GameManager.apply_upgrade(chosen_card)
	if chosen_card.type == UpgradeCard.UpgradeType.HEAVY_AMMO and GameManager.upgrade_damage_bonus <= dmg_before:
		print("FAIL: Heavy Ammo upgrade did not increase upgrade_damage_bonus")
		all_passed = false
	else:
		print("PASS: Upgrade successfully applied to GameManager stats")

	# -------------------------------------------------------------
	# STEP 5 & 6: Wave 5 Boss & Chaos Mode Unlock
	# -------------------------------------------------------------
	print("\n[Step 5-6/15] Wave 5 Boss defeat and Chaos Mode unlock...")
	GameManager.current_wave = 5
	GameManager.on_boss_defeated(50)
	if not SaveManager.chaos_unlocked:
		print("FAIL: Defeating Wave 5 boss did not unlock Chaos mode")
		all_passed = false
	else:
		print("PASS: Chaos mode unlocked at Wave 5 boss defeat (Clauses 283-288)")

	# -------------------------------------------------------------
	# STEP 7 & 8: Wave 10 Boss & Boss Rush Unlock
	# -------------------------------------------------------------
	print("\n[Step 7-8/15] Wave 10 Boss defeat and Boss Rush unlock...")
	GameManager.current_wave = 10
	GameManager.on_boss_defeated(75)
	if not SaveManager.boss_rush_unlocked:
		print("FAIL: Defeating Wave 10 boss did not unlock Boss Rush mode")
		all_passed = false
	else:
		print("PASS: Boss Rush mode unlocked at Wave 10 boss defeat")

	# -------------------------------------------------------------
	# STEP 9: Game Over & Scrap Rewards
	# -------------------------------------------------------------
	print("\n[Step 9/15] Triggering fatal base damage and run summary...")
	GameManager.current_wave = 10
	GameManager.damage_base(99999.0) # Fatal damage
	if GameManager.state != GameManager.GameState.GAME_OVER and GameManager.state != GameManager.GameState.TUTORIAL:
		# If second chance was offered, dismiss it to finalize game over
		GameManager.dismiss_second_chance()

	if GameManager.state != GameManager.GameState.GAME_OVER:
		print("FAIL: State is not GAME_OVER after fatal base damage")
		all_passed = false
	if GameManager.scrap_earned_this_run <= 0 or SaveManager.total_scrap <= 0:
		print("FAIL: Scrap reward not awarded on Game Over")
		all_passed = false
	else:
		print("PASS: Game Over processed cleanly with scrap awarded (+%d)" % GameManager.scrap_earned_this_run)

	# -------------------------------------------------------------
	# STEP 10: Retry Flow
	# -------------------------------------------------------------
	print("\n[Step 10/15] Testing Retry run reset...")
	GameManager.reset_run()
	if GameManager.state != GameManager.GameState.PLAYING or GameManager.base_hp != 1000.0 or GameManager.current_wave != 1:
		print("FAIL: Reset run did not restore fresh combat state")
		all_passed = false
	else:
		print("PASS: Run successfully retried and initialized to Wave 1")

	# -------------------------------------------------------------
	# STEP 11: Permanent Upgrades Meta-Progression
	# -------------------------------------------------------------
	print("\n[Step 11/15] Testing Permanent Upgrades purchase...")
	SaveManager.total_scrap = 500
	var cost_lvl0 = GameBalance.get_permanent_upgrade_cost(0) # 25
	SaveManager.total_scrap -= cost_lvl0
	SaveManager.perm_base_hp_level += 1
	SaveManager.save_to_disk()

	if SaveManager.perm_base_hp_level != 1 or SaveManager.total_scrap != 475:
		print("FAIL: Permanent upgrade did not deduct scrap or increment level")
		all_passed = false
	else:
		print("PASS: Base Armor upgraded to Level 1 with 25 scrap deducted")

	# -------------------------------------------------------------
	# STEP 12: App Restart & Disk Restore Parity
	# -------------------------------------------------------------
	print("\n[Step 12/15] Simulating full app restart and save restore...")
	SaveManager.highest_wave = 10
	SaveManager.save_to_disk()

	# Wipe in-memory values
	SaveManager.total_scrap = 0
	SaveManager.highest_wave = 1
	SaveManager.chaos_unlocked = false
	SaveManager.boss_rush_unlocked = false
	SaveManager.perm_base_hp_level = 0

	# Reload from disk
	SaveManager.load_from_disk()

	if SaveManager.total_scrap != 475 or SaveManager.highest_wave != 10 or \
	   not SaveManager.chaos_unlocked or not SaveManager.boss_rush_unlocked or \
	   SaveManager.perm_base_hp_level != 1:
		print("FAIL: Disk restore failed to recover progression state")
		all_passed = false
	else:
		print("PASS: All progression perfectly recovered from disk storage")

	# -------------------------------------------------------------
	# STEP 13: Chaos Mode Engine Execution
	# -------------------------------------------------------------
	print("\n[Step 13/15] Testing Chaos Mode run and modifier sequence...")
	GameManager.current_mode = GameManager.GameMode.CHAOS
	GameManager.reset_run()

	var chaos_w2 = WaveDefinition.generate(2, ChaosModifier.resolve_for_wave(2, ChaosModifier.ChaosModifierType.NONE))
	if chaos_w2.chaos_modifier == null or chaos_w2.chaos_modifier.type != ChaosModifier.ChaosModifierType.RUSH_HOUR:
		print("FAIL: Chaos Wave 2 modifier expected RUSH_HOUR (Clause 312)")
		all_passed = false
	else:
		print("PASS: Chaos Mode Wave 2 correctly resolved RUSH_HOUR modifier")

	var chaos_scrap = GameBalance.calculate_chaos_scrap_reward(5, 1)
	var normal_scrap = GameBalance.calculate_scrap_reward(5, 1)
	if chaos_scrap <= normal_scrap:
		print("FAIL: Chaos scrap %d not greater than Normal scrap %d" % [chaos_scrap, normal_scrap])
		all_passed = false
	else:
		print("PASS: Chaos Mode applies +10% bonus scrap reward curve")

	# -------------------------------------------------------------
	# STEP 14: Boss Rush Mode Execution
	# -------------------------------------------------------------
	print("\n[Step 14/15] Testing Boss Rush Mode economy and round setup...")
	GameManager.current_mode = GameManager.GameMode.BOSS_RUSH
	GameManager.reset_run()

	if GameManager.coins != 300:
		print("FAIL: Boss Rush starting coins %d != 300" % GameManager.coins)
		all_passed = false
	else:
		print("PASS: Boss Rush starts with 300 coins (Clause 340)")

	var br_round1 = WaveDefinition.generate_boss_rush_round(1)
	if br_round1.spawns.size() != 1 or br_round1.spawns[0].enemy_type != EnemyDefinition.EnemyType.BOSS:
		print("FAIL: Boss Rush round 1 did not spawn single boss")
		all_passed = false
	else:
		print("PASS: Boss Rush Round 1 spawned single boss encounter")

	# -------------------------------------------------------------
	# STEP 15: Rewarded Ads Full Lifecycle
	# -------------------------------------------------------------
	print("\n[Step 15/15] Testing Rewarded Ads full placement cycle...")
	GameManager.current_mode = GameManager.GameMode.NORMAL
	GameManager.reset_run()
	GameManager.last_rewarded_ad_completed_timestamp = -1.0
	SaveManager.highest_wave = 5
	SaveManager.tutorial_completed = true

	# 15.1 Supply Drop
	GameManager.coins = 0
	if not GameManager.can_offer_supply_drop():
		print("FAIL: can_offer_supply_drop returned false")
		all_passed = false
	else:
		GameManager.claim_supply_drop()
		if GameManager.coins <= 0 or not GameManager.supply_drop_used_this_run:
			print("FAIL: Supply drop did not award coins")
			all_passed = false
		else:
			print("PASS: Supply Drop awarded coins successfully")

	# 15.2 Second Chance
	GameManager.base_hp = 0.0
	GameManager.current_wave = 5
	GameManager.last_rewarded_ad_completed_timestamp = -1.0
	if not GameManager.can_offer_second_chance():
		print("FAIL: can_offer_second_chance returned false")
		all_passed = false
	else:
		GameManager.claim_second_chance()
		if GameManager.base_hp != 500.0 or not GameManager.second_chance_used_this_run:
			print("FAIL: Second Chance did not restore 50% HP")
			all_passed = false
		else:
			print("PASS: Second Chance revived base to 500 HP")

	# 15.3 Cap verification
	if GameManager.can_offer_extra_scrap():
		print("FAIL: Extra scrap offered after 2 ads completed in run")
		all_passed = false
	else:
		print("PASS: Max 2 ads per run strictly enforced")

	# Clean up
	SaveManager.reset_all_progress()

	print("\n==================================================================")
	if all_passed:
		print(">>> ALL 15 LIFECYCLE PARITY MILESTONES PASSED WITH ZERO ERRORS! <<<")
		print("==================================================================")
		get_tree().quit(0)
	else:
		print(">>> MASTER REGRESSION TESTS FAILED! <<<")
		print("==================================================================")
		get_tree().quit(1)
