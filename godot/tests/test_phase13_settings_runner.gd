extends Node

const AppLocalization = preload("res://scripts/localization.gd")

## Automated test runner for Phase 13: Settings & Dual-Language Localization.
## Source of truth: Flutter lib/localization/app_localization.dart & lib/ui/settings/settings_dialog.dart (Clauses 138, 663–666).

func _ready() -> void:
	print("==================================================")
	print("--- PHASE 13: SETTINGS & LOCALIZATION PARITY TESTS ---")
	print("==================================================")

	var all_passed = true

	# Test 1: Localization dictionaries parity
	var test_keys = [
		{"key": "wave", "en": "WAVE", "tr": "DALGA"},
		{"key": "settings", "en": "SETTINGS", "tr": "AYARLAR"},
		{"key": "victory", "en": "VICTORY", "tr": "ZAFER"},
		{"key": "defeat", "en": "DEFEAT", "tr": "YENİLGİ"},
		{"key": "scrap", "en": "SCRAP", "tr": "HURDA"},
		{"key": "supply_drop", "en": "SUPPLY DROP", "tr": "İKMAL PAKETİ"},
		{"key": "second_chance", "en": "SECOND CHANCE", "tr": "İKİNCİ ŞANS"},
		{"key": "extra_scrap", "en": "EXTRA SCRAP", "tr": "EKSTRA HURDA"},
		{"key": "wipe_data", "en": "RESET ALL PROGRESS", "tr": "TÜM İLERLEMEYİ SIFIRLA"},
	]

	for item in test_keys:
		var en_val = AppLocalization.text(item["key"], "en")
		var tr_val = AppLocalization.text(item["key"], "tr")
		if en_val != item["en"]:
			print("FAIL: EN '%s' expected '%s', got '%s'" % [item["key"], item["en"], en_val])
			all_passed = false
		if tr_val != item["tr"]:
			print("FAIL: TR '%s' expected '%s', got '%s'" % [item["key"], item["tr"], tr_val])
			all_passed = false

	print("PASS: Core UI keys match Flutter EN/TR dictionaries exactly")

	# Test 2: Formatting helpers
	if AppLocalization.wave_text(8, "en") != "WAVE 8":
		print("FAIL: wave_text EN failed")
		all_passed = false
	if AppLocalization.wave_text(8, "tr") != "DALGA 8":
		print("FAIL: wave_text TR failed")
		all_passed = false
	if AppLocalization.round_text(3, 5, "tr") != "TUR 3/5":
		print("FAIL: round_text TR failed")
		all_passed = false

	print("PASS: Formatted waveText and roundText match Clauses 664, 666")

	# Test 3: Settings Dialog UI & Logic
	var settings_scene = load("res://scenes/ui/settings_dialog.tscn")
	var settings_dialog = settings_scene.instantiate()
	add_child(settings_dialog)
	settings_dialog.open()

	# Change values
	settings_dialog._on_master_slider_changed(75.0)
	settings_dialog._on_sfx_slider_changed(50.0)
	settings_dialog._vibration = false
	settings_dialog._show_damage = false
	settings_dialog._set_language("tr")

	# Save & Close
	settings_dialog._save_and_close()

	if abs(SaveManager.master_volume - 0.75) > 0.01:
		print("FAIL: master_volume %f != 0.75" % SaveManager.master_volume)
		all_passed = false
	if abs(SaveManager.sfx_volume - 0.50) > 0.01:
		print("FAIL: sfx_volume %f != 0.50" % SaveManager.sfx_volume)
		all_passed = false
	if SaveManager.vibration_enabled != false:
		print("FAIL: vibration_enabled != false")
		all_passed = false
	if SaveManager.show_damage_numbers != false:
		print("FAIL: show_damage_numbers != false")
		all_passed = false
	if SaveManager.language != "tr":
		print("FAIL: language != 'tr'")
		all_passed = false

	print("PASS: Settings dialog applies changes to SaveManager correctly")

	# Test 4: Save reset confirmation flow
	SaveManager.total_scrap = 888
	SaveManager.highest_wave = 15
	settings_dialog._on_confirm_wipe()

	if SaveManager.total_scrap != 0 or SaveManager.highest_wave != 1:
		print("FAIL: Wipe data did not clear progress")
		all_passed = false
	else:
		print("PASS: Wipe data resets player progress cleanly")

	# Clean up
	settings_dialog.queue_free()
	SaveManager.reset_all_progress()

	if all_passed:
		print(">>> ALL PHASE 13 PARITY TESTS PASSED! <<<")
		get_tree().quit(0)
	else:
		print(">>> SOME PHASE 13 PARITY TESTS FAILED! <<<")
		get_tree().quit(1)
