extends Node

## Wave Manager coordinating enemy waves and perimeter marker spawns.
## Spawns enemies from outer perimeter markers towards Central Base (0, 0, 0).
## Wave 1: 7 Basic Enemies. When all defeated, announces Wave Clear and prepares next wave.

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)

@export var enemy_scene: PackedScene = preload("res://scenes/enemies/enemy.tscn")
@export var spawn_interval: float = 1.4

var enemies_to_spawn: int = 0
var enemies_spawned: int = 0
var _spawn_timer: float = 0.0
var _is_wave_active: bool = false
var _break_timer: float = 0.0

var spawn_markers: Array[Marker3D] = []

func _ready() -> void:
	_collect_spawn_markers()
	GameManager.game_restarted.connect(_on_game_restarted)
	# Start Wave 1 after short 1.0s grace period
	_break_timer = 1.0

func _collect_spawn_markers() -> void:
	spawn_markers.clear()
	var markers = get_tree().get_nodes_in_group("spawn_points")
	for m in markers:
		if m is Marker3D:
			spawn_markers.append(m)

func start_wave(wave_num: int) -> void:
	_collect_spawn_markers()
	GameManager.current_wave = wave_num
	GameManager.wave_changed.emit(wave_num)
	
	# Wave 1 = 7 enemies (Clause 48). Subsequent waves scale gently (+2 enemies)
	enemies_to_spawn = 7 + (wave_num - 1) * 2
	enemies_spawned = 0
	_spawn_timer = 0.5
	_is_wave_active = true
	wave_started.emit(wave_num)

func _process(delta: float) -> void:
	if GameManager.state == GameManager.GameState.GAME_OVER:
		return

	# Wave break between rounds
	if not _is_wave_active:
		if _break_timer > 0.0:
			_break_timer -= delta
			if _break_timer <= 0.0:
				start_wave(GameManager.current_wave)
		return

	# Spawning active
	if enemies_spawned < enemies_to_spawn:
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:
			_spawn_timer = spawn_interval
			_spawn_next_enemy()
	else:
		# All spawned, check if all alive enemies are defeated
		var alive_enemies = get_tree().get_nodes_in_group("enemies")
		var has_active_enemy = false
		for e in alive_enemies:
			if is_instance_valid(e) and not e.is_dead:
				has_active_enemy = true
				break
		
		if not has_active_enemy:
			_complete_current_wave()

func _spawn_next_enemy() -> void:
	if enemy_scene == null or spawn_markers.is_empty():
		return

	# Pick random spawn marker around perimeter (Clause 50, 51)
	var marker_idx = randi() % spawn_markers.size()
	var marker = spawn_markers[marker_idx]

	var enemy_instance = enemy_scene.instantiate()
	var enemies_container = get_tree().get_first_node_in_group("enemies_container")
	if enemies_container == null:
		enemies_container = get_parent()

	enemies_container.add_child(enemy_instance)
	enemy_instance.global_position = marker.global_position
	enemies_spawned += 1

func _complete_current_wave() -> void:
	_is_wave_active = false
	wave_completed.emit(GameManager.current_wave)
	
	# Award wave clear bonus coins
	var bonus_coins = 20 + GameManager.current_wave * 5
	GameManager.add_coins(bonus_coins)
	
	# Intermission break (2.5s) before next wave
	GameManager.current_wave += 1
	_break_timer = 2.5

func clear_all_enemies() -> void:
	_is_wave_active = false
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e):
			e.queue_free()

func _on_game_restarted() -> void:
	clear_all_enemies()
	_break_timer = 1.0
	_is_wave_active = false
