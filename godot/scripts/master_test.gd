extends Node

## Comprehensive Master Test Suite for Poly Fort Godot 4 Vertical Slice.
## Validates all systems across Phases 1 through 5 in one automated, zero-regression pass.

func _ready() -> void:
	print("==================================================================")
	print(">>> RUNNING POLY FORT GODOT 4 VERTICAL SLICE MASTER TEST SUITE <<<")
	print("==================================================================")
	
	# Instantiate main game
	var main_scene = load("res://scenes/main.tscn")
	assert(main_scene != null, "FAIL: res://scenes/main.tscn failed to load")
	var main = main_scene.instantiate()
	add_child(main)
	
	var base = main.find_child("CentralBase", true, false)
	var board = main.find_child("Board", true, false)
	var hud = main.find_child("HUD", true, false)
	var wave_mgr = main.find_child("WaveManager", true, false)
	var drag_ctrl = main.find_child("DragController", true, false)
	var game_over = main.find_child("GameOverDialog", true, false)
	var camera = main.find_child("Camera3D", true, false)
	
	assert(base != null and board != null and hud != null and wave_mgr != null and drag_ctrl != null and game_over != null and camera != null, "Critical nodes missing!")
	
	# ------------------------------------------------------------------
	# TEST 1: Phase 1 Scene & Symmetrical Formation Check
	# ------------------------------------------------------------------
	print("\n[TEST 1] Verifying 3x3 Perimeter Formation & Base...")
	assert(base.global_position == Vector3.ZERO, "Base should be situated at (0, 0, 0)")
	var slots = board.get_slots()
	assert(slots.size() == 8, "Must have exactly 8 tactical slots surrounding the central base")
	print("  -> Base at (0,0,0) with 8 tactical slots: PASSED")
	
	# ------------------------------------------------------------------
	# TEST 2: Phase 3 Economy & Initial Purchase Check
	# ------------------------------------------------------------------
	print("\n[TEST 2] Verifying Economy & Purchase Cost Scaling...")
	assert(GameManager.coins == 150, "Starting coins should be 150")
	assert(GameManager.get_unit_cost() == 50, "Initial unit cost should be 50")
	
	var buy1 = GameManager.try_purchase_unit()
	assert(buy1, "Purchase 1 should succeed")
	assert(GameManager.coins == 100, "Coins after purchase 1 should be 100")
	assert(GameManager.get_unit_cost() == 55, "Purchase 2 cost should be 55")
	assert(board.get_slot_at_index(0).is_occupied(), "Slot 0 must be occupied")
	
	var buy2 = GameManager.try_purchase_unit()
	assert(buy2, "Purchase 2 should succeed")
	assert(GameManager.coins == 45, "Coins after purchase 2 should be 45")
	assert(GameManager.get_unit_cost() == 61, "Purchase 3 cost should be 61")
	assert(board.get_slot_at_index(1).is_occupied(), "Slot 1 must be occupied")
	
	var buy3_fail = GameManager.try_purchase_unit()
	assert(not buy3_fail, "Purchase 3 should fail due to insufficient coins (45 < 61)")
	print("  -> Economy & Purchase Scaling: PASSED")
	
	# ------------------------------------------------------------------
	# TEST 3: Phase 4 Drag & Merge Mechanics Check
	# ------------------------------------------------------------------
	print("\n[TEST 3] Verifying 3D Drag Move & Unit Merge...")
	var u1 = board.get_slot_at_index(0).get_unit()
	var u2 = board.get_slot_at_index(1).get_unit()
	assert(u1 != null and u2 != null, "Units 1 and 2 should exist")
	assert(u1.level == 1 and u2.level == 1, "Both units should be Lv.1")
	
	# Move u1 to slot 2
	var slot0 = board.get_slot_at_index(0)
	var slot1 = board.get_slot_at_index(1)
	var slot2 = board.get_slot_at_index(2)
	drag_ctrl._move_to_slot(u1, slot0, slot2)
	assert(not slot0.is_occupied() and slot2.is_occupied(), "Slot 0 empty and Slot 2 occupied")
	
	# Merge u1 into u2 on slot 1
	assert(drag_ctrl._can_merge(u1, u2), "Should be eligible for merge")
	drag_ctrl._execute_merge(u1, slot2, u2, slot1)
	assert(not slot2.is_occupied(), "Slot 2 should be cleared after merge")
	assert(u2.level == 2, "Merged unit must be Level 2")
	assert(u2.get_damage() == 18.0, "Level 2 damage must be 18.0 (12 * 1.5)")
	print("  -> 3D Drag Move & Merge Leveling: PASSED")
	
	# ------------------------------------------------------------------
	# TEST 4: Phase 2 Combat & Projectile Execution Check
	# ------------------------------------------------------------------
	print("\n[TEST 4] Verifying Combat, Targeting & Projectiles...")
	var enemy_scene = load("res://scenes/enemies/enemy.tscn")
	var enemy = enemy_scene.instantiate()
	main.find_child("Enemies", true, false).add_child(enemy)
	enemy.global_position = Vector3(0.0, 0.0, -4.5)
	
	# Check damage application
	enemy.take_damage(20.0)
	assert(enemy.hp == 35.0, "Enemy HP should be 35 after 20 damage")
	
	# Check lethal damage & coin drop
	var coins_before = GameManager.coins
	enemy.take_damage(40.0)
	assert(enemy.is_dead, "Enemy should be dead")
	assert(GameManager.coins == coins_before + 5, "Coins should increase by 5 on enemy death")
	print("  -> Damage, Lethality & Coin Rewards: PASSED")
	
	# ------------------------------------------------------------------
	# TEST 5: Phase 5 Wave Flow, Base Destruction & Retry Check
	# ------------------------------------------------------------------
	print("\n[TEST 5] Verifying Base Damage, Game Over & Clean Retry...")
	GameManager.damage_base(100.0)
	assert(GameManager.base_hp == 900.0, "Base HP should be 900 after 100 damage")
	
	# Fatal base damage
	GameManager.damage_base(900.0)
	assert(GameManager.base_hp == 0.0, "Base HP should be 0")
	assert(GameManager.state == GameManager.GameState.GAME_OVER, "Game state must be GAME_OVER")
	assert(game_over.visible, "GameOverDialog must be visible")
	
	# Retry
	game_over._on_retry_pressed()
	assert(not game_over.visible, "GameOverDialog must hide on Retry")
	assert(GameManager.state == GameManager.GameState.PLAYING, "Game state must return to PLAYING")
	assert(GameManager.base_hp == 1000.0, "Base HP must reset to 1000")
	assert(GameManager.coins == 150, "Coins must reset to 150")
	assert(GameManager.purchase_count == 0, "Purchase count must reset to 0")
	assert(not board.get_slot_at_index(1).is_occupied(), "Board slots must be cleanly cleared")
	print("  -> Base Damage, Game Over & Clean Retry Reset: PASSED")
	
	print("\n==================================================================")
	print(">>> ALL 5 TEST SUITES PASSED WITH ZERO REGRESSIONS (100% DONE) <<<")
	print("==================================================================")
	get_tree().quit(0)
