extends Node

func _ready() -> void:
	print("--- Running Phase 5 Wave Lifecycle & Game Over Self-Check ---")
	var main_scene = load("res://scenes/main.tscn")
	assert(main_scene != null, "Failed to load main.tscn")
	
	var main_instance = main_scene.instantiate()
	add_child(main_instance)
	
	var wave_mgr = main_instance.find_child("WaveManager", true, false)
	assert(wave_mgr != null, "WaveManager not found")
	
	var game_over_dialog = main_instance.find_child("GameOverDialog", true, false)
	assert(game_over_dialog != null, "GameOverDialog not found")
	assert(not game_over_dialog.visible, "GameOverDialog should start hidden")
	
	var hud = main_instance.find_child("HUD", true, false)
	assert(hud != null, "HUD not found")
	
	var board = main_instance.find_child("Board", true, false)
	assert(board != null, "Board not found")
	
	# Start wave 1 explicitly to test configuration
	wave_mgr.start_wave(1)
	assert(wave_mgr.enemies_to_spawn == 7, "Wave 1 should have exactly 7 enemies, got %d" % wave_mgr.enemies_to_spawn)
	print("Wave 1 configuration verified: 7 enemies to spawn.")
	
	# Populate board with a unit and spend coins
	GameManager.try_purchase_unit()
	assert(GameManager.coins == 100, "Coins should be 100")
	assert(board.get_slot_at_index(0).is_occupied(), "Slot 0 should be occupied")
	
	# Trigger Base Destruction -> Game Over
	print("Damaging base to 0 to test Game Over...")
	GameManager.damage_base(1000.0)
	assert(GameManager.state == GameManager.GameState.GAME_OVER, "Game state should be GAME_OVER")
	assert(GameManager.base_hp == 0.0, "Base HP should be 0")
	assert(game_over_dialog.visible, "GameOverDialog must become visible")
	print("Game Over triggered successfully: Dialog visible, Base HP at 0.")
	
	# Test Retry reset
	print("Pressing Retry...")
	game_over_dialog._on_retry_pressed()
	
	assert(not game_over_dialog.visible, "GameOverDialog should hide after Retry")
	assert(GameManager.state == GameManager.GameState.PLAYING, "Game state should be PLAYING after Retry")
	assert(GameManager.base_hp == 1000.0, "Base HP should reset to 1000")
	assert(GameManager.coins == 150, "Coins should reset to 150")
	assert(GameManager.purchase_count == 0, "Purchase count should reset to 0")
	assert(not board.get_slot_at_index(0).is_occupied(), "Board slots should be reset and empty")
	
	print(">>> PHASE 5 WAVE LIFECYCLE & RETRY PASSED COMPLETELY <<<")
	get_tree().quit(0)
