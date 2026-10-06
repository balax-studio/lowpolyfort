class_name WaveDefinition
extends RefCounted

## Wave Definition & Procedural Generator.
## Source of truth: Flutter lib/models/wave_data.dart (Clauses 73–82, 630–635).

class WaveSpawnEntry:
	var enemy_type: EnemyDefinition.EnemyType
	var delay_seconds: float
	var lane_index: int
	var trigger_warning: bool = false
	var hp_multiplier: float = 1.0
	var speed_multiplier: float = 1.0
	var coin_multiplier: float = 1.0
	var visual_scale: float = 1.0

	func _init(
		p_type: EnemyDefinition.EnemyType,
		p_delay: float,
		p_lane: int,
		p_warn: bool = false,
		p_hp: float = 1.0,
		p_spd: float = 1.0,
		p_coin: float = 1.0,
		p_scale: float = 1.0
	) -> void:
		enemy_type = p_type
		delay_seconds = p_delay
		lane_index = p_lane
		trigger_warning = p_warn
		hp_multiplier = p_hp
		speed_multiplier = p_spd
		coin_multiplier = p_coin
		visual_scale = p_scale

var wave_number: int = 1
var is_boss_wave: bool = false
var chaos_modifier: ChaosModifier = null
var spawns: Array[WaveSpawnEntry] = []

static func generate(wave: int, modifier: ChaosModifier = null):
	var mod = modifier if modifier != null else ChaosModifier.get_none()
	var is_boss = (wave % GameBalance.BOSS_INTERVAL == 0)
	var wave_def = load("res://scripts/wave_definition.gd").new()
	wave_def.wave_number = wave
	wave_def.is_boss_wave = is_boss
	wave_def.chaos_modifier = mod

	var rng = RandomNumberGenerator.new()
	rng.seed = wave * 9973

	var base_interval = GameBalance.get_wave_spawn_interval(wave)
	var current_delay: float = 0.6

	var add_spawns = func(types: Array[EnemyDefinition.EnemyType]):
		var scaled_types = types.duplicate()
		if mod.enemy_count_multiplier != 1.0:
			var target_count = int(ceil(float(types.size()) * mod.enemy_count_multiplier))
			if target_count > types.size():
				scaled_types.clear()
				for i in range(target_count):
					scaled_types.append(types[i % types.size()])
			elif target_count < types.size():
				scaled_types = types.slice(0, maxi(1, target_count))

		for t in scaled_types:
			var lane = rng.randi_range(0, 7)
			var interval = (base_interval * 0.45) if t == EnemyDefinition.EnemyType.SWARM else base_interval
			current_delay += interval
			wave_def.spawns.append(WaveSpawnEntry.new(
				t,
				current_delay,
				lane,
				false,
				mod.enemy_hp_multiplier,
				mod.enemy_speed_multiplier,
				mod.enemy_coin_multiplier,
				mod.enemy_scale_multiplier
			))

	if wave == 1:
		# Clause 73: 7 Basic
		var r: Array[EnemyDefinition.EnemyType] = []
		for i in range(7): r.append(EnemyDefinition.EnemyType.BASIC)
		add_spawns.call(r)
	elif wave == 2:
		# Clause 73: 7 Basic, 2 Runner
		var r: Array[EnemyDefinition.EnemyType] = [
			EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.BASIC,
			EnemyDefinition.EnemyType.RUNNER, EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.BASIC,
			EnemyDefinition.EnemyType.RUNNER, EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.BASIC
		]
		add_spawns.call(r)
	elif wave == 3:
		# Clause 73: 8 Basic, 3 Runner
		var r: Array[EnemyDefinition.EnemyType] = [
			EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.RUNNER,
			EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.RUNNER,
			EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.RUNNER,
			EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.BASIC
		]
		add_spawns.call(r)
	elif wave == 4:
		# Clause 73: 8 Basic, 3 Runner, 2 Swarm
		var r: Array[EnemyDefinition.EnemyType] = [
			EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.RUNNER,
			EnemyDefinition.EnemyType.SWARM, EnemyDefinition.EnemyType.SWARM,
			EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.RUNNER,
			EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.RUNNER,
			EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.BASIC
		]
		add_spawns.call(r)
	elif wave == 5:
		# Clause 74 & 75: 8 Basic, 4 Runner, 3 Swarm + 1 BRUTE BOSS
		var first_half: Array[EnemyDefinition.EnemyType] = [
			EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.RUNNER, EnemyDefinition.EnemyType.BASIC,
			EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.RUNNER, EnemyDefinition.EnemyType.SWARM
		]
		add_spawns.call(first_half)

		# Boss spawn
		current_delay += 1.2
		wave_def.spawns.append(WaveSpawnEntry.new(
			EnemyDefinition.EnemyType.BOSS,
			current_delay,
			rng.randi_range(0, 7),
			true,
			mod.enemy_hp_multiplier,
			mod.enemy_speed_multiplier,
			mod.enemy_coin_multiplier,
			mod.enemy_scale_multiplier
		))
		current_delay += 1.8

		var second_half: Array[EnemyDefinition.EnemyType] = [
			EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.RUNNER, EnemyDefinition.EnemyType.SWARM, EnemyDefinition.EnemyType.SWARM,
			EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.RUNNER, EnemyDefinition.EnemyType.BASIC,
			EnemyDefinition.EnemyType.BASIC
		]
		add_spawns.call(second_half)
	elif wave == 6:
		# Clause 77: 8 Basic, 4 Runner, 3 Tank, 2 Swarm
		var r: Array[EnemyDefinition.EnemyType] = [
			EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.SWARM, EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.SWARM,
			EnemyDefinition.EnemyType.RUNNER, EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.RUNNER,
			EnemyDefinition.EnemyType.TANK, EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.RUNNER, EnemyDefinition.EnemyType.BASIC,
			EnemyDefinition.EnemyType.RUNNER, EnemyDefinition.EnemyType.TANK, EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.TANK,
			EnemyDefinition.EnemyType.BASIC
		]
		add_spawns.call(r)
	elif wave == 7:
		# Clause 78: 7 Basic, 5 Runner, 3 Tank, 4 Swarm
		var r: Array[EnemyDefinition.EnemyType] = [
			EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.RUNNER, EnemyDefinition.EnemyType.TANK,
			EnemyDefinition.EnemyType.SWARM, EnemyDefinition.EnemyType.SWARM, EnemyDefinition.EnemyType.RUNNER, EnemyDefinition.EnemyType.BASIC,
			EnemyDefinition.EnemyType.TANK, EnemyDefinition.EnemyType.SWARM, EnemyDefinition.EnemyType.SWARM, EnemyDefinition.EnemyType.RUNNER,
			EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.TANK, EnemyDefinition.EnemyType.RUNNER, EnemyDefinition.EnemyType.BASIC,
			EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.RUNNER, EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.BASIC
		]
		add_spawns.call(r)
	elif wave == 8:
		# Clause 79: 7 Basic, 4 Runner, 4 Tank, 4 Swarm, 2 Shielded
		var r: Array[EnemyDefinition.EnemyType] = [
			EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.RUNNER, EnemyDefinition.EnemyType.SHIELDED,
			EnemyDefinition.EnemyType.TANK, EnemyDefinition.EnemyType.SWARM, EnemyDefinition.EnemyType.SWARM, EnemyDefinition.EnemyType.BASIC,
			EnemyDefinition.EnemyType.RUNNER, EnemyDefinition.EnemyType.TANK, EnemyDefinition.EnemyType.SHIELDED,
			EnemyDefinition.EnemyType.SWARM, EnemyDefinition.EnemyType.SWARM, EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.RUNNER,
			EnemyDefinition.EnemyType.TANK, EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.TANK, EnemyDefinition.EnemyType.RUNNER,
			EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.BASIC
		]
		add_spawns.call(r)
	elif wave == 9:
		# Clause 80: 7 Basic, 4 Runner, 4 Tank, 5 Swarm, 3 Shielded
		var r: Array[EnemyDefinition.EnemyType] = [
			EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.RUNNER, EnemyDefinition.EnemyType.SHIELDED, EnemyDefinition.EnemyType.TANK,
			EnemyDefinition.EnemyType.SWARM, EnemyDefinition.EnemyType.SWARM, EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.RUNNER,
			EnemyDefinition.EnemyType.SHIELDED, EnemyDefinition.EnemyType.TANK, EnemyDefinition.EnemyType.SWARM, EnemyDefinition.EnemyType.SWARM,
			EnemyDefinition.EnemyType.SWARM, EnemyDefinition.EnemyType.TANK, EnemyDefinition.EnemyType.SHIELDED, EnemyDefinition.EnemyType.BASIC,
			EnemyDefinition.EnemyType.RUNNER, EnemyDefinition.EnemyType.TANK, EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.RUNNER,
			EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.BASIC
		]
		add_spawns.call(r)
	elif wave == 10:
		# Clause 81: 7 Basic, 5 Runner, 4 Tank, 5 Swarm, 4 Shielded + Boss
		var first_part: Array[EnemyDefinition.EnemyType] = [
			EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.RUNNER, EnemyDefinition.EnemyType.SHIELDED, EnemyDefinition.EnemyType.TANK,
			EnemyDefinition.EnemyType.SWARM, EnemyDefinition.EnemyType.SWARM, EnemyDefinition.EnemyType.RUNNER, EnemyDefinition.EnemyType.BASIC,
			EnemyDefinition.EnemyType.SHIELDED, EnemyDefinition.EnemyType.TANK
		]
		add_spawns.call(first_part)

		current_delay += 1.0
		wave_def.spawns.append(WaveSpawnEntry.new(
			EnemyDefinition.EnemyType.BOSS,
			current_delay,
			rng.randi_range(0, 7),
			true,
			mod.enemy_hp_multiplier,
			mod.enemy_speed_multiplier,
			mod.enemy_coin_multiplier,
			mod.enemy_scale_multiplier
		))
		current_delay += 1.5

		var second_part: Array[EnemyDefinition.EnemyType] = [
			EnemyDefinition.EnemyType.SWARM, EnemyDefinition.EnemyType.SWARM, EnemyDefinition.EnemyType.SWARM,
			EnemyDefinition.EnemyType.TANK, EnemyDefinition.EnemyType.SHIELDED, EnemyDefinition.EnemyType.SHIELDED,
			EnemyDefinition.EnemyType.RUNNER, EnemyDefinition.EnemyType.TANK, EnemyDefinition.EnemyType.RUNNER, EnemyDefinition.EnemyType.RUNNER,
			EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.BASIC, EnemyDefinition.EnemyType.BASIC,
			EnemyDefinition.EnemyType.BASIC
		]
		add_spawns.call(second_part)
	else:
		# Wave 11+ intelligent generator
		var total_count = int(ceil(float(GameBalance.get_wave_enemy_count(wave)) * mod.enemy_count_multiplier))
		var types: Array[EnemyDefinition.EnemyType] = []
		for i in range(total_count):
			var roll = rng.randf()
			types.append(roll_wave_11_plus_enemy(roll, wave))

		var half = types.size() / 2
		add_spawns.call(types.slice(0, half))

		if is_boss:
			current_delay += 1.0
			wave_def.spawns.append(WaveSpawnEntry.new(
				EnemyDefinition.EnemyType.BOSS,
				current_delay,
				rng.randi_range(0, 7),
				true,
				mod.enemy_hp_multiplier,
				mod.enemy_speed_multiplier,
				mod.enemy_coin_multiplier,
				mod.enemy_scale_multiplier
			))
			current_delay += 1.5

		add_spawns.call(types.slice(half))

	return wave_def

static func roll_wave_11_plus_enemy(roll: float, wave: int) -> EnemyDefinition.EnemyType:
	if wave <= 20:
		if roll < 0.25: return EnemyDefinition.EnemyType.BASIC
		if roll < 0.45: return EnemyDefinition.EnemyType.RUNNER
		if roll < 0.60: return EnemyDefinition.EnemyType.TANK
		if roll < 0.85: return EnemyDefinition.EnemyType.SWARM
		return EnemyDefinition.EnemyType.SHIELDED
	elif wave <= 30:
		if roll < 0.15: return EnemyDefinition.EnemyType.BASIC
		if roll < 0.35: return EnemyDefinition.EnemyType.RUNNER
		if roll < 0.55: return EnemyDefinition.EnemyType.TANK
		if roll < 0.80: return EnemyDefinition.EnemyType.SWARM
		return EnemyDefinition.EnemyType.SHIELDED
	else:
		if roll < 0.10: return EnemyDefinition.EnemyType.BASIC
		if roll < 0.30: return EnemyDefinition.EnemyType.RUNNER
		if roll < 0.55: return EnemyDefinition.EnemyType.TANK
		if roll < 0.75: return EnemyDefinition.EnemyType.SWARM
		return EnemyDefinition.EnemyType.SHIELDED

static func generate_boss_rush_round(round_num: int):
	var round_data = BossRushRoundData.get_round(round_num)
	var wave_def = load("res://scripts/wave_definition.gd").new()
	wave_def.wave_number = round_num
	wave_def.is_boss_wave = true

	var rng = RandomNumberGenerator.new()
	rng.seed = round_num * 8191

	# Boss spawns at 0.5s
	wave_def.spawns.append(WaveSpawnEntry.new(
		EnemyDefinition.EnemyType.BOSS,
		0.5,
		2,
		true,
		round_data.boss_hp_multiplier,
		round_data.boss_speed_multiplier,
		1.0,
		1.0
	))

	var support_list: Array[EnemyDefinition.EnemyType] = []
	for type in round_data.support_roster.keys():
		var count = round_data.support_roster[type]
		for i in range(count):
			support_list.append(type)

	if not support_list.is_empty():
		support_list.shuffle()
		var start_delay = 1.2
		var total_span = 6.0
		var step = total_span / float(support_list.size())
		for i in range(support_list.size()):
			var t = support_list[i]
			var lane = rng.randi_range(0, 7)
			wave_def.spawns.append(WaveSpawnEntry.new(
				t,
				start_delay + (float(i) * step),
				lane
			))

	return wave_def
