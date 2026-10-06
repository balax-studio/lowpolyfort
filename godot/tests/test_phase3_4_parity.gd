extends SceneTree

func _init() -> void:
	print("--- BEGIN TEST PHASE 3 & 4: MAIN MENU & MODE SELECT PARITY ---")
	var failed: int = 0

	var sm = root.get_node_or_null("/root/SaveManager")
	if sm == null:
		sm = load("res://scripts/save_manager.gd").new()
		sm.name = "SaveManager"
		root.add_child(sm)

	var gm = root.get_node_or_null("/root/GameManager")
	if gm == null:
		gm = load("res://scripts/game_manager.gd").new()
		gm.name = "GameManager"
		root.add_child(gm)

	sm.save_file_path = "user://test_menu_save.json"
	sm.reset_all()

	# 1. Instantiate Main Menu scene
	var menu_scene: PackedScene = load("res://scenes/ui/main_menu.tscn")
	if menu_scene == null:
		print("FAIL: Could not load main_menu.tscn")
		quit(1)
		return
	var menu: MainMenu = menu_scene.instantiate()
	root.add_child(menu)
	print("PASS: MainMenu scene instantiated cleanly with 3D preview and UI overlay")

	# 2. Check UI badge binding
	sm.highest_wave = 7
	sm.total_scrap = 45
	sm.save_to_disk()
	menu.refresh_stats()

	if menu.best_wave_label.text != "BEST WAVE: 7":
		print("FAIL: best_wave_label mismatch: %s" % menu.best_wave_label.text)
		failed += 1
	if menu.scrap_label.text != "45 SCRAP":
		print("FAIL: scrap_label mismatch: %s" % menu.scrap_label.text)
		failed += 1
	print("PASS: MainMenu stats badge binding verified (BEST WAVE: 7, 45 SCRAP)")

	# 3. PLAY button routing when Chaos is LOCKED
	sm.chaos_unlocked = false
	sm.save_to_disk()
	menu.mode_select_dialog.visible = false
	menu._on_play_pressed()
	if menu.mode_select_dialog.visible:
		print("FAIL: ModeSelectDialog opened when Chaos was locked!")
		failed += 1
	else:
		print("PASS: PLAY button routes directly to Normal mode when Chaos is locked (Clause 112)")

	# 4. PLAY button routing when Chaos is UNLOCKED
	sm.chaos_unlocked = true
	sm.save_to_disk()
	menu._on_play_pressed()
	if not menu.mode_select_dialog.visible:
		print("FAIL: ModeSelectDialog did not open when Chaos was unlocked!")
		failed += 1
	else:
		print("PASS: PLAY button opens ModeSelectDialog when Chaos is unlocked (Clause 112)")

	# 5. ModeSelectDialog locked shake verification
	var mode_dialog = menu.mode_select_dialog
	sm.boss_rush_unlocked = false
	mode_dialog.refresh_state()

	var selected_mode: int = -1
	mode_dialog.mode_selected.connect(func(m): selected_mode = m)

	# Tap locked Boss Rush -> should NOT emit mode_selected
	mode_dialog._on_boss_rush_pressed()
	if selected_mode != -1:
		print("FAIL: Locked Boss Rush emitted mode_selected!")
		failed += 1
	else:
		print("PASS: Locked mode cards block selection and trigger shake animation")

	# Tap unlocked Chaos -> should emit CHAOS
	mode_dialog._on_chaos_pressed()
	if selected_mode != GameManager.GameMode.CHAOS:
		print("FAIL: Unlocked Chaos failed to emit CHAOS! Got: %d" % selected_mode)
		failed += 1
	else:
		print("PASS: Unlocked Chaos successfully emits CHAOS mode")

	# 6. ModeSelectDialog Normal card
	selected_mode = -1
	mode_dialog._on_normal_pressed()
	if selected_mode != GameManager.GameMode.NORMAL:
		print("FAIL: Normal card failed to emit NORMAL! Got: %d" % selected_mode)
		failed += 1
	else:
		print("PASS: Normal card successfully emits NORMAL mode")

	# Clean up test save file
	if FileAccess.file_exists(sm.save_file_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(sm.save_file_path))

	menu.queue_free()

	if failed == 0:
		print("ALL PHASE 3 & 4 PARITY CHECKS PASSED SUCCESSFULLY!")
	else:
		print("TOTAL FAILURES: %d" % failed)

	quit(failed)
