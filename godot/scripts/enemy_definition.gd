class_name EnemyDefinition
extends Resource

## Data definition for Enemy types.
## Source of truth: Flutter lib/models/enemy_data.dart (Clauses 70, 75).

enum EnemyType {
	BASIC,
	RUNNER,
	TANK,
	SWARM,
	SHIELDED,
	BOSS
}

@export var type: EnemyType = EnemyType.BASIC
@export var name: String = "Mutant Raider"
@export var base_color: Color = Color(0.8, 0.2, 0.2)
@export var base_hp: float = 55.0
@export var base_speed: float = 1.6
@export var base_damage: float = 15.0
@export var attack_interval: float = 1.0
@export var base_coin_reward: int = 5
@export var radius: float = 0.4
@export var base_shield: float = 0.0

# Boss specific charge attributes (Clause 75)
@export var charge_speed: float = 0.0
@export var charge_duration: float = 0.0
@export var charge_cooldown: float = 0.0

static var _registry: Dictionary = {}

static func get_registry() -> Dictionary:
	if _registry.is_empty():
		_registry = _create_registry()
	return _registry

static func get_definition(p_type: EnemyType) -> EnemyDefinition:
	return get_registry().get(p_type, null)

static func _create_registry() -> Dictionary:
	var dict = {}

	# Basic: Mutant Raider
	var basic = EnemyDefinition.new()
	basic.type = EnemyType.BASIC
	basic.name = "Mutant Raider"
	basic.base_color = Color(0.82, 0.24, 0.24)
	basic.base_hp = 55.0
	basic.base_speed = 1.6
	basic.base_damage = 15.0
	basic.attack_interval = 1.0
	basic.base_coin_reward = 5
	basic.radius = 0.4
	dict[EnemyType.BASIC] = basic

	# Runner: Scout Sprinter
	var runner = EnemyDefinition.new()
	runner.type = EnemyType.RUNNER
	runner.name = "Scout Sprinter"
	runner.base_color = Color(0.95, 0.75, 0.15)
	runner.base_hp = 34.0
	runner.base_speed = 2.62
	runner.base_damage = 10.0
	runner.attack_interval = 0.8
	runner.base_coin_reward = 4
	runner.radius = 0.32
	dict[EnemyType.RUNNER] = runner

	# Tank: Iron Goliath
	var tank = EnemyDefinition.new()
	tank.type = EnemyType.TANK
	tank.name = "Iron Goliath"
	tank.base_color = Color(0.40, 0.40, 0.48)
	tank.base_hp = 210.0
	tank.base_speed = 0.93
	tank.base_damage = 35.0
	tank.attack_interval = 1.4
	tank.base_coin_reward = 15
	tank.radius = 0.60
	dict[EnemyType.TANK] = tank

	# Swarm: Swarm Crawler
	var swarm = EnemyDefinition.new()
	swarm.type = EnemyType.SWARM
	swarm.name = "Swarm Crawler"
	swarm.base_color = Color(0.70, 0.30, 0.85)
	swarm.base_hp = 22.0
	swarm.base_speed = 2.10
	swarm.base_damage = 6.0
	swarm.attack_interval = 0.7
	swarm.base_coin_reward = 2
	swarm.radius = 0.25
	dict[EnemyType.SWARM] = swarm

	# Shielded: Barrier Warden
	var shielded = EnemyDefinition.new()
	shielded.type = EnemyType.SHIELDED
	shielded.name = "Barrier Warden"
	shielded.base_color = Color(0.20, 0.65, 0.85)
	shielded.base_hp = 120.0
	shielded.base_shield = 80.0
	shielded.base_speed = 1.25
	shielded.base_damage = 22.0
	shielded.attack_interval = 1.1
	shielded.base_coin_reward = 12
	shielded.radius = 0.45
	dict[EnemyType.SHIELDED] = shielded

	# Boss: Brute Warlord
	var boss = EnemyDefinition.new()
	boss.type = EnemyType.BOSS
	boss.name = "Brute Warlord"
	boss.base_color = Color(0.90, 0.15, 0.15)
	boss.base_hp = 1200.0
	boss.base_speed = 0.70
	boss.charge_speed = 1.60
	boss.charge_duration = 1.2
	boss.charge_cooldown = 7.0
	boss.base_damage = 65.0
	boss.attack_interval = 1.8
	boss.base_coin_reward = 100
	boss.radius = 0.90
	dict[EnemyType.BOSS] = boss

	return dict

static func get_def(enemy_type: EnemyType) -> EnemyDefinition:
	var reg = get_registry()
	return reg.get(enemy_type, reg[EnemyType.BASIC])

func get_scaled_hp(wave: int) -> float:
	return round(base_hp * GameBalance.get_wave_enemy_hp_multiplier(wave))

func get_scaled_speed(wave: int) -> float:
	return base_speed * GameBalance.get_wave_enemy_speed_multiplier(wave)

func get_scaled_shield(wave: int) -> float:
	if base_shield <= 0.0:
		return 0.0
	return round(base_shield * GameBalance.get_wave_enemy_hp_multiplier(wave))

func get_scaled_damage(wave: int) -> float:
	return round(base_damage * GameBalance.get_wave_enemy_damage_multiplier(wave))
