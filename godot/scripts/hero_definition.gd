class_name HeroDefinition
extends Resource

## Data definition for Hero classes.
## Source of truth: Flutter lib/models/hero_data.dart (Clauses 61–64, 115).

enum HeroClass {
	RIFLEMAN,
	SHOTGUNNER,
	SNIPER,
	HEAVY_GUNNER
}

enum TargetPriority {
	FIRST,
	CLOSEST,
	STRONGEST,
	LOWEST_HP,
	BOSS_FIRST
}

@export var hero_class: HeroClass = HeroClass.RIFLEMAN
@export var name: String = "Rifleman"
@export var role_description: String = ""
@export var theme_color: Color = Color(0.2, 0.7, 0.4)
@export var base_damage: float = 12.0
@export var attacks_per_second: float = 1.2
@export var range_meters: float = 7.5
@export var projectile_speed: float = 18.0
@export var crit_chance: float = 0.05
@export var crit_multiplier: float = 1.75
@export var default_priority: TargetPriority = TargetPriority.FIRST
@export var projectile_count: int = 1
@export var spread_angle: float = 0.0
@export var unlock_wave_requirement: int = 1

static var _registry: Dictionary = {}

static func get_registry() -> Dictionary:
	if _registry.is_empty():
		_registry = _create_registry()
	return _registry

static func _create_registry() -> Dictionary:
	var dict = {}
	
	# Rifleman (W1)
	var rm = HeroDefinition.new()
	rm.hero_class = HeroClass.RIFLEMAN
	rm.name = "Rifleman"
	rm.role_description = "Versatile frontline combatant with balanced range and fire rate."
	rm.theme_color = Color(0.14, 0.46, 0.92) # Tactical Blue uniform (Image A & B Master Reference)
	rm.base_damage = 12.0
	rm.attacks_per_second = 1.2
	rm.range_meters = 7.5
	rm.projectile_speed = 18.0
	rm.crit_chance = 0.05
	rm.crit_multiplier = 1.75
	rm.default_priority = TargetPriority.FIRST
	rm.projectile_count = 1
	rm.spread_angle = 0.0
	rm.unlock_wave_requirement = GameBalance.UNLOCK_WAVE_RIFLEMAN
	dict[HeroClass.RIFLEMAN] = rm

	# Shotgunner (W5)
	var sg = HeroDefinition.new()
	sg.hero_class = HeroClass.SHOTGUNNER
	sg.name = "Shotgunner"
	sg.role_description = "Devastating close-range blast firing 5 spread pellets."
	sg.theme_color = Color(0.85, 0.45, 0.15) # Orange uniform
	sg.base_damage = 9.0
	sg.attacks_per_second = 0.65
	sg.range_meters = 4.2
	sg.projectile_speed = 15.0
	sg.crit_chance = 0.03
	sg.crit_multiplier = 1.5
	sg.default_priority = TargetPriority.CLOSEST
	sg.projectile_count = 5
	sg.spread_angle = 0.38
	sg.unlock_wave_requirement = GameBalance.UNLOCK_WAVE_SHOTGUNNER
	dict[HeroClass.SHOTGUNNER] = sg

	# Sniper (W10)
	var sn = HeroDefinition.new()
	sn.hero_class = HeroClass.SNIPER
	sn.name = "Sniper"
	sn.role_description = "Extreme range anti-armor marksman targeting strongest threats."
	sn.theme_color = Color(0.25, 0.45, 0.85) # Blue uniform
	sn.base_damage = 55.0
	sn.attacks_per_second = 0.45
	sn.range_meters = 14.0
	sn.projectile_speed = 30.0
	sn.crit_chance = 0.12
	sn.crit_multiplier = 2.0
	sn.default_priority = TargetPriority.STRONGEST
	sn.projectile_count = 1
	sn.spread_angle = 0.0
	sn.unlock_wave_requirement = GameBalance.UNLOCK_WAVE_SNIPER
	dict[HeroClass.SNIPER] = sn

	# Heavy Gunner (W15)
	var hg = HeroDefinition.new()
	hg.hero_class = HeroClass.HEAVY_GUNNER
	hg.name = "Heavy Gunner"
	hg.role_description = "Continuous suppression fire decimating advancing hordes."
	hg.theme_color = Color(0.75, 0.20, 0.20) # Red uniform
	hg.base_damage = 6.0
	hg.attacks_per_second = 3.0
	hg.range_meters = 6.8
	hg.projectile_speed = 20.0
	hg.crit_chance = 0.04
	hg.crit_multiplier = 1.5
	hg.default_priority = TargetPriority.FIRST
	hg.projectile_count = 1
	hg.spread_angle = 0.0
	hg.unlock_wave_requirement = GameBalance.UNLOCK_WAVE_HEAVY_GUNNER
	dict[HeroClass.HEAVY_GUNNER] = hg

	return dict

static func get_def(hero_class_type: HeroClass) -> HeroDefinition:
	var reg = get_registry()
	return reg.get(hero_class_type, reg[HeroClass.RIFLEMAN])

static func get_definition(hero_class_type: HeroClass) -> HeroDefinition:
	return get_def(hero_class_type)

static func roll_unit_with_rng(rng: RandomNumberGenerator, unlocked: Array[HeroClass]) -> HeroClass:
	if unlocked.is_empty():
		return HeroClass.RIFLEMAN
	if unlocked.size() == 1:
		return unlocked[0]

	var roll = rng.randf()
	if unlocked.size() == 2:
		# Clause 614: Rifleman 60%, Shotgunner 40%
		return HeroClass.RIFLEMAN if roll < 0.60 else HeroClass.SHOTGUNNER
	elif unlocked.size() == 3:
		# Clause 614: Rifleman 45%, Shotgunner 30%, Sniper 25%
		if roll < 0.45: return HeroClass.RIFLEMAN
		if roll < 0.75: return HeroClass.SHOTGUNNER
		return HeroClass.SNIPER
	else:
		# Clause 614: Rifleman 40%, Shotgunner 25%, Heavy Gunner 20%, Sniper 15%
		if roll < 0.40: return HeroClass.RIFLEMAN
		if roll < 0.65: return HeroClass.SHOTGUNNER
		if roll < 0.85: return HeroClass.HEAVY_GUNNER
		return HeroClass.SNIPER

func get_damage_at_level(level: int) -> float:
	return base_damage * GameBalance.get_hero_damage_multiplier(level)

func get_attack_speed_at_level(level: int) -> float:
	return attacks_per_second * GameBalance.get_hero_attack_speed_multiplier(level)

func get_range_at_level(level: int) -> float:
	return range_meters * GameBalance.get_hero_range_multiplier(level)
