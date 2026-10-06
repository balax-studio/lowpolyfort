extends Node3D

## Generic Tactical Defender Unit.
## Configured via UnitData resource, automatically scans for threats nearest to Base,
## aims weapon, and fires projectiles with recoil animation.

@export var data: Resource = null
@export var level: int = 1
@export var hero_class: HeroDefinition.HeroClass = HeroDefinition.HeroClass.RIFLEMAN
var hero_def: HeroDefinition = null

var current_slot: Node3D = null
var current_target: Node3D = null

var _target_scan_timer: float = 0.0
var _attack_timer: float = 0.0
var _uniform_mat: StandardMaterial3D = null
var is_dragging: bool = false

@onready var model_root: Node3D = $ModelRoot
@onready var torso_mesh: MeshInstance3D = $ModelRoot/TorsoMesh
@onready var helmet_mesh: MeshInstance3D = $ModelRoot/HelmetMesh
@onready var weapon_pivot: Node3D = $ModelRoot/WeaponPivot if has_node("ModelRoot/WeaponPivot") else $WeaponPivot
@onready var weapon_mesh: MeshInstance3D = weapon_pivot.get_node("WeaponMesh") if weapon_pivot and weapon_pivot.has_node("WeaponMesh") else null
@onready var muzzle_point: Marker3D = weapon_pivot.get_node("MuzzlePoint") if weapon_pivot and weapon_pivot.has_node("MuzzlePoint") else null
@onready var level_label: Label3D = $LevelLabel
@onready var selection_ring: MeshInstance3D = $SelectionRing

var projectile_scene: PackedScene = preload("res://scenes/combat/projectile.tscn")

func _ready() -> void:
	add_to_group("units")
	if hero_def == null:
		set_hero_class(hero_class)
	
	update_level(level)

func set_hero_class(h_class: HeroDefinition.HeroClass) -> void:
	hero_class = h_class
	hero_def = HeroDefinition.get_def(h_class)
	
	# Apply distinct visual uniform tint matching Flutter GameColors
	if torso_mesh:
		if _uniform_mat == null:
			_uniform_mat = StandardMaterial3D.new()
			_uniform_mat.roughness = 0.6
		_uniform_mat.albedo_color = hero_def.theme_color
		torso_mesh.set_surface_override_material(0, _uniform_mat)
	if helmet_mesh:
		var helmet_mat = StandardMaterial3D.new()
		helmet_mat.albedo_color = hero_def.theme_color.darkened(0.2)
		helmet_mesh.set_surface_override_material(0, helmet_mat)
	
	# Adapt weapon visual silhouette
	if weapon_mesh:
		match hero_class:
			HeroDefinition.HeroClass.RIFLEMAN:
				weapon_mesh.scale = Vector3(1.0, 1.0, 1.0)
			HeroDefinition.HeroClass.SHOTGUNNER:
				weapon_mesh.scale = Vector3(1.4, 1.1, 0.85) # Wide, short barrel
			HeroDefinition.HeroClass.SNIPER:
				weapon_mesh.scale = Vector3(0.8, 0.8, 1.6)  # Extra long, slim barrel
			HeroDefinition.HeroClass.HEAVY_GUNNER:
				weapon_mesh.scale = Vector3(1.3, 1.3, 1.1)  # Chunky, heavy barrel

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
	var base_dmg = hero_def.get_damage_at_level(level) if hero_def else (data.damage if data else 12.0)
	var upg_mult = 1.0 + GameManager.upgrade_damage_bonus
	return base_dmg * upg_mult

func get_attack_speed() -> float:
	var base_spd = hero_def.get_attack_speed_at_level(level) if hero_def else (data.attack_speed if data else 1.2)
	var upg_mult = 1.0 + GameManager.upgrade_aspd_bonus
	var chaos_mult = 1.0
	if GameManager.current_mode == GameManager.GameMode.CHAOS and GameManager.active_chaos_modifier != null:
		chaos_mult = GameManager.active_chaos_modifier.unit_attack_speed_multiplier
	return base_spd * upg_mult * chaos_mult

func get_range() -> float:
	var base_rng = hero_def.get_range_at_level(level) if hero_def else (data.range_radius if data else 7.5)
	var upg_mult = 1.0 + GameManager.upgrade_range_bonus
	return base_rng * upg_mult

func _process(delta: float) -> void:
	if is_dragging or GameManager.state == GameManager.GameState.GAME_OVER:
		return

	# Attack cooldown
	if _attack_timer > 0.0:
		_attack_timer -= delta

	# Periodic target scan every 0.16s (Clause 24, 78)
	_target_scan_timer -= delta
	if _target_scan_timer <= 0.0:
		_target_scan_timer = GameBalance.TARGET_SCAN_INTERVAL
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
	if target != null:
		var target_pos = Vector3(target.global_position.x, global_position.y, target.global_position.z)
		if model_root:
			var target_rot_y = atan2(target_pos.x - global_position.x, target_pos.z - global_position.z) + PI
			model_root.rotation.y = lerp_angle(model_root.rotation.y, target_rot_y, min(1.0, delta * 12.0))
		if weapon_pivot:
			var aim_target = target.global_position + Vector3(0, 0.45, 0)
			var current_transform = weapon_pivot.global_transform
			weapon_pivot.look_at(aim_target, Vector3.UP)
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
	
	var base_crit = hero_def.crit_chance if hero_def else (data.critical_chance if data else 0.05)
	var crit_chance = minf(base_crit + GameManager.upgrade_crit_bonus, GameBalance.MAX_CRIT_CHANCE_CAP)
	var is_crit = randf() < crit_chance
	var crit_mult = (hero_def.crit_multiplier if hero_def else (data.critical_damage if data else 1.75)) if is_crit else 1.0
	var final_damage = get_damage() * crit_mult
	
	# Armor Piercing Roguelite perk (+20% vs Tank and Shielded)
	if target.has_method("is_tank_or_shielded") and target.is_tank_or_shielded():
		if GameManager.has_method("has_armor_piercing") and GameManager.has_armor_piercing():
			final_damage *= 1.20
	
	var proj_speed = hero_def.projectile_speed if hero_def else (data.projectile_speed if data else 18.0)
	var p_count = hero_def.projectile_count if hero_def else 1

	if p_count > 1 and hero_def != null:
		# Shotgunner 5-pellet spread
		var half_spread = hero_def.spread_angle * 0.5
		var angle_step = hero_def.spread_angle / float(p_count - 1)
		for i in range(p_count):
			var pellet = projectile_scene.instantiate()
			proj_container.add_child(pellet)
			pellet.global_position = muzzle_point.global_position
			var offset_angle = -half_spread + (float(i) * angle_step)
			pellet.setup(target, final_damage, proj_speed, is_crit)
			pellet.direction = pellet.direction.rotated(Vector3.UP, offset_angle)
	else:
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
