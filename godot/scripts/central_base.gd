extends Node3D

## Central Command Bunker situated at (0, 0, 0) defended against invading hordes.
## Features ambient rotating radar dish, cyan status lights, and damage flash reaction.

@onready var model_root: Node3D = $ModelRoot
@onready var radar_dish: Node3D = $ModelRoot.get_node_or_null("RadarDish")
@onready var beacon_light: MeshInstance3D = $ModelRoot.get_node_or_null("BeaconLight")
@onready var hull_mesh: MeshInstance3D = $ModelRoot.get_node_or_null("HullMesh")

var _damage_flash_timer: float = 0.0
var _shake_timer: float = 0.0
var _original_hull_material: StandardMaterial3D = null
var _flash_material: StandardMaterial3D = null

func _ready() -> void:
	GameManager.base_ref = self
	
	# Cache materials for hit flash
	if hull_mesh and hull_mesh.get_active_material(0):
		_original_hull_material = hull_mesh.get_active_material(0)
	
	_flash_material = StandardMaterial3D.new()
	_flash_material.albedo_color = Color(0.95, 0.2, 0.2)
	_flash_material.roughness = 0.4

func _process(delta: float) -> void:
	# Ambient radar dish rotation (Clause 11, 41)
	if radar_dish:
		radar_dish.rotate_y(delta * 1.5)

	# Localized damage flash decay
	if _damage_flash_timer > 0.0:
		_damage_flash_timer -= delta
		if _damage_flash_timer <= 0.0 and hull_mesh and _original_hull_material:
			hull_mesh.set_surface_override_material(0, null)

	# Localized base damage shake
	if _shake_timer > 0.0:
		_shake_timer -= delta
		var offset_x = sin(_shake_timer * 50.0) * 0.08
		var offset_z = cos(_shake_timer * 50.0) * 0.05
		model_root.position = Vector3(offset_x, 0.0, offset_z)
	else:
		model_root.position = Vector3.ZERO

func trigger_damage_flash() -> void:
	_damage_flash_timer = 0.12
	_shake_timer = 0.15
	if hull_mesh and _flash_material:
		hull_mesh.set_surface_override_material(0, _flash_material)

func trigger_destruction() -> void:
	_damage_flash_timer = 0.4
	_shake_timer = 0.5
	var tween = create_tween()
	tween.tween_property(model_root, "scale", Vector3(1.1, 0.7, 1.1), 0.2)
	tween.tween_property(model_root, "scale", Vector3(0.9, 0.3, 0.9), 0.3)
