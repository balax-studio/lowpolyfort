extends Node

const HeroDefinition = preload("res://scripts/hero_definition.gd")

func _ready() -> void:
	print("\n--- BEGIN TEST PHASE 11: ARMORY / UNIT CODEX SHOWCASE ---")
	test_unlock_wave_milestones()
	test_save_unlock_progression()
	test_armory_view_ui_binding()
	print("ALL PHASE 11 PARITY CHECKS PASSED SUCCESSFULLY!\n")
	get_tree().quit(0)

func test_unlock_wave_milestones() -> void:
	var rm = HeroDefinition.get_definition(HeroDefinition.HeroClass.RIFLEMAN)
	var sg = HeroDefinition.get_definition(HeroDefinition.HeroClass.SHOTGUNNER)
	var sn = HeroDefinition.get_definition(HeroDefinition.HeroClass.SNIPER)
	var hg = HeroDefinition.get_definition(HeroDefinition.HeroClass.HEAVY_GUNNER)

	assert(rm.unlock_wave_requirement == 1, "Rifleman unlocked at Wave 1")
	assert(sg.unlock_wave_requirement == 5, "Shotgunner unlocked at Wave 5")
	assert(sn.unlock_wave_requirement == 10, "Sniper unlocked at Wave 10")
	assert(hg.unlock_wave_requirement == 15, "Heavy Gunner unlocked at Wave 15")
	print("PASS: 4 Hero unlock wave milestones verified (W1, W5, W10, W15)")

func test_save_unlock_progression() -> void:
	SaveManager.save_file_path = "user://test_phase11_save.json"
	SaveManager.reset_all_progress()

	# Wave 1
	SaveManager.highest_wave = 1
	var u1 = SaveManager.get_unlocked_hero_classes()
	assert(u1.size() == 1 and u1.has(HeroDefinition.HeroClass.RIFLEMAN), "Wave 1: only Rifleman")

	# Wave 5
	SaveManager.highest_wave = 5
	var u5 = SaveManager.get_unlocked_hero_classes()
	assert(u5.size() == 2 and u5.has(HeroDefinition.HeroClass.SHOTGUNNER), "Wave 5: unlocks Shotgunner")

	# Wave 10
	SaveManager.highest_wave = 10
	var u10 = SaveManager.get_unlocked_hero_classes()
	assert(u10.size() == 3 and u10.has(HeroDefinition.HeroClass.SNIPER), "Wave 10: unlocks Sniper")

	# Wave 15
	SaveManager.highest_wave = 15
	var u15 = SaveManager.get_unlocked_hero_classes()
	assert(u15.size() == 4 and u15.has(HeroDefinition.HeroClass.HEAVY_GUNNER), "Wave 15: unlocks Heavy Gunner")
	print("PASS: SaveManager progressive hero unlock resolution verified")

func test_armory_view_ui_binding() -> void:
	var armory_scene: PackedScene = preload("res://scenes/ui/armory_view.tscn")
	var armory = armory_scene.instantiate()
	add_child(armory)

	SaveManager.highest_wave = 7
	armory.refresh_armory()

	var cards = armory.get_node("SafeContainer/VBox/Scroll/CardsContainer")
	var rm_card = cards.get_node("RiflemanCard")
	var sg_card = cards.get_node("ShotgunnerCard")
	var sn_card = cards.get_node("SniperCard")
	var hg_card = cards.get_node("HeavyGunnerCard")

	# At Wave 7: Rifleman & Shotgunner UNLOCKED, Sniper & HG LOCKED
	var rm_badge = rm_card.get_node("Margin/HBox/InfoVBox/HeaderRow/StatusBadge/Margin/Label").text
	var sg_badge = sg_card.get_node("Margin/HBox/InfoVBox/HeaderRow/StatusBadge/Margin/Label").text
	var sn_badge = sn_card.get_node("Margin/HBox/InfoVBox/HeaderRow/StatusBadge/Margin/Label").text
	var hg_badge = hg_card.get_node("Margin/HBox/InfoVBox/HeaderRow/StatusBadge/Margin/Label").text

	assert(rm_badge == "UNLOCKED", "Rifleman must be UNLOCKED at Wave 7")
	assert(sg_badge == "UNLOCKED", "Shotgunner must be UNLOCKED at Wave 7")
	assert(sn_badge == "WAVE 10", "Sniper must display WAVE 10 requirement")
	assert(hg_badge == "WAVE 15", "Heavy Gunner must display WAVE 15 requirement")

	# Stat box visibility
	assert(rm_card.get_node("Margin/HBox/InfoVBox/StatsBox").visible == true, "Unlocked unit shows stats")
	assert(sn_card.get_node("Margin/HBox/InfoVBox/StatsBox").visible == false, "Locked unit hides stats")

	# Back button closes armory
	var closed_emitted = {"val": false}
	armory.closed.connect(func(): closed_emitted["val"] = true)
	armory._on_back_pressed()
	assert(armory.visible == false, "Armory must hide when back button pressed")
	assert(closed_emitted["val"] == true, "closed signal must be emitted")

	armory.queue_free()
	print("PASS: ArmoryView UI bindings, card badges, and close action verified")
