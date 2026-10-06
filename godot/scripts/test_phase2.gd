extends Node

var main_instance: Node = null
var unit_instance: Node = null
var enemy_instance: Node = null
var test_step: int = 0
var timer: float = 0.0

func _ready() -> void:
	print("--- Running Phase 2 Combat Loop Self-Check ---")
	var main_scene = load("res://scenes/main.tscn")
	assert(main_scene != null, "Failed to load main.tscn")
	
	main_instance = main_scene.instantiate()
	add_child(main_instance)
	
	var board = main_instance.find_child("Board", true, false)
	assert(board != null, "Board not found")
	
	# 1. Spawn unit on Slot 1
	var slot1 = board.get_slot_at_index(1)
	assert(slot1 != null, "Slot 1 missing")
	unit_instance = board.spawn_unit_on_slot(slot1, 1)
	assert(unit_instance != null, "Unit failed to spawn")
	assert(slot1.is_occupied(), "Slot 1 should be occupied")
	print("Spawned Unit Lv.1 on Slot 1 at ", unit_instance.global_position)
	
	# 2. Spawn Enemy at (0, 0, -5.5)
	var enemy_scene = load("res://scenes/enemies/enemy.tscn")
	assert(enemy_scene != null, "Enemy scene missing")
	
	enemy_instance = enemy_scene.instantiate()
	var enemies_container = main_instance.find_child("Enemies", true, false)
	enemies_container.add_child(enemy_instance)
	enemy_instance.global_position = Vector3(0.0, 0.0, -5.5)
	print("Spawned Basic Enemy at ", enemy_instance.global_position)
	
	test_step = 1

func _process(delta: float) -> void:
	timer += delta
	
	if test_step == 1:
		# Check that unit has scanned and locked onto enemy
		if timer >= 0.25:
			assert(unit_instance.current_target == enemy_instance, "Unit should have acquired enemy target!")
			print("Target scan OK: Unit targeted enemy.")
			test_step = 2
			timer = 0.0
			
	elif test_step == 2:
		# Wait for unit to shoot and kill enemy
		if GameManager.coins > 150:
			print("Combat Kill OK: Enemy died, coins awarded: ", GameManager.coins)
			assert(GameManager.coins == 155, "Expected 155 coins, got %d" % GameManager.coins)
			
			# Test Step 3: Spawn enemy directly near base to test Base Attack
			var enemy_scene = load("res://scenes/enemies/enemy.tscn")
			var near_enemy = enemy_scene.instantiate()
			var enemies_container = main_instance.find_child("Enemies", true, false)
			enemies_container.add_child(near_enemy)
			near_enemy.global_position = Vector3(0.0, 0.0, -1.35)
			print("Spawned enemy directly at base perimeter to test Base Attack.")
			test_step = 3
			timer = 0.0
			
	elif test_step == 3:
		if GameManager.base_hp < 1000.0:
			print("Base Attack OK: Base took damage, HP is now: ", GameManager.base_hp)
			assert(GameManager.base_hp <= 985.0, "Base HP should be <= 985")
			print(">>> PHASE 2 COMBAT LOOP PASSED COMPLETELY <<<")
			test_step = 999
			get_tree().quit(0)
			
	if timer > 10.0 and test_step != 999:
		push_error("Test timed out at step %d" % test_step)
		get_tree().quit(1)
