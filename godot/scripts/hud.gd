extends Control

## Neo-brutalist Mobile Portrait HUD.
## Displays Wave number, Central Base HP bar, Coin counter, and the ADD UNIT purchase button.

@onready var wave_label: Label = $TopBar/WaveBadge/WaveLabel
@onready var hp_label: Label = $TopBar/HpBarContainer/HpLabel
@onready var hp_bar: ProgressBar = $TopBar/HpBarContainer/HpProgressBar
@onready var coins_label: Label = $TopBar/CoinsBadge/CoinsLabel
@onready var add_unit_button: Button = $BottomBar/AddUnitButton
@onready var btn_text_label: Label = $BottomBar/AddUnitButton/ButtonText

func _ready() -> void:
	# Connect to GameManager signals
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.base_hp_changed.connect(_on_base_hp_changed)
	GameManager.wave_changed.connect(_on_wave_changed)
	GameManager.game_over_triggered.connect(_on_game_over)
	GameManager.game_restarted.connect(_on_game_restarted)

	add_unit_button.pressed.connect(_on_add_unit_pressed)

	# Initial values
	_update_hud_display()

func _update_hud_display() -> void:
	_on_wave_changed(GameManager.current_wave)
	_on_base_hp_changed(GameManager.base_hp, GameManager.max_base_hp)
	_on_coins_changed(GameManager.coins)

func _on_coins_changed(current_coins: int) -> void:
	if coins_label:
		coins_label.text = "%d 🪙" % current_coins
	
	var cost = GameManager.get_unit_cost()
	var can_buy = GameManager.can_afford_unit() and GameManager.state != GameManager.GameState.GAME_OVER
	
	# Check if board is full
	if GameManager.board_ref != null and GameManager.board_ref.get_first_empty_slot() == null:
		can_buy = false
		if btn_text_label:
			btn_text_label.text = "BOARD FULL"
	else:
		if btn_text_label:
			btn_text_label.text = "ADD UNIT (%d 🪙)" % cost

	if add_unit_button:
		add_unit_button.disabled = not can_buy

func _on_base_hp_changed(current_hp: float, max_hp: float) -> void:
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = current_hp
	if hp_label:
		hp_label.text = "BASE: %d / %d" % [int(current_hp), int(max_hp)]

func _on_wave_changed(wave_num: int) -> void:
	if wave_label:
		wave_label.text = "WAVE %d" % wave_num

func _on_add_unit_pressed() -> void:
	# Visual button punch
	var tween = create_tween()
	tween.tween_property(add_unit_button, "scale", Vector3(0.95, 0.95, 1.0), 0.05)
	tween.tween_property(add_unit_button, "scale", Vector3(1.0, 1.0, 1.0), 0.08)

	var success = GameManager.try_purchase_unit()
	if success:
		_on_coins_changed(GameManager.coins)

func _on_game_over() -> void:
	if add_unit_button:
		add_unit_button.disabled = true

func _on_game_restarted() -> void:
	_update_hud_display()
