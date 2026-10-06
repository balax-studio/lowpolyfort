extends Node

func _ready() -> void:
	print("--- Running Phase 4 Drag & Merge Self-Check ---")
	var main_scene = load("res://scenes/main.tscn")
	assert(main_scene != null, "Failed to load main.tscn")
	
	var main_instance = main_scene.instantiate()
	add_child(main_instance)
	
	var board = main_instance.find_child("Board", true, false)
	assert(board != null, "Board not found")
	
	var drag_ctrl = main_instance.find_child("DragController", true, false)
	assert(drag_ctrl != null, "DragController not found")
	
	var slot0 = board.get_slot_at_index(0)
	var slot1 = board.get_slot_at_index(1)
	var slot2 = board.get_slot_at_index(2)
	
	var u1 = board.spawn_unit_on_slot(slot0, 1)
	var u2 = board.spawn_unit_on_slot(slot1, 1)
	assert(u1 != null and u2 != null, "Units failed to spawn")
	assert(slot0.is_occupied() and slot1.is_occupied(), "Slots 0 and 1 should be occupied")
	print("Spawned Unit 1 (Lv.1) on Slot 0 and Unit 2 (Lv.1) on Slot 1.")
	
	# Test 1: Move Unit 1 from Slot 0 to empty Slot 2
	drag_ctrl._move_to_slot(u1, slot0, slot2)
	assert(not slot0.is_occupied(), "Slot 0 should now be empty after move")
	assert(slot2.is_occupied(), "Slot 2 should now be occupied")
	assert(slot2.get_unit() == u1, "Slot 2 unit should be u1")
	assert(u1.current_slot == slot2, "u1.current_slot should be slot2")
	print("Test 1 OK: Successfully moved unit to empty slot.")
	
	# Test 2: Merge validation between two Lv.1 units
	assert(drag_ctrl._can_merge(u1, u2), "Two Lv.1 Riflemen should be mergeable")
	print("Test 2 OK: Merge eligibility confirmed.")
	
	# Test 3: Execute Merge into Slot 1
	drag_ctrl._execute_merge(u1, slot2, u2, slot1)
	assert(not slot2.is_occupied(), "Slot 2 should be empty after merge")
	assert(slot1.is_occupied(), "Slot 1 should remain occupied")
	assert(u2.level == 2, "Unit 2 should now be Lv.2, got Lv.%d" % u2.level)
	assert(u2.get_damage() == 18.0, "Lv.2 damage should be 18.0 (12 * 1.5), got %f" % u2.get_damage())
	assert(u2.level_label.text == "Lv.2", "Level label should display 'Lv.2'")
	print("Test 3 OK: Merge executed successfully -> Level 2 reached, damage scaled to 18.0.")
	
	# Test 4: Can't merge different levels
	var u3 = board.spawn_unit_on_slot(slot0, 1)
	assert(u3 != null, "Failed to spawn u3")
	assert(not drag_ctrl._can_merge(u3, u2), "Lv.1 and Lv.2 should NOT be mergeable")
	print("Test 4 OK: Mismatched levels correctly rejected.")
	
	print(">>> PHASE 4 DRAG & MERGE PASSED COMPLETELY <<<")
	get_tree().quit(0)
