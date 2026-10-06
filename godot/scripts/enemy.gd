extends Node3D

## Enemy unit marching toward Central Base (0, 0, 0).
## Deals damage to the Base on contact, rewards coins on death.

signal died(enemy: Node3D)

@export var data: Resource = null

var hp: float = 55.0
var max_hp: float = 55.0
var speed: float = 1.6
var damage: float = 15.0
var attack_interval: float = 1.2
var coin_reward: int = 5
var is_dead: bool = false

var _attack_timer: float = 0.0
var _flash_timer: float = 0.0
var _stop_distance: float = 1.45

@onready var model_root: Node3D = $ModelRoot
@onready var body_mesh: MeshInstance3D = $ModelRoot/BodyMesh
@onready var hp_fill: MeshInstance3D = $HealthBar/BarFill

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

	hp -= amount
	_flash_timer = 0.08
	if body_mesh and _hit_flash_mat:
		body_mesh.set_surface_override_material(0, _hit_flash_mat)

	_update_hp_bar()

	if hp <= 0.0:
		_die()

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
	
	# Award coins once (Clause 33)
	GameManager.add_coins(coin_reward)

	# Visual death shrink & pop (Clause 33)
	var tween = create_tween()
	tween.tween_property(model_root, "scale", Vector3(1.2, 1.2, 1.2), 0.06)
	tween.tween_property(model_root, "scale", Vector3(0.01, 0.01, 0.01), 0.12)
	tween.tween_callback(queue_free)
