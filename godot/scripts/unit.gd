extends Node3D

## Generic Tactical Defender Unit.
## Configured via UnitData resource, automatically scans for threats nearest to Base,
## aims weapon, and fires projectiles with recoil animation.

@export var data: Resource = null
@export var level: int = 1

var current_slot: Node3D = null
var current_target: Node3D = null

var _target_scan_timer: float = 0.0
var _attack_timer: float = 0.0
var is_dragging: bool = false

@onready var model_root: Node3D = $ModelRoot
@onready var weapon_pivot: Node3D = $WeaponPivot
@onready var weapon_mesh: MeshInstance3D = $WeaponPivot/WeaponMesh
@onready var muzzle_point: Marker3D = $WeaponPivot/MuzzlePoint
@onready var level_label: Label3D = $LevelLabel
@onready var selection_ring: MeshInstance3D = $SelectionRing

var projectile_scene: PackedScene = preload("res://scenes/combat/projectile.tscn")

func _ready() -> void:
	add_to_group("units")
	if data == null:
		data = load("res://resources/rifleman_data.tres")
	
	update_level(level)

func update_level(new_level: int) -> void:
	level = clamp(new_level, 1, 8)
	if level_label:
		level_label.text = "Lv.%d" % level
		# Subtle color tint based on level tier
		if level >= 4:
			level_label.modulate = Color(1.0, 0.85, 0.2) # Gold
		elif level >= 2:
			level_label.modulate = Color(0.4, 0.9, 1.0) # Cyan
		else:
			level_label.modulate = Color.WHITE

func get_damage() -> float:
	var base_dmg = data.damage if data else 12.0
	# Merge power curve: 1.5x per level
	return base_dmg * pow(1.5, float(level - 1))

func get_attack_speed() -> float:
	return data.attack_speed if data else 1.2

func get_range() -> float:
	return data.range_radius if data else 7.5

func _process(delta: float) -> void:
	if is_dragging or GameManager.state == GameManager.GameState.GAME_OVER:
		return

	# Attack cooldown
	if _attack_timer > 0.0:
		_attack_timer -= delta

	# Periodic target scan every 0.15s (Clause 24, 78)
	_target_scan_timer -= delta
	if _target_scan_timer <= 0.0:
		_target_scan_timer = 0.15
		_scan_for_target()

	# Aim and attack if target is valid
	if _is_target_valid(current_target):
		_aim_at_target(current_target, delta)
		if _attack_timer <= 0.0:
			_attack_timer = 1.0 / get_attack_speed()
			_shoot(current_target)
	else:
		current_target = null

func _scan_for_target() -> void:
	# Keep current target if still valid and within range
	if _is_target_valid(current_target):
		return

	var enemies = get_tree().get_nodes_in_group("enemies")
	var best_target: Node3D = null
	var min_base_dist: float = 99999.0
	var my_pos = global_position
	var max_range_sq = pow(get_range(), 2)

	for enemy in enemies:
		if not is_instance_valid(enemy) or not ("is_dead" in enemy) or enemy.is_dead:
			continue
		
		var dist_to_unit_sq = my_pos.distance_squared_to(enemy.global_position)
		if dist_to_unit_sq <= max_range_sq:
			# Prioritize enemy closest to Central Base (Clause 77)
			var dist_to_base = enemy.global_position.distance_to(Vector3.ZERO)
			if dist_to_base < min_base_dist:
				min_base_dist = dist_to_base
				best_target = enemy

	current_target = best_target

func _is_target_valid(target: Node3D) -> bool:
	if target == null or not is_instance_valid(target) or not ("is_dead" in target):
		return false
	if target.is_dead:
		return false
	return global_position.distance_to(target.global_position) <= get_range()

func _aim_at_target(target: Node3D, delta: float) -> void:
	if weapon_pivot and target != null:
		var target_pos = target.global_position + Vector3(0, 0.45, 0)
		var current_transform = weapon_pivot.global_transform
		weapon_pivot.look_at(target_pos, Vector3.UP)
		# Smooth aim blend
		weapon_pivot.global_transform = current_transform.interpolate_with(weapon_pivot.global_transform, min(1.0, delta * 15.0))

func _shoot(target: Node3D) -> void:
	if projectile_scene == null:
		return

	var proj = projectile_scene.instantiate()
	var proj_container = get_tree().get_first_node_in_group("projectiles_container")
	if proj_container == null:
		proj_container = get_parent()
	
	proj_container.add_child(proj)
	proj.global_position = muzzle_point.global_position
	
	var is_crit = randf() < (data.critical_chance if data else 0.05)
	var crit_mult = (data.critical_damage if data else 1.75) if is_crit else 1.0
	var final_damage = get_damage() * crit_mult
	var proj_speed = data.projectile_speed if data else 18.0
	
	proj.setup(target, final_damage, proj_speed, is_crit)

	# Weapon recoil punch (Clause 25, 85)
	if weapon_mesh:
		var recoil_tween = create_tween()
		recoil_tween.tween_property(weapon_mesh, "position:z", 0.12, 0.04)
		recoil_tween.tween_property(weapon_mesh, "position:z", 0.0, 0.07)

func play_spawn_effect() -> void:
	# Clause 17: scale 0.7 -> 1.1 -> 1.0
	scale = Vector3(0.7, 0.7, 0.7)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(1.12, 1.12, 1.12), 0.12)
	tween.tween_property(self, "scale", Vector3(1.0, 1.0, 1.0), 0.08)

func play_merge_effect() -> void:
	# Clause 46: scale 0.8 -> 1.25 -> 1.0 with punch
	scale = Vector3(0.8, 0.8, 0.8)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(1.25, 1.25, 1.25), 0.12)
	tween.tween_property(self, "scale", Vector3(1.0, 1.0, 1.0), 0.10)

func set_dragging(dragging: bool) -> void:
	is_dragging = dragging
	if selection_ring:
		selection_ring.visible = dragging
	if dragging:
		position.y += 0.4
		scale = Vector3(1.08, 1.08, 1.08)
	else:
		scale = Vector3.ONE
