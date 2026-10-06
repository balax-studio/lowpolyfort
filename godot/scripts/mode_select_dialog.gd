class_name ModeSelectDialog
extends Control

## Neo-Brutalist Mode Select Dialog.
## Source of truth: Flutter lib/ui/main_menu/mode_select_dialog.dart (Clauses 291–296).

signal mode_selected(mode: GameManager.GameMode)
signal closed()

@onready var normal_card: Button = $CardContainer/VBoxContainer/NormalCard
@onready var chaos_card: Button = $CardContainer/VBoxContainer/ChaosCard
@onready var boss_rush_card: Button = $CardContainer/VBoxContainer/BossRushCard
@onready var close_button: Button = $CardContainer/VBoxContainer/Header/CloseButton

@onready var normal_best_label: Label = $CardContainer/VBoxContainer/NormalCard/VBox/BestLabel
@onready var chaos_sub_label: Label = $CardContainer/VBoxContainer/ChaosCard/VBox/SubLabel
@onready var chaos_best_label: Label = $CardContainer/VBoxContainer/ChaosCard/VBox/BestLabel
@onready var boss_rush_sub_label: Label = $CardContainer/VBoxContainer/BossRushCard/VBox/SubLabel
@onready var boss_rush_best_label: Label = $CardContainer/VBoxContainer/BossRushCard/VBox/BestLabel

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	normal_card.pressed.connect(_on_normal_pressed)
	chaos_card.pressed.connect(_on_chaos_pressed)
	boss_rush_card.pressed.connect(_on_boss_rush_pressed)
	refresh_state()

func open() -> void:
	refresh_state()
	visible = true

func close() -> void:
	visible = false
	closed.emit()

func refresh_state() -> void:
	# Normal mode is always unlocked
	if normal_best_label:
		normal_best_label.text = "BEST WAVE: %d" % SaveManager.highest_wave

	# Chaos mode
	var chaos_unlocked = SaveManager.chaos_unlocked
	if chaos_sub_label:
		if chaos_unlocked:
			chaos_sub_label.text = "EVERY WAVE CHANGES THE RULES"
			chaos_best_label.text = "BEST WAVE: %d" % SaveManager.best_chaos_wave
			chaos_best_label.visible = true
		else:
			chaos_sub_label.text = "🔒 DEFEAT NORMAL WAVE 5 BOSS"
			chaos_best_label.visible = false

	# Boss Rush mode
	var boss_rush_unlocked = SaveManager.boss_rush_unlocked
	if boss_rush_sub_label:
		if boss_rush_unlocked:
			boss_rush_sub_label.text = "5 BOSSES • ONE RUN"
			boss_rush_best_label.text = "BEST: %d / 5" % SaveManager.best_boss_rush_round
			boss_rush_best_label.visible = true
		else:
			boss_rush_sub_label.text = "🔒 DEFEAT NORMAL WAVE 10 BOSS"
			boss_rush_best_label.visible = false

func _on_close_pressed() -> void:
	close()

func _on_normal_pressed() -> void:
	close()
	mode_selected.emit(GameManager.GameMode.NORMAL)

func _on_chaos_pressed() -> void:
	if SaveManager.chaos_unlocked:
		close()
		mode_selected.emit(GameManager.GameMode.CHAOS)
	else:
		_play_shake_animation(chaos_card)

func _on_boss_rush_pressed() -> void:
	if SaveManager.boss_rush_unlocked:
		close()
		mode_selected.emit(GameManager.GameMode.BOSS_RUSH)
	else:
		_play_shake_animation(boss_rush_card)

func _play_shake_animation(node: Control) -> void:
	var tween = create_tween()
	var orig_x = node.position.x
	tween.tween_property(node, "position:x", orig_x - 8.0, 0.06)
	tween.tween_property(node, "position:x", orig_x + 8.0, 0.06)
	tween.tween_property(node, "position:x", orig_x - 5.0, 0.06)
	tween.tween_property(node, "position:x", orig_x + 5.0, 0.06)
	tween.tween_property(node, "position:x", orig_x, 0.06)
