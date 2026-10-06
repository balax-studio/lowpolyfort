class_name MainMenu
extends Control

## Neo-Brutalist Main Menu Controller.
## Source of truth: Image B master visual reference (Clauses 53, 54, 114).

@onready var play_button: Button = $UIOverlay/BottomContainer/VBox/PlayButton
@onready var modes_button: Button = $UIOverlay/BottomContainer/VBox/NavRow/ModesButton
@onready var upgrades_button: Button = $UIOverlay/BottomContainer/VBox/NavRow/UpgradesButton
@onready var armory_button: Button = $UIOverlay/BottomContainer/VBox/NavRow/ArmoryButton
@onready var settings_button: Button = $UIOverlay/BottomContainer/VBox/NavRow/SettingsButton

@onready var best_wave_label: Label = $UIOverlay/TopContainer/VBox/HeaderRow/BestWaveBadge/Margin/VBox/BestWaveLabel
@onready var scrap_label: Label = $UIOverlay/TopContainer/VBox/HeaderRow/RightCardsCol/ScrapBadge/Margin/HBox/ScrapLabel
@onready var milestone_label: Label = $UIOverlay/TopContainer/VBox/HeaderRow/RightCardsCol/MilestoneBadge/Margin/HBox/VBox/MilestoneLabel

@onready var mode_select_dialog: Control = $ModeSelectDialog
@onready var armory_view: Control = $ArmoryView
@onready var permanent_upgrades_view: Control = $PermanentUpgradesView
@onready var settings_dialog: Control = $SettingsDialog
@onready var preview_camera_pivot: Node3D = $SubViewportContainer/SubViewport/WorldPreview/CameraPivot

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	if modes_button:
		modes_button.pressed.connect(_on_modes_pressed)
	upgrades_button.pressed.connect(_on_upgrades_pressed)
	armory_button.pressed.connect(_on_armory_pressed)
	settings_button.pressed.connect(_on_settings_pressed)

	if mode_select_dialog:
		mode_select_dialog.mode_selected.connect(_on_mode_selected)

	if settings_dialog and settings_dialog.has_signal("closed"):
		settings_dialog.closed.connect(refresh_stats)

	SaveManager.save_updated.connect(refresh_stats)
	refresh_stats()

func _process(_delta: float) -> void:
	# Keep fixed 3/4 diorama angle locked to match Image B framing
	pass

func refresh_stats() -> void:
	if best_wave_label:
		best_wave_label.text = "BEST WAVE: %d" % SaveManager.highest_wave
	if scrap_label:
		scrap_label.text = "%d SCRAP" % SaveManager.total_scrap
	if milestone_label:
		var hw = SaveManager.highest_wave
		if hw < 5:
			milestone_label.text = "NEXT: DEFEAT WAVE 5 BOSS"
		elif hw < 10:
			milestone_label.text = "NEXT: UNLOCK SNIPER AT WAVE 10"
		elif hw < 15:
			milestone_label.text = "NEXT: UNLOCK HEAVY GUNNER AT WAVE 15"
		else:
			milestone_label.text = "RECORD SURVIVAL MISSION"

func _on_play_pressed() -> void:
	# Clause 112: If Chaos is unlocked, present ModeSelectDialog. Else start Normal directly.
	if SaveManager.chaos_unlocked:
		if mode_select_dialog:
			mode_select_dialog.open()
	else:
		start_game(GameManager.GameMode.NORMAL)

func _on_modes_pressed() -> void:
	if mode_select_dialog:
		mode_select_dialog.open()

func _on_mode_selected(mode: GameManager.GameMode) -> void:
	start_game(mode)

func start_game(mode: GameManager.GameMode) -> void:
	GameManager.current_mode = mode
	GameManager.reset_run()
	if get_tree().current_scene == self:
		get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_upgrades_pressed() -> void:
	if permanent_upgrades_view:
		permanent_upgrades_view.open()

func _on_armory_pressed() -> void:
	if armory_view:
		armory_view.open()

func _on_settings_pressed() -> void:
	if settings_dialog:
		settings_dialog.open()
