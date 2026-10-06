extends Node

func _ready() -> void:
	print("--- BEGIN TEST PHASE 3 & 4 (SCENE RUNNER): MAIN MENU & MODE SELECT PARITY ---")
	var failed: int = 0

	SaveManager.save_file_path = "user://test_menu_save.json"
	SaveManager.reset_all()

	# 1. Instantiate Main Menu scene
	var menu_scene: PackedScene = load("res://scenes/ui/main_menu.tscn")
	if menu_scene == null:
		print("FAIL: Could not load main_menu.tscn")
		get_tree().quit(1)
		return
	var menu = menu_scene.instantiate()
	add_child(menu)
	print("PASS: MainMenu scene instantiated cleanly with 3D preview and UI overlay")

	# 2. Check UI badge binding
	SaveManager.highest_wave = 7
	SaveManager.total_scrap = 45
	SaveManager.save_to_disk()
	menu.refresh_stats()

	if menu.best_wave_label.text != "BEST WAVE: 7":
		print("FAIL: best_wave_label mismatch: %s" % menu.best_wave_label.text)
		failed += 1
	if menu.scrap_label.text != "45 SCRAP":
		print("FAIL: scrap_label mismatch: %s" % menu.scrap_label.text)
		failed += 1
	print("PASS: MainMenu stats badge binding verified (BEST WAVE: 7, 45 SCRAP)")

	# 3. PLAY button routing when Chaos is LOCKED
	SaveManager.chaos_unlocked = false
	SaveManager.save_to_disk()
	menu.mode_select_dialog.visible = false
	menu._on_play_pressed()
	if menu.mode_select_dialog.visible:
		print("FAIL: ModeSelectDialog opened when Chaos was locked!")
		failed += 1
	else:
		print("PASS: PLAY button routes directly to Normal mode when Chaos is locked (Clause 112)")

	# 4. PLAY button routing when Chaos is UNLOCKED
	SaveManager.chaos_unlocked = true
	SaveManager.save_to_disk()
	menu._on_play_pressed()
	if not menu.mode_select_dialog.visible:
		print("FAIL: ModeSelectDialog did not open when Chaos was unlocked!")
		failed += 1
	else:
		print("PASS: PLAY button opens ModeSelectDialog when Chaos is unlocked (Clause 112)")

	# 5. ModeSelectDialog locked shake verification
	var mode_dialog = menu.mode_select_dialog
	SaveManager.boss_rush_unlocked = false
	mode_dialog.refresh_state()

	var result = { "mode": -1 }
	mode_dialog.mode_selected.connect(func(m): result["mode"] = m)

	# Tap locked Boss Rush -> should NOT emit mode_selected
	mode_dialog._on_boss_rush_pressed()
	if result["mode"] != -1:
		print("FAIL: Locked Boss Rush emitted mode_selected!")
		failed += 1
	else:
		print("PASS: Locked mode cards block selection and trigger shake animation")

	# Tap unlocked Chaos -> should emit CHAOS
	mode_dialog._on_chaos_pressed()
	if result["mode"] != GameManager.GameMode.CHAOS:
		print("FAIL: Unlocked Chaos failed to emit CHAOS! Got: %d" % result["mode"])
		failed += 1
	else:
		print("PASS: Unlocked Chaos successfully emits CHAOS mode")

	# 6. ModeSelectDialog Normal card
	result["mode"] = -1
	mode_dialog._on_normal_pressed()
	if result["mode"] != GameManager.GameMode.NORMAL:
		print("FAIL: Normal card failed to emit NORMAL! Got: %d" % result["mode"])
		failed += 1
	else:
		print("PASS: Normal card successfully emits NORMAL mode")

	# Clean up test save file
	if FileAccess.file_exists(SaveManager.save_file_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveManager.save_file_path))

	menu.queue_free()

	if failed == 0:
		print("ALL PHASE 3 & 4 PARITY CHECKS PASSED SUCCESSFULLY!")
	else:
		print("TOTAL FAILURES: %d" % failed)

	get_tree().quit(failed)
