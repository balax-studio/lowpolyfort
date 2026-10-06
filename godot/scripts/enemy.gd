extends Node3D

## Enemy unit marching toward Central Base (0, 0, 0).
## Deals damage to the Base on contact, rewards coins on death.

signal died(enemy: Node3D)

@export var data: Resource = null

var hp: float = 55.0
var max_hp: float = 55.0
var shield: float = 0.0
var max_shield: float = 0.0
var speed: float = 1.6
var base_move_speed: float = 1.6
var damage: float = 15.0
var attack_interval: float = 1.2
var coin_reward: int = 5
var is_dead: bool = false
var enemy_type_name: String = "basic"

# Boss charge mechanics (Clause 75)
var charge_speed: float = 0.0
var charge_duration: float = 0.0
var charge_cooldown: float = 0.0
var _charge_timer: float = 0.0
var _charge_active_timer: float = 0.0

var _attack_timer: float = 0.0
var _flash_timer: float = 0.0
var _stop_distance: float = 1.45

@onready var model_root: Node3D = $ModelRoot
@onready var body_mesh: MeshInstance3D = $ModelRoot/BodyMesh
@onready var head_mesh: MeshInstance3D = $ModelRoot/HeadMesh
@onready var hp_fill: MeshInstance3D = $HealthBar/BarFill

func is_tank_or_shielded() -> bool:
	return enemy_type_name == "tank" or enemy_type_name == "shielded" or shield > 0.0

func setup_from_definition(
	enemy_def: EnemyDefinition,
	wave: int = 1,
	hp_mult: float = 1.0,
	spd_mult: float = 1.0,
	coin_mult: float = 1.0,
	scale_mult: float = 1.0
) -> void:
	max_hp = enemy_def.get_scaled_hp(wave) * hp_mult
	hp = max_hp
	max_shield = enemy_def.get_scaled_shield(wave) * hp_mult
	shield = max_shield
	base_move_speed = enemy_def.get_scaled_speed(wave) * spd_mult
	speed = base_move_speed
	damage = enemy_def.get_scaled_damage(wave)
	coin_reward = int(round(float(enemy_def.base_coin_reward) * coin_mult))
	attack_interval = enemy_def.attack_interval
	charge_speed = enemy_def.charge_speed
	charge_duration = enemy_def.charge_duration
	charge_cooldown = enemy_def.charge_cooldown
	_charge_timer = charge_cooldown
	enemy_type_name = EnemyDefinition.EnemyType.keys()[enemy_def.type].to_lower()

	# Visual scale
	var base_scale = (enemy_def.radius / 0.4) * scale_mult
	scale = Vector3.ONE * base_scale

	# Tint body and head mesh with completely matte low-poly material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = enemy_def.base_color
	mat.metallic = 0.0
	mat.roughness = 1.0
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mat.metallic_specular = 0.0
	if body_mesh:
		body_mesh.set_surface_override_material(0, mat)
	if head_mesh:
		head_mesh.set_surface_override_material(0, mat)

	_update_hp_bar()

var _original_body_mat: StandardMaterial3D = null
var _hit_flash_mat: StandardMaterial3D = null

func _ready() -> void:
	add_to_group("enemies")
	
	if data == null:
		data = load("res://resources/basic_enemy_data.tres")
	
	if data:
		hp = data.hp
		max_hp = data.hp
		speed = data.speed
		damage = data.damage
		attack_interval = data.attack_interval
		coin_reward = data.coin_reward

	if body_mesh and body_mesh.get_active_material(0):
		_original_body_mat = body_mesh.get_active_material(0)
	
	_hit_flash_mat = StandardMaterial3D.new()
	_hit_flash_mat.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	_hit_flash_mat.emission_enabled = true
	_hit_flash_mat.emission = Color(1.0, 1.0, 1.0, 1.0)
	_hit_flash_mat.emission_energy_multiplier = 2.5

	_update_hp_bar()

func _process(delta: float) -> void:
	if is_dead:
		return

	# Hit flash decay
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0 and body_mesh and _original_body_mat:
			body_mesh.set_surface_override_material(0, null)

	# Boss charge logic (Clause 75)
	if charge_cooldown > 0.0:
		if _charge_active_timer > 0.0:
			_charge_active_timer -= delta
			speed = charge_speed
			if _charge_active_timer <= 0.0:
				speed = base_move_speed
				_charge_timer = charge_cooldown
		else:
			_charge_timer -= delta
			if _charge_timer <= 0.0:
				_charge_active_timer = charge_duration
				speed = charge_speed

	# Calculate distance to Central Base (0, 0, 0)
	var base_target = Vector3(0.0, global_position.y, 0.0)
	var to_base = base_target - global_position
	var dist_to_base = to_base.length()

	if dist_to_base > _stop_distance:
		# Straight march to Base (Clause 9, 31)
		var direction = to_base.normalized()
		global_position += direction * speed * delta
		look_at(base_target, Vector3.UP)
		
		# Gentle walking bob animation (Clause 68)
		model_root.position.y = abs(sin(Time.get_ticks_msec() * 0.008 * speed)) * 0.12
	else:
		# At base perimeter: attack Base (Clause 31, 32)
		model_root.position.y = 0.0
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_attack_timer = attack_interval
			_perform_base_attack()

func _perform_base_attack() -> void:
	# Small body punch movement towards base
	var punch_tween = create_tween()
	punch_tween.tween_property(model_root, "position:z", -0.25, 0.1)
	punch_tween.tween_property(model_root, "position:z", 0.0, 0.15)
	GameManager.damage_base(damage)

func take_damage(amount: float, is_crit: bool = false) -> void:
	if is_dead:
		return

	# Shield absorption
	var remaining_damage = amount
	if shield > 0.0:
		if shield >= remaining_damage:
			shield -= remaining_damage
			remaining_damage = 0.0
		else:
			remaining_damage -= shield
			shield = 0.0

	hp -= remaining_damage
	_flash_timer = GameBalance.BASE_DAMAGE_FLASH_DURATION
	if body_mesh and _hit_flash_mat:
		body_mesh.set_surface_override_material(0, _hit_flash_mat)

	if SaveManager.show_damage_numbers:
		_spawn_floating_damage(amount, is_crit)

	_update_hp_bar()

	if hp <= 0.0:
		_die()

func _spawn_floating_damage(amount: float, is_crit: bool) -> void:
	var label = Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.text = ("%d!" % int(amount)) if is_crit else str(int(amount))
	label.font_size = 28 if is_crit else 22
	label.modulate = Color(1.0, 0.85, 0.15) if is_crit else Color(1.0, 0.95, 0.95)
	label.outline_modulate = Color(0.05, 0.05, 0.05, 1.0)
	label.outline_size = 6
	get_parent().add_child(label)
	label.global_position = global_position + Vector3(randf_range(-0.15, 0.15), 0.75, randf_range(-0.15, 0.15))

	var tween = label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y + 0.65, GameBalance.FLOATING_TEXT_DURATION_SECONDS)
	tween.tween_property(label, "modulate:a", 0.0, GameBalance.FLOATING_TEXT_DURATION_SECONDS).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(label.queue_free)

func _update_hp_bar() -> void:
	if hp_fill:
		var ratio = clamp(hp / max_hp, 0.0, 1.0)
		hp_fill.scale.x = ratio
		hp_fill.position.x = (ratio - 1.0) * 0.35

func _die() -> void:
	if is_dead:
		return
	is_dead = true
	remove_from_group("enemies")
	died.emit(self)
	
	# Award coins & track kills via GameManager
	if enemy_type_name == "boss":
		GameManager.on_boss_defeated(coin_reward)
	else:
		GameManager.on_enemy_killed(coin_reward)

	# Visual death shrink & pop (Clause 33)
	var tween = create_tween()
	tween.tween_property(model_root, "scale", Vector3(1.2, 1.2, 1.2), 0.06)
	tween.tween_property(model_root, "scale", Vector3(0.01, 0.01, 0.01), 0.12)
	tween.tween_callback(queue_free)
