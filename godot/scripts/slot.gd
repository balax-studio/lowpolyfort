extends Node3D

## Slot representing one of the 8 tactical pads surrounding the Central Base.
## Contains slot_index, occupied status, unit reference, and 3D visual highlights.

signal slot_clicked(slot: Node3D)

@export var slot_index: int = 0
var occupied: bool = false
var unit_reference: Node = null

@onready var platform_mesh: MeshInstance3D = $ModelRoot/PlatformMesh
@onready var accent_mesh: MeshInstance3D = $ModelRoot/AccentRing
@onready var area3d: Area3D = $Area3D

var _mat_normal: StandardMaterial3D = null
var _mat_highlight_valid: StandardMaterial3D = null
var _mat_highlight_invalid: StandardMaterial3D = null

func _ready() -> void:
	add_to_group("slots")
	
	# Create materials for drag state highlighting
	_mat_normal = StandardMaterial3D.new()
	_mat_normal.albedo_color = Color(0.12, 0.55, 0.85, 1.0)
	_mat_normal.emission_enabled = true
	_mat_normal.emission = Color(0.1, 0.4, 0.8, 1.0)
	_mat_normal.emission_energy_multiplier = 0.8
	
	_mat_highlight_valid = StandardMaterial3D.new()
	_mat_highlight_valid.albedo_color = Color(0.4, 0.95, 0.2, 1.0)
	_mat_highlight_valid.emission_enabled = true
	_mat_highlight_valid.emission = Color(0.4, 0.95, 0.2, 1.0)
	_mat_highlight_valid.emission_energy_multiplier = 2.0
	
	_mat_highlight_invalid = StandardMaterial3D.new()
	_mat_highlight_invalid.albedo_color = Color(0.95, 0.2, 0.2, 1.0)
	_mat_highlight_invalid.emission_enabled = true
	_mat_highlight_invalid.emission = Color(0.95, 0.2, 0.2, 1.0)
	_mat_highlight_invalid.emission_energy_multiplier = 1.8

	clear_highlight()

func is_occupied() -> bool:
	return occupied and unit_reference != null and is_instance_valid(unit_reference)

func get_unit() -> Node:
	if is_occupied():
		return unit_reference
	return null

func set_unit(u: Node) -> void:
	unit_reference = u
	occupied = (u != null)
	if u != null:
		u.current_slot = self

func clear_unit() -> void:
	unit_reference = null
	occupied = false

func get_placement_position() -> Vector3:
	return global_position + Vector3(0.0, 0.12, 0.0)

func highlight_valid() -> void:
	if accent_mesh and _mat_highlight_valid:
		accent_mesh.set_surface_override_material(0, _mat_highlight_valid)

func highlight_invalid() -> void:
	if accent_mesh and _mat_highlight_invalid:
		accent_mesh.set_surface_override_material(0, _mat_highlight_invalid)

func clear_highlight() -> void:
	if accent_mesh and _mat_normal:
		accent_mesh.set_surface_override_material(0, _mat_normal)
