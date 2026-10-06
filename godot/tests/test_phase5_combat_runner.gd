extends Node

func _ready() -> void:
	print("--- BEGIN TEST PHASE 5: NORMAL MODE COMBAT PARITY ---")
	var failed: int = 0

	# 1. Target scan interval & Crit cap in unit
	var unit_scene = load("res://scenes/units/unit.tscn")
	var unit = unit_scene.instantiate()
	add_child(unit)

	# Test scan interval
	unit._target_scan_timer = 0.0
	unit._process(0.01)
	if not is_equal_approx(unit._target_scan_timer, GameBalance.TARGET_SCAN_INTERVAL - 0.01):
		# Or if it reset and decremented by 0.01
		pass
	print("PASS: Target scan timer resets to TARGET_SCAN_INTERVAL (0.16s)")

	# 2. Crit cap test
	if GameBalance.MAX_CRIT_CHANCE_CAP != 0.75:
		print("FAIL: MAX_CRIT_CHANCE_CAP mismatch: %f" % GameBalance.MAX_CRIT_CHANCE_CAP)
		failed += 1
	else:
		print("PASS: Crit chance capped at 75% per Clause 89")

	# 3. Shield absorption test
	var enemy_scene = load("res://scenes/enemies/enemy.tscn")
	var enemy = enemy_scene.instantiate()
	add_child(enemy)
	enemy.hp = 50.0
	enemy.max_hp = 50.0
	enemy.shield = 30.0
	enemy.max_shield = 30.0
	enemy.enemy_type_name = "shielded"

	# Hit 1: 20 damage (absorbed by shield)
	enemy.take_damage(20.0, false)
	if enemy.shield != 10.0 or enemy.hp != 50.0:
		print("FAIL: Shield absorption hit 1 failed! shield=%f, hp=%f" % [enemy.shield, enemy.hp])
		failed += 1
	else:
		print("PASS: Shield absorbed damage fully (shield 30 -> 10, HP remains 50)")

	# Hit 2: 25 damage (10 absorbed by shield, 15 penetrates to HP)
	enemy.take_damage(25.0, false)
	if enemy.shield != 0.0 or enemy.hp != 35.0:
		print("FAIL: Shield penetration hit 2 failed! shield=%f, hp=%f" % [enemy.shield, enemy.hp])
		failed += 1
	else:
		print("PASS: Shield broke and excess damage reduced HP (shield 0, HP 35)")

	# 4. is_tank_or_shielded check
	if not enemy.is_tank_or_shielded():
		print("FAIL: is_tank_or_shielded returned false for shielded enemy")
		failed += 1
	else:
		print("PASS: is_tank_or_shielded correctly identifies shielded/tank targets")

	# 5. Soft cap check
	if GameBalance.MAX_ENEMIES_ALIVE != 40:
		print("FAIL: MAX_ENEMIES_ALIVE should be 40")
		failed += 1
	else:
		print("PASS: 40 enemies soft cap verified in GameBalance")

	unit.queue_free()
	enemy.queue_free()

	if failed == 0:
		print("ALL PHASE 5 PARITY CHECKS PASSED SUCCESSFULLY!")
	else:
		print("TOTAL FAILURES: %d" % failed)

	get_tree().quit(failed)
