extends Node

## Automated test runner for Phase 16: Final UI/VFX Polish & Juice Parity.
## Source of truth: Flutter lib/game/ & Godot visual design (Clauses 11, 17, 25, 41, 46, 68, 85, 88).

func _ready() -> void:
	print("==================================================")
	print("--- PHASE 16: UI / VFX POLISH PARITY TESTS ---")
	print("==================================================")

	var all_passed = true

	# Test 1: Camera screen shake trauma decay (Clause 88)
	var camera_script = load("res://scripts/camera_controller.gd")
	var camera = Camera3D.new()
	camera.set_script(camera_script)
	add_child(camera)

	camera.add_trauma(0.60)
	if camera.trauma != 0.60:
		print("FAIL: Camera trauma not set to 0.60")
		all_passed = false

	# Advance 0.1s process
	camera._process(0.10)
	if camera.trauma >= 0.60:
		print("FAIL: Camera trauma did not decay over time")
		all_passed = false
	else:
		print("PASS: Camera trauma decay mechanics active and calibrated")

	camera.queue_free()

	# Test 2: Central Base beacon rotation & damage flash (Clauses 11, 41)
	var base_scene = load("res://scenes/world/central_base.tscn")
	var base_inst = base_scene.instantiate()
	add_child(base_inst)

	var initial_rot = base_inst.radar_dish.rotation.y
	base_inst._process(0.20)
	var after_rot = base_inst.radar_dish.rotation.y
	if after_rot == initial_rot:
		print("FAIL: Radar dish does not rotate in _process")
		all_passed = false
	else:
		print("PASS: Central Base ambient radar dish rotation verified")

	base_inst.trigger_damage_flash()
	if base_inst._damage_flash_timer <= 0.0:
		print("FAIL: trigger_damage_flash did not set timer")
		all_passed = false
	else:
		print("PASS: Base damage flash triggers material pulse")

	base_inst.queue_free()

	# Test 3: Unit spawn and merge squash & stretch (Clauses 17, 46)
	var unit_scene = load("res://scenes/units/unit.tscn")
	var unit_inst = unit_scene.instantiate()
	add_child(unit_inst)

	unit_inst.play_spawn_effect()
	if unit_inst.scale.x >= 1.0:
		print("FAIL: play_spawn_effect did not start with squash < 1.0")
		all_passed = false
	else:
		print("PASS: Unit spawn scale squash effect active")

	unit_inst.play_merge_effect()
	if unit_inst.scale.x >= 1.0:
		print("FAIL: play_merge_effect did not start with merge punch scale")
		all_passed = false
	else:
		print("PASS: Unit merge punch effect active")

	unit_inst.set_dragging(true)
	if not unit_inst.is_dragging or unit_inst.position.y <= 0.1:
		print("FAIL: set_dragging(true) did not elevate unit 0.4 units")
		all_passed = false
	else:
		print("PASS: Drag elevation elevates unit above tactical grid")

	unit_inst.queue_free()

	# Test 4: Floating damage numbers toggle integration
	SaveManager.show_damage_numbers = false
	var enemy_scene = load("res://scenes/enemies/enemy.tscn")
	var enemy_inst = enemy_scene.instantiate()
	add_child(enemy_inst)
	enemy_inst.setup_from_definition(EnemyDefinition.get_def(EnemyDefinition.EnemyType.BASIC), 1)

	var child_count_before = get_child_count()
	enemy_inst.take_damage(20.0, false)
	var child_count_after = get_child_count()

	if child_count_after > child_count_before:
		print("FAIL: Floating damage number created when show_damage_numbers=false")
		all_passed = false
	else:
		print("PASS: show_damage_numbers=false suppresses floating text")

	SaveManager.show_damage_numbers = true
	enemy_inst.take_damage(20.0, false)
	child_count_after = get_child_count()

	if child_count_after <= child_count_before:
		print("FAIL: Floating damage number NOT created when show_damage_numbers=true")
		all_passed = false
	else:
		print("PASS: show_damage_numbers=true spawns animated 3D billboard text")

	enemy_inst.queue_free()

	if all_passed:
		print(">>> ALL PHASE 16 PARITY TESTS PASSED! <<<")
		get_tree().quit(0)
	else:
		print(">>> SOME PHASE 16 PARITY TESTS FAILED! <<<")
		get_tree().quit(1)
