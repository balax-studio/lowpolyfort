class_name ChaosModifier
extends RefCounted

## Chaos Modifier specifications.
## Source of truth: Flutter lib/models/game_mode_data.dart (Clauses 304–314).

enum ChaosModifierType {
	NONE,
	RUSH_HOUR,
	TOUGH_CROWD,
	SWARM_WAVE,
	RICH_WAVE,
	RAPID_FIRE,
	GIANTS
}

var type: ChaosModifierType = ChaosModifierType.NONE
var title: String = ""
var subtitle: String = ""
var enemy_hp_multiplier: float = 1.0
var enemy_speed_multiplier: float = 1.0
var enemy_count_multiplier: float = 1.0
var enemy_coin_multiplier: float = 1.0
var unit_attack_speed_multiplier: float = 1.0
var enemy_scale_multiplier: float = 1.0

func _init(
	p_type: ChaosModifierType,
	p_title: String,
	p_subtitle: String,
	p_hp: float = 1.0,
	p_spd: float = 1.0,
	p_cnt: float = 1.0,
	p_coin: float = 1.0,
	p_unit_aspd: float = 1.0,
	p_scale: float = 1.0
) -> void:
	type = p_type
	title = p_title
	subtitle = p_subtitle
	enemy_hp_multiplier = p_hp
	enemy_speed_multiplier = p_spd
	enemy_count_multiplier = p_cnt
	enemy_coin_multiplier = p_coin
	unit_attack_speed_multiplier = p_unit_aspd
	enemy_scale_multiplier = p_scale

static var _none_mod: ChaosModifier = null
static var _rush_hour: ChaosModifier = null
static var _tough_crowd: ChaosModifier = null
static var _swarm_wave: ChaosModifier = null
static var _rich_wave: ChaosModifier = null
static var _rapid_fire: ChaosModifier = null
static var _giants: ChaosModifier = null

static func get_none() -> ChaosModifier:
	if _none_mod == null:
		_none_mod = ChaosModifier.new(ChaosModifierType.NONE, "NORMAL WAVE", "STANDARD RULES")
	return _none_mod

static func get_rush_hour() -> ChaosModifier:
	if _rush_hour == null:
		_rush_hour = ChaosModifier.new(ChaosModifierType.RUSH_HOUR, "RUSH HOUR", "ENEMIES +30% SPEED", 1.0, 1.30, 1.0, 1.15)
	return _rush_hour

static func get_tough_crowd() -> ChaosModifier:
	if _tough_crowd == null:
		_tough_crowd = ChaosModifier.new(ChaosModifierType.TOUGH_CROWD, "TOUGH CROWD", "ENEMIES +35% HP", 1.35, 1.0, 1.0, 1.20)
	return _tough_crowd

static func get_swarm_wave() -> ChaosModifier:
	if _swarm_wave == null:
		_swarm_wave = ChaosModifier.new(ChaosModifierType.SWARM_WAVE, "SWARM WAVE", "MORE ENEMIES • LESS HP", 0.80, 1.0, 1.50, 1.0)
	return _swarm_wave

static func get_rich_wave() -> ChaosModifier:
	if _rich_wave == null:
		_rich_wave = ChaosModifier.new(ChaosModifierType.RICH_WAVE, "RICH WAVE", "DOUBLE COINS", 1.25, 1.0, 1.0, 2.00)
	return _rich_wave

static func get_rapid_fire() -> ChaosModifier:
	if _rapid_fire == null:
		_rapid_fire = ChaosModifier.new(ChaosModifierType.RAPID_FIRE, "RAPID FIRE", "UNITS FIRE 50% FASTER", 1.0, 1.15, 1.0, 1.0, 1.50)
	return _rapid_fire

static func get_giants() -> ChaosModifier:
	if _giants == null:
		_giants = ChaosModifier.new(ChaosModifierType.GIANTS, "GIANTS", "FEWER • BIGGER • STRONGER", 2.00, 0.85, 0.65, 1.50, 1.0, 1.40)
	return _giants

static func get_active_pool() -> Array[ChaosModifier]:
	return [
		get_rush_hour(),
		get_tough_crowd(),
		get_swarm_wave(),
		get_rich_wave(),
		get_rapid_fire(),
		get_giants()
	]

static func resolve_for_wave(wave: int, previous_type: ChaosModifierType = ChaosModifierType.NONE, custom_seed: int = 0) -> ChaosModifier:
	if wave <= 1:
		return get_none()

	# Fixed sequence for waves 2–10 (Clause 312)
	match wave:
		2: return get_rush_hour()
		3: return get_rapid_fire()
		4: return get_swarm_wave()
		5: return get_tough_crowd()
		6: return get_rich_wave()
		7: return get_rush_hour()
		8: return get_giants()
		9: return get_rapid_fire()
		10: return get_rich_wave()
		_:
			# Wave 11+ seeded random avoiding immediate duplicate (Clause 313, 314)
			var rng = RandomNumberGenerator.new()
			var seed_val = custom_seed if custom_seed != 0 else (wave * 7919)
			rng.seed = seed_val
			var pool = get_active_pool()
			var eligible: Array[ChaosModifier] = []
			for m in pool:
				if m.type != previous_type:
					eligible.append(m)
			if eligible.is_empty():
				eligible = pool
			var idx = rng.randi_range(0, eligible.size() - 1)
			return eligible[idx]
