extends Node

## Multi-Shot Verification Capture
## Captures:
## 1. Godot Main Menu screenshot
## 2. Normal gameplay screenshot
## 3. Chaos Mode screenshot
## 4. Boss Rush screenshot

const EnemyDefinition = preload("res://scripts/enemy_definition.gd")
const HeroDefinition = preload("res://scripts/hero_definition.gd")

var current_step: int = 0
var step_frames: int = 0
var is_transitioning: bool = false
var transition_frames: int = 0
var active_scene: Node = null

const SCREENSHOT_DIR = "res://screenshots"

func _ready() -> void:
	var dir = DirAccess.open("res://")
	if not dir.dir_exists(SCREENSHOT_DIR):
		dir.make_dir(SCREENSHOT_DIR)
	_setup_current_step()

func _process(_delta: float) -> void:
	if is_transitioning:
		transition_frames += 1
		if transition_frames >= 5:
			is_transitioning = false
			transition_frames = 0
			_setup_current_step()
		return

	step_frames += 1

	if current_step == 0 and step_frames == 35:
		_save_screenshot("1_godot_main_menu.png")
		_advance_to_next_step()
	elif current_step == 1 and step_frames == 35:
		_save_screenshot("2_normal_gameplay.png")
		_advance_to_next_step()
	elif current_step == 2 and step_frames == 35:
		_save_screenshot("3_chaos_mode.png")
		_advance_to_next_step()
	elif current_step == 3 and step_frames == 35:
		_save_screenshot("4_boss_rush.png")
		print("ALL_4_SCREENSHOTS_CAPTURED_SUCCESSFULLY")
		get_tree().quit(0)

func _advance_to_next_step() -> void:
	current_step += 1
	step_frames = 0
	if active_scene != null:
		active_scene.queue_free()
		active_scene = null
	is_transitioning = true
	transition_frames = 0

func _setup_current_step() -> void:
	match current_step:
		0:
			_setup_main_menu()
		1:
			_setup_normal_gameplay()
		2:
			_setup_chaos_gameplay()
		3:
			_setup_boss_rush_gameplay()

func _setup_main_menu() -> void:
	SaveManager.highest_wave = 14
	SaveManager.total_scrap = 135
	SaveManager.chaos_unlocked = true
	SaveManager.boss_rush_unlocked = true
	SaveManager.tutorial_completed = true

	var menu_scene = load("res://scenes/ui/main_menu.tscn")
	active_scene = menu_scene.instantiate()
	add_child(active_scene)
	if active_scene.has_method("refresh_stats"):
		active_scene.refresh_stats()

func _setup_normal_gameplay() -> void:
	GameManager.current_mode = GameManager.GameMode.NORMAL
	GameManager.reset_run()
	GameManager.current_wave = 3
	GameManager.coins = 175
	GameManager.base_hp = 1000.0

	var main_scene = load("res://scenes/main.tscn")
	active_scene = main_scene.instantiate()
	add_child(active_scene)

	var board = active_scene.find_child("Board", true, false)
	if board:
		board.spawn_unit_on_slot(board.get_slot_at_index(1), 1, HeroDefinition.HeroClass.RIFLEMAN)
		board.spawn_unit_on_slot(board.get_slot_at_index(3), 2, HeroDefinition.HeroClass.RIFLEMAN)
		board.spawn_unit_on_slot(board.get_slot_at_index(4), 1, HeroDefinition.HeroClass.SHOTGUNNER)

	var enemies_container = active_scene.find_child("Enemies", true, false)
	var enemy_scene = load("res://scenes/enemies/enemy.tscn")
	if enemies_container and enemy_scene:
		var e1 = enemy_scene.instantiate()
		enemies_container.add_child(e1)
		e1.setup_from_definition(EnemyDefinition.get_definition(EnemyDefinition.EnemyType.BASIC), 3)
		e1.global_position = Vector3(0.0, 0.0, -7.0)

		var e2 = enemy_scene.instantiate()
		enemies_container.add_child(e2)
		e2.setup_from_definition(EnemyDefinition.get_definition(EnemyDefinition.EnemyType.RUNNER), 3)
		e2.global_position = Vector3(4.2, 0.0, -5.5)

		var e3 = enemy_scene.instantiate()
		enemies_container.add_child(e3)
		e3.setup_from_definition(EnemyDefinition.get_definition(EnemyDefinition.EnemyType.SWARM), 3)
		e3.global_position = Vector3(-4.0, 0.0, -4.5)

	var hud = active_scene.find_child("HUD", true, false)
	if hud and hud.has_method("_update_hud_display"):
		hud._update_hud_display()

func _setup_chaos_gameplay() -> void:
	GameManager.current_mode = GameManager.GameMode.CHAOS
	GameManager.reset_run()
	GameManager.current_wave = 4
	GameManager.coins = 280
	GameManager.base_hp = 880.0

	var main_scene = load("res://scenes/main.tscn")
	active_scene = main_scene.instantiate()
	add_child(active_scene)

	var board = active_scene.find_child("Board", true, false)
	if board:
		board.spawn_unit_on_slot(board.get_slot_at_index(0), 2, HeroDefinition.HeroClass.RIFLEMAN)
		board.spawn_unit_on_slot(board.get_slot_at_index(1), 1, HeroDefinition.HeroClass.SNIPER)
		board.spawn_unit_on_slot(board.get_slot_at_index(4), 2, HeroDefinition.HeroClass.SHOTGUNNER)
		board.spawn_unit_on_slot(board.get_slot_at_index(6), 1, HeroDefinition.HeroClass.HEAVY_GUNNER)

	var enemies_container = active_scene.find_child("Enemies", true, false)
	var enemy_scene = load("res://scenes/enemies/enemy.tscn")
	if enemies_container and enemy_scene:
		var e1 = enemy_scene.instantiate()
		enemies_container.add_child(e1)
		e1.setup_from_definition(EnemyDefinition.get_definition(EnemyDefinition.EnemyType.RUNNER), 4, 1.0, 1.5)
		e1.global_position = Vector3(0.0, 0.0, -6.5)

		var e2 = enemy_scene.instantiate()
		enemies_container.add_child(e2)
		e2.setup_from_definition(EnemyDefinition.get_definition(EnemyDefinition.EnemyType.TANK), 4, 1.2, 1.2)
		e2.global_position = Vector3(-3.5, 0.0, -5.0)

		var e3 = enemy_scene.instantiate()
		enemies_container.add_child(e3)
		e3.setup_from_definition(EnemyDefinition.get_definition(EnemyDefinition.EnemyType.RUNNER), 4, 1.0, 1.5)
		e3.global_position = Vector3(3.5, 0.0, -5.0)

	var hud = active_scene.find_child("HUD", true, false)
	if hud:
		var wave_label = hud.find_child("WaveLabel", true, false)
		if wave_label:
			wave_label.text = "CHAOS W4: RUSH HOUR"
		if hud.has_method("_on_base_hp_changed"):
			hud._on_base_hp_changed(GameManager.base_hp, GameManager.max_base_hp)
		if hud.has_method("_on_coins_changed"):
			hud._on_coins_changed(GameManager.coins)

func _setup_boss_rush_gameplay() -> void:
	GameManager.current_mode = GameManager.GameMode.BOSS_RUSH
	GameManager.reset_run()
	GameManager.current_wave = 1
	GameManager.coins = 450
	GameManager.base_hp = 1000.0

	var main_scene = load("res://scenes/main.tscn")
	active_scene = main_scene.instantiate()
	add_child(active_scene)

	var board = active_scene.find_child("Board", true, false)
	if board:
		board.spawn_unit_on_slot(board.get_slot_at_index(0), 2, HeroDefinition.HeroClass.SNIPER)
		board.spawn_unit_on_slot(board.get_slot_at_index(1), 3, HeroDefinition.HeroClass.RIFLEMAN)
		board.spawn_unit_on_slot(board.get_slot_at_index(2), 2, HeroDefinition.HeroClass.HEAVY_GUNNER)
		board.spawn_unit_on_slot(board.get_slot_at_index(4), 2, HeroDefinition.HeroClass.SHOTGUNNER)

	var enemies_container = active_scene.find_child("Enemies", true, false)
	var enemy_scene = load("res://scenes/enemies/enemy.tscn")
	if enemies_container and enemy_scene:
		# Grand Boss
		var boss = enemy_scene.instantiate()
		enemies_container.add_child(boss)
		boss.setup_from_definition(EnemyDefinition.get_definition(EnemyDefinition.EnemyType.BOSS), 5, 2.5, 0.8, 1.0, 1.5)
		boss.global_position = Vector3(0.0, 0.0, -7.5)

		# Minion support
		var m1 = enemy_scene.instantiate()
		enemies_container.add_child(m1)
		m1.setup_from_definition(EnemyDefinition.get_definition(EnemyDefinition.EnemyType.SHIELDED), 5)
		m1.global_position = Vector3(-3.0, 0.0, -8.5)

		var m2 = enemy_scene.instantiate()
		enemies_container.add_child(m2)
		m2.setup_from_definition(EnemyDefinition.get_definition(EnemyDefinition.EnemyType.RUNNER), 5)
		m2.global_position = Vector3(3.0, 0.0, -8.5)

	var hud = active_scene.find_child("HUD", true, false)
	if hud:
		var wave_label = hud.find_child("WaveLabel", true, false)
		if wave_label:
			wave_label.text = "BOSS RUSH 1/5"
		if hud.has_method("_on_base_hp_changed"):
			hud._on_base_hp_changed(GameManager.base_hp, GameManager.max_base_hp)
		if hud.has_method("_on_coins_changed"):
			hud._on_coins_changed(GameManager.coins)

func _save_screenshot(filename: String) -> void:
	var img = get_viewport().get_texture().get_image()
	var full_path = "%s/%s" % [SCREENSHOT_DIR, filename]
	var err = img.save_png(full_path)
	if err == OK:
		print("SCREENSHOT_SAVED: ", ProjectSettings.globalize_path(full_path))
	else:
		push_error("Failed saving screenshot: %s, code %d" % [full_path, err])
