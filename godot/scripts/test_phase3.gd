extends Node

func _ready() -> void:
	print("--- Running Phase 3 Economy & Unit Purchase Self-Check ---")
	var main_scene = load("res://scenes/main.tscn")
	assert(main_scene != null, "Failed to load main.tscn")
	
	var main_instance = main_scene.instantiate()
	add_child(main_instance)
	
	# Verify initial state
	assert(GameManager.coins == 150, "Initial coins should be 150")
	assert(GameManager.get_unit_cost() == 50, "Initial cost should be 50")
	print("Initial economy verified: 150 coins, 50 cost.")
	
	var board = main_instance.find_child("Board", true, false)
	assert(board != null, "Board not found")
	
	var hud = main_instance.find_child("HUD", true, false)
	assert(hud != null, "HUD not found")
	
	# 1. Purchase 1st unit
	var success_1 = GameManager.try_purchase_unit()
	assert(success_1, "First purchase should succeed")
	assert(GameManager.coins == 100, "Coins should be 100 after 1st purchase, got %d" % GameManager.coins)
	assert(GameManager.purchase_count == 1, "Purchase count should be 1")
	assert(GameManager.get_unit_cost() == 55, "Cost 2 should be ceil(50*1.1)=55, got %d" % GameManager.get_unit_cost())
	assert(board.get_slot_at_index(0).is_occupied(), "Slot 0 should be occupied")
	print("Purchase 1 OK: Slot 0 occupied, 100 coins remaining, next cost 55.")
	
	# 2. Purchase 2nd unit
	var success_2 = GameManager.try_purchase_unit()
	assert(success_2, "Second purchase should succeed")
	assert(GameManager.coins == 45, "Coins should be 45 after 2nd purchase, got %d" % GameManager.coins)
	assert(GameManager.purchase_count == 2, "Purchase count should be 2")
	assert(GameManager.get_unit_cost() == 61, "Cost 3 should be ceil(50*1.1^2)=61, got %d" % GameManager.get_unit_cost())
	assert(board.get_slot_at_index(1).is_occupied(), "Slot 1 should be occupied")
	print("Purchase 2 OK: Slot 1 occupied, 45 coins remaining, next cost 61.")
	
	# 3. Third purchase attempt should fail due to insufficient funds (45 < 61)
	var success_3 = GameManager.try_purchase_unit()
	assert(not success_3, "Third purchase should fail (insufficient coins)")
	assert(GameManager.coins == 45, "Coins should remain 45")
	assert(not board.get_slot_at_index(2).is_occupied(), "Slot 2 should remain empty")
	print("Purchase 3 failure check OK: Insufficient funds correctly handled.")
	
	# Verify HUD reflects disabled button and coin text
	var coins_label = hud.find_child("CoinsLabel", true, false)
	assert(coins_label != null and coins_label.text == "45 🪙", "CoinsLabel should display '45 🪙'")
	
	var add_btn = hud.find_child("AddUnitButton", true, false)
	assert(add_btn != null and add_btn.disabled, "AddUnitButton should be disabled")
	
	print(">>> PHASE 3 ECONOMY & PURCHASE PASSED COMPLETELY <<<")
	get_tree().quit(0)
