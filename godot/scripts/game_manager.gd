extends Node

## Core Game Manager Autoload Singleton for Poly Fort Godot 4 Vertical Slice.
## Manages game state, coins economy, Base HP, unit purchase, and run lifecycle.

signal coins_changed(amount: int)
signal base_hp_changed(current_hp: float, max_hp: float)
signal wave_changed(wave_num: int)
signal game_over_triggered()
signal game_restarted()

enum GameState { MENU, PLAYING, WAVE_BREAK, GAME_OVER }

var state: GameState = GameState.PLAYING
var coins: int = 150
var purchase_count: int = 0
var base_hp: float = 1000.0
var max_base_hp: float = 1000.0
var current_wave: int = 1

var board_ref: Node = null
var base_ref: Node = null

func _ready() -> void:
	reset_run()

func reset_run() -> void:
	state = GameState.PLAYING
	coins = 150
	purchase_count = 0
	base_hp = 1000.0
	max_base_hp = 1000.0
	current_wave = 1
	coins_changed.emit(coins)
	base_hp_changed.emit(base_hp, max_base_hp)
	wave_changed.emit(current_wave)
	game_restarted.emit()

func get_unit_cost() -> int:
	# Clause 16: ceil(50 * 1.10^purchaseCount)
	var raw_cost = 50.0 * pow(1.10, purchase_count)
	return int(ceil(snappedf(raw_cost, 0.001)))

func can_afford_unit() -> bool:
	return coins >= get_unit_cost()

func add_coins(amount: int) -> void:
	coins += amount
	coins_changed.emit(coins)

func spend_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		coins_changed.emit(coins)
		return true
	return false

func try_purchase_unit() -> bool:
	if state == GameState.GAME_OVER:
		return false
	if not can_afford_unit():
		return false
	if board_ref == null:
		return false

	var empty_slot = board_ref.get_first_empty_slot()
	if empty_slot == null:
		return false # Board full

	var cost = get_unit_cost()
	if spend_coins(cost):
		purchase_count += 1
		board_ref.spawn_unit_on_slot(empty_slot, 1)
		return true
	return false

func damage_base(amount: float) -> void:
	if state == GameState.GAME_OVER:
		return
	base_hp = max(0.0, base_hp - amount)
	base_hp_changed.emit(base_hp, max_base_hp)

	if base_ref != null and base_ref.has_method("trigger_damage_flash"):
		base_ref.trigger_damage_flash()

	if base_hp <= 0.0:
		state = GameState.GAME_OVER
		game_over_triggered.emit()
		if base_ref != null and base_ref.has_method("trigger_destruction"):
			base_ref.trigger_destruction()
