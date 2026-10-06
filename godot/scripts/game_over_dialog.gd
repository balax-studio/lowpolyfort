extends Control

## Neo-brutalist Game Over Dialog with clean run reset.

@onready var waves_survived_label: Label = $PanelContainer/VBoxContainer/WavesSurvivedLabel
@onready var retry_button: Button = $PanelContainer/VBoxContainer/RetryButton

func _ready() -> void:
	visible = false
	GameManager.game_over_triggered.connect(_on_game_over)
	retry_button.pressed.connect(_on_retry_pressed)

func _on_game_over() -> void:
	if waves_survived_label:
		waves_survived_label.text = "WAVE REACHED: %d" % GameManager.current_wave
	visible = true

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
