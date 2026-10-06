extends Resource
class_name UnitData

## Resource defining friendly unit combat attributes.

@export var unit_type: String = "rifleman"
@export var damage: float = 12.0
@export var attack_speed: float = 1.2
@export var range_radius: float = 7.5
@export var projectile_speed: float = 18.0
@export var critical_chance: float = 0.05
@export var critical_damage: float = 1.75
@export var target_priority: String = "closest_to_base"
