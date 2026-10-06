extends Node3D

## Tactical Board managing the 8 defensive slots arranged symmetrically around Central Base.
## Layout:
##   Slot 0 (-2.2, 0, -2.2)   Slot 1 (0, 0, -2.2)   Slot 2 (2.2, 0, -2.2)
##   Slot 3 (-2.2, 0,  0.0)      [CENTRAL BASE]     Slot 4 (2.2, 0,  0.0)
##   Slot 5 (-2.2, 0,  2.2)   Slot 6 (0, 0,  2.2)   Slot 7 (2.2, 0,  2.2)

@export var unit_scene: PackedScene = null

@onready var slots_container: Node3D = $Slots

var slots: Array[Node3D] = []

func _ready() -> void:
	GameManager.board_ref = self
	_initialize_slots()

func _initialize_slots() -> void:
	slots.clear()
	for child in slots_container.get_children():
		if child.is_in_group("slots"):
			slots.append(child)
	# Sort by slot_index for consistent ordering
	slots.sort_custom(func(a, b): return a.slot_index < b.slot_index)

func get_slots() -> Array[Node3D]:
	if slots.is_empty():
		_initialize_slots()
	return slots

func get_first_empty_slot() -> Node3D:
	for slot in get_slots():
		if not slot.is_occupied():
			return slot
	return null

func get_slot_at_index(idx: int) -> Node3D:
	var all_slots = get_slots()
	if idx >= 0 and idx < all_slots.size():
		return all_slots[idx]
	return null

func spawn_unit_on_slot(slot: Node3D, level: int = 1, h_class: HeroDefinition.HeroClass = HeroDefinition.HeroClass.RIFLEMAN) -> Node:
	if slot == null or slot.is_occupied():
		return null
	
	if unit_scene == null:
		unit_scene = load("res://scenes/units/unit.tscn")
	
	if unit_scene == null:
		push_error("Unit scene could not be loaded!")
		return null

	var unit_instance = unit_scene.instantiate()
	unit_instance.level = level
	if unit_instance.has_method("set_hero_class"):
		unit_instance.set_hero_class(h_class)
	
	# Place in World units container or on board
	var units_parent = get_tree().get_first_node_in_group("units_container")
	if units_parent == null:
		units_parent = self
	
	units_parent.add_child(unit_instance)
	unit_instance.global_position = slot.get_placement_position()
	slot.set_unit(unit_instance)
	
	# Unit spawn scale punch tween (Clause 17)
	unit_instance.play_spawn_effect()
	
	return unit_instance

func clear_all_units() -> void:
	for slot in get_slots():
		if slot.is_occupied():
			var u = slot.get_unit()
			slot.clear_unit()
			if u != null and is_instance_valid(u):
				u.queue_free()

func reset_board() -> void:
	clear_all_units()
