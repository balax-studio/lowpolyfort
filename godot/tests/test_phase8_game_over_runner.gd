extends Node

func _ready() -> void:
	print("\n--- BEGIN TEST PHASE 8: GAME OVER & FULL RUN SUMMARY ---")
	test_normal_mode_game_over_scrap()
	test_chaos_mode_game_over_scrap()
	test_boss_rush_mode_game_over_scrap()
	test_dialog_ui_binding()
	print("ALL PHASE 8 PARITY CHECKS PASSED SUCCESSFULLY!\n")
	get_tree().quit(0)

func test_normal_mode_game_over_scrap() -> void:
	SaveManager.save_file_path = "user://test_phase8_save.json"
	SaveManager.reset_all_progress()
	SaveManager.highest_wave = 3
	SaveManager.total_scrap = 50
	SaveManager.save_to_disk()

	GameManager.reset_run()
	GameManager.current_mode = GameManager.GameMode.NORMAL
	GameManager.current_wave = 5
	GameManager.bosses_defeated_this_run = 1
	GameManager.kills_this_run = 25

	# Trigger game over
	GameManager.trigger_game_over()

	# Normal formula: (5 * 3) + (1 * 10) = 15 + 10 = 25
	assert(GameManager.scrap_earned_this_run == 25, "Scrap earned in Normal mode must be 25, got %d" % GameManager.scrap_earned_this_run)
	assert(GameManager.is_new_high_score == true, "Wave 5 > Wave 3 must be a new high score")
	assert(SaveManager.highest_wave == 5, "Highest wave in save must update to 5")
	assert(SaveManager.total_scrap == 75, "Total scrap must be 50 + 25 = 75, got %d" % SaveManager.total_scrap)
	assert(SaveManager.runs_played == 1, "Runs played must increment to 1")
	print("PASS: Normal mode scrap formula & persistent save progression verified")

func test_chaos_mode_game_over_scrap() -> void:
	SaveManager.save_file_path = "user://test_phase8_save.json"
	SaveManager.reset_all_progress()
	SaveManager.best_chaos_wave = 2
	SaveManager.save_to_disk()

	GameManager.reset_run()
	GameManager.current_mode = GameManager.GameMode.CHAOS
	GameManager.current_wave = 6
	GameManager.bosses_defeated_this_run = 1

	GameManager.trigger_game_over()

	# Chaos formula: floor(((6 * 3) + (1 * 10)) * 1.10) = floor((18 + 10) * 1.10) = floor(30.8) = 30
	assert(GameManager.scrap_earned_this_run == 30, "Scrap earned in Chaos mode must be 30, got %d" % GameManager.scrap_earned_this_run)
	assert(GameManager.is_new_high_score == true, "Wave 6 > Wave 2 must be new Chaos high score")
	assert(SaveManager.best_chaos_wave == 6, "Best Chaos wave must update to 6")
	print("PASS: Chaos mode +10% scrap formula & high score verified")

func test_boss_rush_mode_game_over_scrap() -> void:
	SaveManager.save_file_path = "user://test_phase8_save.json"
	SaveManager.reset_all_progress()
	SaveManager.best_boss_rush_round = 1
	SaveManager.save_to_disk()

	# Partial completion (3 bosses)
	GameManager.reset_run()
	GameManager.current_mode = GameManager.GameMode.BOSS_RUSH
	GameManager.bosses_defeated_this_run = 3
	GameManager.trigger_game_over()
	# 3 * 8 = 24
	assert(GameManager.scrap_earned_this_run == 24, "3 bosses must yield 24 scrap, got %d" % GameManager.scrap_earned_this_run)

	# Full victory (5 bosses)
	GameManager.reset_run()
	GameManager.current_mode = GameManager.GameMode.BOSS_RUSH
	GameManager.bosses_defeated_this_run = 5
	GameManager.trigger_game_over()
	# min(50, 5 * 8 + 10) = 50
	assert(GameManager.scrap_earned_this_run == 50, "Full Boss Rush victory must yield 50 scrap, got %d" % GameManager.scrap_earned_this_run)
	assert(SaveManager.best_boss_rush_round == 5, "Best Boss Rush round must update to 5")
	print("PASS: Boss Rush scrap formulas (3 bosses -> 24, 5 bosses -> 50) verified")

func test_dialog_ui_binding() -> void:
	var dialog_scene: PackedScene = preload("res://scenes/ui/game_over_dialog.tscn")
	var dialog = dialog_scene.instantiate()
	add_child(dialog)

	GameManager.reset_run()
	GameManager.current_mode = GameManager.GameMode.NORMAL
	GameManager.current_wave = 7
	GameManager.kills_this_run = 42
	GameManager.coins = 280
	GameManager.trigger_game_over()

	assert(dialog.visible == true, "Dialog must become visible upon game over")
	assert(dialog.score_title_label.text == "WAVE 7", "Score title label must be WAVE 7")
	assert(dialog.kills_value_label.text == "42", "Kills value label must display 42")
	assert(dialog.coins_value_label.text == "280", "Coins value label must display 280")
	assert(dialog.scrap_value_label.text.begins_with("+"), "Scrap value label must show + prefix")

	dialog.queue_free()
	print("PASS: GameOverDialog UI node bindings and labels verified")
