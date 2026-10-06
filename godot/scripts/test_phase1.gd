extends Node

func _ready() -> void:
	print("--- Running Phase 1 Self-Check ---")
	assert(GameManager != null, "GameManager autoload missing!")
	print("GameManager autoload confirmed. Coins: ", GameManager.coins, " Base HP: ", GameManager.base_hp)
	
	var main_scene = load("res://scenes/main.tscn")
	assert(main_scene != null, "Failed to load main.tscn")
	
	var main_instance = main_scene.instantiate()
	add_child(main_instance)
	
	var base = main_instance.find_child("CentralBase", true, false)
	assert(base != null, "CentralBase not found in main.tscn")
	print("CentralBase found at global position: ", base.global_position)
	assert(base.global_position == Vector3.ZERO, "CentralBase should be at (0,0,0)")
	
	var board = main_instance.find_child("Board", true, false)
	assert(board != null, "Board not found in main.tscn")
	
	var slots = board.get_slots()
	assert(slots.size() == 8, "Expected 8 tactical slots, found: %d" % slots.size())
	print("8 tactical slots verified around Base.")
	
	# Verify slot coordinates match the symmetrical ring
	var expected_positions = [
		Vector3(-2.2, 0, -2.2), Vector3(0, 0, -2.2), Vector3(2.2, 0, -2.2),
		Vector3(-2.2, 0, 0),                         Vector3(2.2, 0, 0),
		Vector3(-2.2, 0, 2.2),  Vector3(0, 0, 2.2),  Vector3(2.2, 0, 2.2)
	]
	for i in range(8):
		var slot = board.get_slot_at_index(i)
		assert(slot != null, "Slot %d is null" % i)
		assert(slot.position.is_equal_approx(expected_positions[i]), "Slot %d position mismatch: %s vs %s" % [i, slot.position, expected_positions[i]])
		print("  Slot %d at position %s: OK" % [i, slot.position])
	
	var camera = main_instance.find_child("Camera3D", true, false)
	assert(camera != null, "Camera3D not found!")
	print("Camera3D verified at %s, FOV %f, pitch %f degrees" % [camera.position, camera.fov, camera.rotation_degrees.x])
	
	var light = main_instance.find_child("DirectionalLight3D", true, false)
	assert(light != null, "DirectionalLight3D not found!")
	assert(light.shadow_enabled, "Directional shadows must be enabled")
	print("DirectionalLight3D shadows confirmed.")
	
	print(">>> PHASE 1 TEST PASSED COMPLETELY <<<")
