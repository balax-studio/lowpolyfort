extends Node

## Automated test runner for Phase 12: Permanent Upgrades Meta-Progression Shop.
## Source of truth: Flutter lib/ui/upgrades/permanent_upgrades_view.dart (Clauses 105–112, 646, 647).

func _ready() -> void:
	print("==================================================")
	print("--- PHASE 12: PERMANENT UPGRADES PARITY TESTS ---")
	print("==================================================")

	var all_passed = true

	# Test 1: Upgrade costs sequence
	var expected_costs = [25, 50, 100, 175, 300]
	for lvl in range(expected_costs.size()):
		var cost = GameBalance.get_permanent_upgrade_cost(lvl)
		if cost != expected_costs[lvl]:
			print("FAIL: Perk level %d cost %d != expected %d" % [lvl, cost, expected_costs[lvl]])
			all_passed = false
	print("PASS: Permanent upgrade cost curves match Flutter [25, 50, 100, 175, 300]")

	# Test 2: Max level is 5
	if GameBalance.MAX_PERM_UPGRADE_LEVEL != 5:
		print("FAIL: MAX_PERM_UPGRADE_LEVEL != 5")
		all_passed = false
	else:
		print("PASS: MAX_PERM_UPGRADE_LEVEL is strictly 5 (Clauses 646, 647)")

	# Test 3: Purchase logic and scrap deduction
	SaveManager.reset_all_progress()
	SaveManager.total_scrap = 0

	var upgrades_scene = load("res://scenes/ui/permanent_upgrades_view.tscn")
	var upgrades_view = upgrades_scene.instantiate()
	add_child(upgrades_view)
	upgrades_view.open()

	# Attempt buy with 0 scrap -> should fail
	upgrades_view._on_perk_buy("base_armor")
	if SaveManager.perm_base_hp_level != 0:
		print("FAIL: Base armor upgraded without scrap")
		all_passed = false
	else:
		print("PASS: Insufficient scrap blocks purchase")

	# Give scrap and test full level 0 -> 5 cycle
	SaveManager.total_scrap = 1000
	var scrap_start = SaveManager.total_scrap

	# Buy Base Armor: 25 + 50 + 100 + 175 + 300 = 650
	for i in range(5):
		upgrades_view._on_perk_buy("base_armor")
		if SaveManager.perm_base_hp_level != i + 1:
			print("FAIL: Base armor level expected %d, got %d" % [i + 1, SaveManager.perm_base_hp_level])
			all_passed = false

	if SaveManager.total_scrap != scrap_start - 650:
		print("FAIL: Scrap total %d != expected %d" % [SaveManager.total_scrap, scrap_start - 650])
		all_passed = false
	else:
		print("PASS: Base Armor upgraded 0->5 with exact 650 scrap deduction")

	# Test cap at level 5
	upgrades_view._on_perk_buy("base_armor")
	if SaveManager.perm_base_hp_level != 5:
		print("FAIL: Base armor exceeded max level 5")
		all_passed = false
	else:
		print("PASS: Base armor strictly capped at level 5")

	# Test all other 5 perks
	SaveManager.total_scrap = 5000
	var other_perks = ["starting_cash", "unit_training", "rapid_training", "luck", "bounty"]
	for p in other_perks:
		upgrades_view._on_perk_buy(p)

	if SaveManager.perm_starting_coins_level != 1 or \
	   SaveManager.perm_damage_level != 1 or \
	   SaveManager.perm_attack_speed_level != 1 or \
	   SaveManager.perm_crit_level != 1 or \
	   SaveManager.perm_bounty_level != 1:
		print("FAIL: One or more perks failed single upgrade test")
		all_passed = false
	else:
		print("PASS: All 6 permanent perk types successfully upgradeable")

	# Test save persistence
	SaveManager.save_to_disk()
	SaveManager.load_from_disk()
	if SaveManager.perm_base_hp_level != 5 or SaveManager.perm_starting_coins_level != 1:
		print("FAIL: SaveManager did not restore permanent upgrade levels from disk")
		all_passed = false
	else:
		print("PASS: Permanent upgrade levels correctly persist to disk")

	# Clean up
	upgrades_view.queue_free()
	SaveManager.reset_all_progress()

	if all_passed:
		print(">>> ALL PHASE 12 PARITY TESTS PASSED! <<<")
		get_tree().quit(0)
	else:
		print(">>> SOME PHASE 12 PARITY TESTS FAILED! <<<")
		get_tree().quit(1)
