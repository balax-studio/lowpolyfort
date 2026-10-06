class_name GameOverDialog
extends Control

## Neo-Brutalist Game Over Dialog parameterized for all 3 modes.
## Source of truth: Flutter lib/ui/game_over/game_over_dialog.dart (Clauses 204–207, 319, 345, 346, 394).

@onready var banner_badge: PanelContainer = $PanelContainer/VBoxContainer/BannerBadge
@onready var banner_label: Label = $PanelContainer/VBoxContainer/BannerBadge/Label
@onready var score_title_label: Label = $PanelContainer/VBoxContainer/ScoreTitleLabel
@onready var best_record_badge: PanelContainer = $PanelContainer/VBoxContainer/BestRecordBadge
@onready var best_score_label: Label = $PanelContainer/VBoxContainer/BestScoreLabel

@onready var milestone_card: PanelContainer = $PanelContainer/VBoxContainer/MilestoneCard
@onready var milestone_title: Label = $PanelContainer/VBoxContainer/MilestoneCard/VBox/Title
@onready var milestone_subtitle: Label = $PanelContainer/VBoxContainer/MilestoneCard/VBox/Subtitle

@onready var kills_value_label: Label = $PanelContainer/VBoxContainer/StatsRow/KillsCol/ValueLabel
@onready var coins_value_label: Label = $PanelContainer/VBoxContainer/StatsRow/CoinsCol/ValueLabel
@onready var scrap_value_label: Label = $PanelContainer/VBoxContainer/StatsRow/ScrapCol/ValueLabel

@onready var retry_button: Button = $PanelContainer/VBoxContainer/RetryButton
@onready var retry_label: Label = $PanelContainer/VBoxContainer/RetryButton/Label
@onready var extra_scrap_button: Button = $PanelContainer/VBoxContainer/ExtraScrapButton
@onready var extra_scrap_label: Label = $PanelContainer/VBoxContainer/ExtraScrapButton/Label
@onready var upgrades_button: Button = $PanelContainer/VBoxContainer/SecondaryRow/UpgradesButton
@onready var menu_button: Button = $PanelContainer/VBoxContainer/SecondaryRow/MenuButton

func _ready() -> void:
	visible = false
	GameManager.game_over_triggered.connect(_on_game_over)
	retry_button.pressed.connect(_on_retry_pressed)
	if extra_scrap_button:
		extra_scrap_button.pressed.connect(_on_extra_scrap_pressed)
	if upgrades_button:
		upgrades_button.pressed.connect(_on_upgrades_pressed)
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)

func _on_game_over() -> void:
	var mode = GameManager.current_mode
	var is_boss_rush_victory = (mode == GameManager.GameMode.BOSS_RUSH and GameManager.bosses_defeated_this_run >= 5)

	# 1. Header Banner & Score Title (Clauses 319, 345, 346, 394)
	if mode == GameManager.GameMode.BOSS_RUSH:
		if is_boss_rush_victory:
			banner_label.text = "🏆 BOSS RUSH CLEARED!"
			banner_badge.self_modulate = Color(0.85, 0.96, 0.22) # Electric Lime
			score_title_label.text = "5 / 5 BOSSES"
			best_score_label.text = "ALL-TIME BEST: %d / 5" % SaveManager.best_boss_rush_round
		else:
			banner_label.text = "BOSS RUSH OVER"
			banner_badge.self_modulate = Color(0.92, 0.22, 0.22) # Punch Red
			score_title_label.text = "%d / 5 BOSSES" % GameManager.bosses_defeated_this_run
			best_score_label.text = "ALL-TIME BEST: %d / 5" % SaveManager.best_boss_rush_round
	elif mode == GameManager.GameMode.CHAOS:
		banner_label.text = "⚡ CHAOS RUN OVER"
		banner_badge.self_modulate = Color(0.96, 0.74, 0.15) # Acid Yellow
		score_title_label.text = "WAVE %d" % GameManager.current_wave
		best_score_label.text = "ALL-TIME BEST: WAVE %d" % SaveManager.best_chaos_wave
	else:
		banner_label.text = "RUN OVER"
		banner_badge.self_modulate = Color(0.92, 0.22, 0.22) # Punch Red
		score_title_label.text = "WAVE %d" % GameManager.current_wave
		best_score_label.text = "ALL-TIME BEST: WAVE %d" % SaveManager.highest_wave

	# 2. Best record callout (Clauses 199–201)
	if GameManager.is_new_high_score:
		best_record_badge.visible = true
		best_score_label.visible = false
	else:
		best_record_badge.visible = false
		best_score_label.visible = true

	# 3. Mode Context / Milestone Card (Clauses 204, 207, 322, 350)
	if mode == GameManager.GameMode.NORMAL:
		milestone_card.visible = true
		var hw = SaveManager.highest_wave
		if hw < 5:
			milestone_title.text = "NEXT: WAVE 5 BOSS"
			milestone_subtitle.text = "DEFEAT TO UNLOCK CHAOS MODE"
		elif hw < 10:
			milestone_title.text = "NEXT: WAVE 10 BOSS"
			milestone_subtitle.text = "DEFEAT TO UNLOCK BOSS RUSH"
		elif hw < 15:
			milestone_title.text = "NEXT: WAVE 15"
			milestone_subtitle.text = "UNLOCK HEAVY GUNNER CODEX"
		else:
			milestone_title.text = "OUTPOST DEFENDER"
			milestone_subtitle.text = "ALL COMBAT MODES UNLOCKED"
	elif mode == GameManager.GameMode.CHAOS:
		milestone_card.visible = true
		milestone_title.text = "CHAOS BONUS EARNED"
		milestone_subtitle.text = "+10% SCRAP BONUS APPLIED"
	else:
		milestone_card.visible = true
		if is_boss_rush_victory:
			milestone_title.text = "ALL 5 BOSSES CLEARED!"
			milestone_subtitle.text = "+10 COMPLETION BONUS (50 TOTAL)"
		else:
			milestone_title.text = "5 BOSS CHALLENGE"
			milestone_subtitle.text = "DEFEAT ALL 5 FOR COMPLETION BONUS"

	# 4. Compact Run Stats
	kills_value_label.text = str(GameManager.kills_this_run)
	coins_value_label.text = str(GameManager.coins)
	scrap_value_label.text = "+%d" % GameManager.scrap_earned_this_run

	# 4.5 Extra Scrap Button (Clauses 481–491)
	if extra_scrap_button:
		if GameManager.can_offer_extra_scrap():
			extra_scrap_button.visible = true
			if extra_scrap_label:
				extra_scrap_label.text = "▶ WATCH AD • +%d SCRAP" % GameManager.scrap_earned_this_run
		else:
			extra_scrap_button.visible = false

	# 5. Button label
	if retry_label:
		retry_label.text = "REPLAY" if is_boss_rush_victory else "RETRY"

	visible = true

func _on_extra_scrap_pressed() -> void:
	var bonus = GameManager.scrap_earned_this_run
	GameManager.claim_extra_scrap()
	if extra_scrap_button:
		extra_scrap_button.visible = false
	if scrap_value_label:
		scrap_value_label.text = "+%d (2X!)" % (bonus * 2)

func _on_retry_pressed() -> void:
	visible = false

	# Clear projectiles
	var projectiles = get_tree().get_nodes_in_group("projectiles")
	for p in projectiles:
		if is_instance_valid(p):
			p.queue_free()

	# Clear enemies
	var wave_mgr = get_tree().get_first_node_in_group("wave_manager")
	if wave_mgr and wave_mgr.has_method("clear_all_enemies"):
		wave_mgr.clear_all_enemies()

	# Reset board
	if GameManager.board_ref != null and GameManager.board_ref.has_method("reset_board"):
		GameManager.board_ref.reset_board()

	# Reset run state
	GameManager.reset_run()

func _on_upgrades_pressed() -> void:
	# Handled in Phase 12 (Permanent Upgrades view)
	pass

func _on_menu_pressed() -> void:
	visible = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
