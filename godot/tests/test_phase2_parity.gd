extends SceneTree

func _init() -> void:
	print("--- BEGIN TEST PHASE 2: PERSISTENT SAVE & META-PROGRESSION ---")
	var failed: int = 0

	var sm = load("res://scripts/save_manager.gd").new()
	sm.save_file_path = "user://test_save_data.json"
	
	# Clean up any leftover test save
	if FileAccess.file_exists(sm.save_file_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(sm.save_file_path))

	# 1. Reset & Defaults
	sm.reset_all()
	if sm.total_scrap != 0 or sm.highest_wave != 1 or sm.tutorial_completed != false:
		print("FAIL: Defaults mismatch! scrap=%d, wave=%d, tut=%s" % [sm.total_scrap, sm.highest_wave, sm.tutorial_completed])
		failed += 1
	else:
		print("PASS: Fresh save default values verified")

	# 2. Modify values and Save to disk
	sm.total_scrap = 120
	sm.highest_wave = 12
	sm.total_kills = 85
	sm.total_bosses_killed = 2
	sm.perm_base_hp_level = 3
	sm.perm_starting_coins_level = 2
	sm.save_to_disk()

	# 3. Reload into fresh instance
	var sm2 = load("res://scripts/save_manager.gd").new()
	sm2.save_file_path = "user://test_save_data.json"
	var load_ok = sm2.load_from_disk()
	if not load_ok or sm2.total_scrap != 120 or sm2.highest_wave != 12 or sm2.perm_base_hp_level != 3:
		print("FAIL: Persistence reload mismatch! ok=%s, scrap=%d, wave=%d" % [load_ok, sm2.total_scrap, sm2.highest_wave])
		failed += 1
	else:
		print("PASS: Persistent JSON save and load verified successfully")

	# 4. Mode unlocks from wave milestones
	# highest_wave = 12 should unlock Chaos (>5) and Boss Rush (>10)
	if not sm2.chaos_unlocked or not sm2.boss_rush_unlocked:
		print("FAIL: Mode unlocks from wave milestone failed! chaos=%s, bossRush=%s" % [sm2.chaos_unlocked, sm2.boss_rush_unlocked])
		failed += 1
	else:
		print("PASS: Wave milestone mode unlocks verified (Wave 12 unlocks Chaos & Boss Rush)")

	# 5. Unit unlocks check
	var unlocked = sm2.get_unlocked_hero_classes()
	if not unlocked.has(HeroDefinition.HeroClass.RIFLEMAN) or not unlocked.has(HeroDefinition.HeroClass.SHOTGUNNER) or not unlocked.has(HeroDefinition.HeroClass.SNIPER) or unlocked.has(HeroDefinition.HeroClass.HEAVY_GUNNER):
		print("FAIL: Unlocked hero classes mismatch at wave 12: %s" % [unlocked])
		failed += 1
	else:
		print("PASS: Dynamic hero unlock milestones verified (Rifleman, Shotgunner, Sniper unlocked; Heavy Gunner locked until W15)")

	# 6. Rewarded Ad Rolling 24h Window
	var now = Time.get_unix_time_from_system() * 1000.0
	var old_ts = int(now - (25.0 * 3600.0 * 1000.0)) # 25 hours ago (expired)
	var recent_ts1 = int(now - (2.0 * 3600.0 * 1000.0)) # 2 hours ago (valid)
	var recent_ts2 = int(now - (10.0 * 60.0 * 1000.0)) # 10 mins ago (valid)
	
	sm2.rewarded_ad_completion_timestamps = [old_ts, recent_ts1, recent_ts2]
	sm2.save_to_disk()
	
	var ad_count = sm2.get_completed_ads_in_rolling_24h()
	if ad_count != 2:
		print("FAIL: Expected 2 valid ads in rolling 24h, got %d" % ad_count)
		failed += 1
	else:
		print("PASS: Rewarded Ad rolling 24h filtering verified (old timestamp excluded)")

	# 7. Record new ad and verify pruning
	var new_ts = int(now)
	sm2.record_ad_completion(new_ts)
	if sm2.rewarded_ad_completion_timestamps.has(old_ts):
		print("FAIL: Expired timestamp was not pruned on record_ad_completion")
		failed += 1
	elif sm2.get_completed_ads_in_rolling_24h() != 3:
		print("FAIL: Expected 3 ads after recording new one")
		failed += 1
	else:
		print("PASS: Ad timestamp recording and automatic expiration pruning verified")

	# Clean up test save file
	if FileAccess.file_exists(sm.save_file_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(sm.save_file_path))

	if failed == 0:
		print("ALL PHASE 2 PARITY CHECKS PASSED SUCCESSFULLY!")
	else:
		print("TOTAL FAILURES: %d" % failed)

	quit(failed)
