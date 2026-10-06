extends Node

const WaveDefinition = preload("res://scripts/wave_definition.gd")

## Wave Manager coordinating enemy waves and perimeter marker spawns.
## Source of truth: Flutter lib/systems/wave_system.dart & lib/systems/spawn_system.dart.

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal boss_warning_triggered(wave_number: int)
signal upgrade_requested()

@export var enemy_scene: PackedScene = preload("res://scenes/enemies/enemy.tscn")

var _queue: Array = []
var _spawn_timer: float = 0.0
var _is_wave_active: bool = false
var _is_intermission: bool = false
var _break_timer: float = 0.0
var current_wave_def = null

var spawn_markers: Array[Marker3D] = []

func _ready() -> void:
	_collect_spawn_markers()
	GameManager.game_restarted.connect(_on_game_restarted)
	_reset_break_timer()

func _reset_break_timer() -> void:
	if GameManager.current_mode == GameManager.GameMode.BOSS_RUSH:
		_break_timer = GameBalance.BOSS_RUSH_INITIAL_PREP_SECONDS
	else:
		_break_timer = GameBalance.WAVE_COUNTDOWN_SECONDS

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

	if GameManager.current_mode == GameManager.GameMode.BOSS_RUSH:
		current_wave_def = WaveDefinition.generate_boss_rush_round(wave_num)
	elif GameManager.current_mode == GameManager.GameMode.CHAOS:
		var prev_type = GameManager.active_chaos_modifier.type if GameManager.active_chaos_modifier != null else ChaosModifier.ChaosModifierType.NONE
		GameManager.active_chaos_modifier = ChaosModifier.resolve_for_wave(wave_num, prev_type)
		current_wave_def = WaveDefinition.generate(wave_num, GameManager.active_chaos_modifier)
	else:
		GameManager.active_chaos_modifier = null
		current_wave_def = WaveDefinition.generate(wave_num)

	_queue.clear()
	for s in current_wave_def.spawns:
		_queue.append(s)

	# Sort by delay_seconds ascending
	_queue.sort_custom(func(a, b): return a.delay_seconds < b.delay_seconds)

	_spawn_timer = 0.0
	_is_wave_active = true
	_is_intermission = false
	wave_started.emit(wave_num)

func _process(delta: float) -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return

	# Pre-wave initial countdown or break
	if not _is_wave_active and not _is_intermission:
		if _break_timer > 0.0:
			_break_timer -= delta
			if _break_timer <= 0.0:
				start_wave(GameManager.current_wave)
		return

	# Intermission after wave cleared
	if _is_intermission:
		_break_timer -= delta
		if _break_timer <= 0.0:
			_is_intermission = false
			if GameManager.current_mode == GameManager.GameMode.BOSS_RUSH:
				# In Boss Rush: every round completion drafts an upgrade (Clause 342)
				_trigger_upgrade_dialog()
			elif (GameManager.current_wave - 1) % GameBalance.UPGRADE_INTERVAL == 0:
				# Normal / Chaos mode: upgrade every 3 waves (3, 6, 9... Clause 86)
				_trigger_upgrade_dialog()
			else:
				start_wave(GameManager.current_wave)
		return

	# Spawning active with 40 enemy soft cap (Clauses 83, 636)
	_spawn_timer += delta
	while not _queue.is_empty() and _queue[0].delay_seconds <= _spawn_timer:
		var alive_count = get_tree().get_nodes_in_group("enemies").size()
		if alive_count >= GameBalance.MAX_ENEMIES_ALIVE:
			break

		var entry = _queue.pop_front()
		if entry.trigger_warning:
			boss_warning_triggered.emit(GameManager.current_wave)
			GameManager.boss_warning_triggered.emit(GameManager.current_wave)
		_spawn_enemy(entry)

	# Check if all enemies in wave are cleared
	if _queue.is_empty():
		var alive_enemies = get_tree().get_nodes_in_group("enemies")
		var has_active_enemy = false
		for e in alive_enemies:
			if is_instance_valid(e) and not e.is_dead:
				has_active_enemy = true
				break

		if not has_active_enemy:
			_complete_current_wave()

func _spawn_enemy(entry) -> void:
	if enemy_scene == null or spawn_markers.is_empty():
		return

	# Select marker based on lane_index (modulo wrap for 8 perimeter markers)
	var marker_idx = entry.lane_index % spawn_markers.size()
	var marker = spawn_markers[marker_idx]

	var enemy_instance = enemy_scene.instantiate()
	var enemies_container = get_tree().get_first_node_in_group("enemies_container")
	if enemies_container == null:
		enemies_container = get_parent()

	enemies_container.add_child(enemy_instance)
	enemy_instance.global_position = marker.global_position

	var enemy_def = EnemyDefinition.get_definition(entry.enemy_type)
	enemy_instance.setup_from_definition(
		enemy_def,
		GameManager.current_wave,
		entry.hp_multiplier,
		entry.speed_multiplier,
		entry.coin_multiplier,
		entry.visual_scale
	)

func _complete_current_wave() -> void:
	_is_wave_active = false
	wave_completed.emit(GameManager.current_wave)

	if GameManager.current_mode == GameManager.GameMode.BOSS_RUSH:
		if GameManager.bosses_defeated_this_run >= GameBalance.BOSS_RUSH_TOTAL_ROUNDS:
			GameManager.trigger_boss_rush_victory()
			return
		else:
			GameManager.current_wave += 1
			_is_intermission = true
			_break_timer = GameBalance.BOSS_RUSH_INTER_ROUND_PREP_SECONDS
	else:
		GameManager.current_wave += 1
		_is_intermission = true
		_break_timer = GameBalance.WAVE_CLEAR_INTERMISSION_SECONDS

func skip_prep() -> void:
	if _break_timer > 0.0:
		_break_timer = 0.0

func _trigger_upgrade_dialog() -> void:
	GameManager.state = GameManager.GameState.UPGRADE_SELECTION
	upgrade_requested.emit()
	var dialog = get_tree().get_first_node_in_group("upgrade_dialog")
	if dialog and dialog.has_method("open_draft"):
		if not dialog.upgrade_selected.is_connected(on_upgrade_chosen):
			dialog.upgrade_selected.connect(on_upgrade_chosen)
		dialog.open_draft()
	else:
		# Fallback if no UI dialog registered in tree
		on_upgrade_chosen()

func on_upgrade_chosen(_card: UpgradeCard = null) -> void:
	GameManager.state = GameManager.GameState.PLAYING
	start_wave(GameManager.current_wave)

func clear_all_enemies() -> void:
	_is_wave_active = false
	_queue.clear()
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e):
			e.queue_free()

func _on_game_restarted() -> void:
	clear_all_enemies()
	_reset_break_timer()
	_is_wave_active = false
	_is_intermission = false
