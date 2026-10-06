extends Node

func _ready() -> void:
	print("--- BEGIN TEST PHASE 6: UNIT PURCHASE, UNLOCKS & WEIGHTED RNG ---")
	var failed: int = 0
	var rng = RandomNumberGenerator.new()
	rng.seed = 12345

	# 1. Test 1-class distribution (100% Rifleman)
	var unlocked_1: Array[HeroDefinition.HeroClass] = [HeroDefinition.HeroClass.RIFLEMAN]
	for i in range(100):
		var rolled = HeroDefinition.roll_unit_with_rng(rng, unlocked_1)
		if rolled != HeroDefinition.HeroClass.RIFLEMAN:
			print("FAIL: Expected 100% Rifleman with 1 class unlocked")
			failed += 1
			break
	print("PASS: 1-class distribution verified (100% Rifleman)")

	# 2. Test 2-class distribution (60% Rifleman, 40% Shotgunner)
	var unlocked_2: Array[HeroDefinition.HeroClass] = [HeroDefinition.HeroClass.RIFLEMAN, HeroDefinition.HeroClass.SHOTGUNNER]
	var count_rm = 0
	var count_sg = 0
	var trials = 5000
	for i in range(trials):
		var rolled = HeroDefinition.roll_unit_with_rng(rng, unlocked_2)
		if rolled == HeroDefinition.HeroClass.RIFLEMAN:
			count_rm += 1
		else:
			count_sg += 1
	var rm_ratio = float(count_rm) / float(trials)
	var sg_ratio = float(count_sg) / float(trials)
	if abs(rm_ratio - 0.60) > 0.03 or abs(sg_ratio - 0.40) > 0.03:
		print("FAIL: 2-class distribution off! RM: %f (expected 0.60), SG: %f (expected 0.40)" % [rm_ratio, sg_ratio])
		failed += 1
	else:
		print("PASS: 2-class distribution matches Flutter Clause 614 (RM: %.1f%%, SG: %.1f%%)" % [rm_ratio * 100.0, sg_ratio * 100.0])

	# 3. Test 4-class distribution (40% RM, 25% SG, 20% HG, 15% SN)
	var unlocked_4: Array[HeroDefinition.HeroClass] = [
		HeroDefinition.HeroClass.RIFLEMAN,
		HeroDefinition.HeroClass.SHOTGUNNER,
		HeroDefinition.HeroClass.SNIPER,
		HeroDefinition.HeroClass.HEAVY_GUNNER
	]
	var c_rm = 0
	var c_sg = 0
	var c_hg = 0
	var c_sn = 0
	for i in range(trials):
		var rolled = HeroDefinition.roll_unit_with_rng(rng, unlocked_4)
		match rolled:
			HeroDefinition.HeroClass.RIFLEMAN: c_rm += 1
			HeroDefinition.HeroClass.SHOTGUNNER: c_sg += 1
			HeroDefinition.HeroClass.HEAVY_GUNNER: c_hg += 1
			HeroDefinition.HeroClass.SNIPER: c_sn += 1
	
	var r_rm = float(c_rm) / float(trials)
	var r_sg = float(c_sg) / float(trials)
	var r_hg = float(c_hg) / float(trials)
	var r_sn = float(c_sn) / float(trials)
	if abs(r_rm - 0.40) > 0.03 or abs(r_sg - 0.25) > 0.03 or abs(r_hg - 0.20) > 0.03 or abs(r_sn - 0.15) > 0.03:
		print("FAIL: 4-class distribution off! RM: %f, SG: %f, HG: %f, SN: %f" % [r_rm, r_sg, r_hg, r_sn])
		failed += 1
	else:
		print("PASS: 4-class distribution matches Flutter Clause 614 (RM: %.1f%%, SG: %.1f%%, HG: %.1f%%, SN: %.1f%%)" % [r_rm * 100.0, r_sg * 100.0, r_hg * 100.0, r_sn * 100.0])

	# 4. Unit class configuration and stat verification
	var unit_scene = load("res://scenes/units/unit.tscn")
	var u_rm = unit_scene.instantiate()
	var u_sg = unit_scene.instantiate()
	var u_sn = unit_scene.instantiate()
	var u_hg = unit_scene.instantiate()
	add_child(u_rm)
	add_child(u_sg)
	add_child(u_sn)
	add_child(u_hg)

	u_rm.set_hero_class(HeroDefinition.HeroClass.RIFLEMAN)
	u_sg.set_hero_class(HeroDefinition.HeroClass.SHOTGUNNER)
	u_sn.set_hero_class(HeroDefinition.HeroClass.SNIPER)
	u_hg.set_hero_class(HeroDefinition.HeroClass.HEAVY_GUNNER)

	if u_rm.get_damage() != 12.0 or u_sg.get_damage() != 9.0 or u_sn.get_damage() != 55.0 or u_hg.get_damage() != 6.0:
		print("FAIL: Hero damage mismatch")
		failed += 1
	if u_sg.hero_def.projectile_count != 5:
		print("FAIL: Shotgunner projectile count should be 5")
		failed += 1
	if u_sn.get_range() != 14.0 or u_hg.get_attack_speed() != 3.0:
		print("FAIL: Sniper range or Heavy Gunner attack speed mismatch")
		failed += 1
	print("PASS: All 4 Hero class definitions verified with exact base stats")

	# 5. Merge validation
	var drag_ctrl = load("res://scripts/drag_controller.gd").new()
	var can_merge_same = drag_ctrl._can_merge(u_rm, u_rm)
	var can_merge_diff = drag_ctrl._can_merge(u_rm, u_sg)
	
	u_rm.level = 8
	var can_merge_max = drag_ctrl._can_merge(u_rm, u_rm)

	if not can_merge_same:
		print("FAIL: Matching level 1 units should be mergeable")
		failed += 1
	if can_merge_diff:
		print("FAIL: Different unit classes (Rifleman + Shotgunner) should NOT be mergeable")
		failed += 1
	if can_merge_max:
		print("FAIL: Max level (8) units should NOT be mergeable")
		failed += 1
	print("PASS: Merge validation rules verified (same class + same level + level < 8)")

	u_rm.queue_free()
	u_sg.queue_free()
	u_sn.queue_free()
	u_hg.queue_free()
	drag_ctrl.queue_free()

	if failed == 0:
		print("ALL PHASE 6 PARITY CHECKS PASSED SUCCESSFULLY!")
	else:
		print("TOTAL FAILURES: %d" % failed)

	get_tree().quit(failed)
