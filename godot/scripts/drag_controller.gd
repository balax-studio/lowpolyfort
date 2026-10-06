extends Node

## 3D Drag & Drop and Unit Merge Controller.
## Translates screen touch/mouse input to ground plane coordinates using Camera3D ray projection.
## Handles picking units, slot hovering feedback (valid lime vs invalid red), and merge leveling.

@export var board_ref: Node3D = null
@export var camera_ref: Camera3D = null

var dragged_unit: Node3D = null
var origin_slot: Node3D = null
var hovered_slot: Node3D = null

var ground_plane: Plane = Plane(Vector3.UP, 0.0)

func _ready() -> void:
	if board_ref == null:
		board_ref = get_tree().get_first_node_in_group("board")
	if camera_ref == null:
		camera_ref = get_viewport().get_camera_3d()

func _unhandled_input(event: InputEvent) -> void:
	if GameManager.state == GameManager.GameState.GAME_OVER:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_handle_press(event.position)
			else:
				_handle_release(event.position)
	elif event is InputEventMouseMotion:
		if dragged_unit != null:
			_handle_drag(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_handle_press(event.position)
		else:
			_handle_release(event.position)
	elif event is InputEventScreenDrag:
		if dragged_unit != null:
			_handle_drag(event.position)

func _get_ground_hit(screen_pos: Vector2) -> Variant:
	if camera_ref == null:
		camera_ref = get_viewport().get_camera_3d()
	if camera_ref == null:
		return null
	var from = camera_ref.project_ray_origin(screen_pos)
	var dir = camera_ref.project_ray_normal(screen_pos)
	var hit = ground_plane.intersects_ray(from, dir)
	return hit

func _handle_press(screen_pos: Vector2) -> void:
	var hit = _get_ground_hit(screen_pos)
	if hit == null:
		return

	var hit_pos: Vector3 = hit
	var units = get_tree().get_nodes_in_group("units")
	var closest_unit: Node3D = null
	var min_dist: float = 0.95

	for u in units:
		if not is_instance_valid(u) or u.current_slot == null:
			continue
		var dist = hit_pos.distance_to(u.global_position)
		if dist < min_dist:
			min_dist = dist
			closest_unit = u

	if closest_unit != null:
		_start_dragging(closest_unit)

func _start_dragging(unit: Node3D) -> void:
	dragged_unit = unit
	origin_slot = unit.current_slot
	unit.set_dragging(true)

func _handle_drag(screen_pos: Vector2) -> void:
	if dragged_unit == null:
		return

	var hit = _get_ground_hit(screen_pos)
	if hit == null:
		return

	var hit_pos: Vector3 = hit
	# Unit follows cursor elevated 0.4 world units above ground (Clause 44)
	dragged_unit.global_position = Vector3(hit_pos.x, 0.4, hit_pos.z)

	# Find slot hovered
	var target_slot = _find_closest_slot(hit_pos)
	if target_slot != hovered_slot:
		if hovered_slot != null:
			hovered_slot.clear_highlight()
		hovered_slot = target_slot

	if hovered_slot != null:
		if hovered_slot == origin_slot:
			hovered_slot.clear_highlight()
		elif not hovered_slot.is_occupied():
			# Empty slot is a valid move target (Clause 44, 45)
			hovered_slot.highlight_valid()
		else:
			# Occupied: check if mergeable
			var other_unit = hovered_slot.get_unit()
			if _can_merge(dragged_unit, other_unit):
				hovered_slot.highlight_valid()
			else:
				hovered_slot.highlight_invalid()

func _handle_release(screen_pos: Vector2) -> void:
	if dragged_unit == null:
		return

	var hit = _get_ground_hit(screen_pos)
	var target_slot: Node3D = null
	if hit != null:
		target_slot = _find_closest_slot(hit)

	if target_slot != null and target_slot != origin_slot:
		if not target_slot.is_occupied():
			# Move to empty slot
			_move_to_slot(dragged_unit, origin_slot, target_slot)
		else:
			var target_unit = target_slot.get_unit()
			if _can_merge(dragged_unit, target_unit):
				# Execute Merge! (Clause 42, 45, 46)
				_execute_merge(dragged_unit, origin_slot, target_unit, target_slot)
			else:
				# Invalid target: return to origin
				_return_to_origin(dragged_unit, origin_slot)
	else:
		# Return to origin
		_return_to_origin(dragged_unit, origin_slot)

	if hovered_slot != null:
		hovered_slot.clear_highlight()
		hovered_slot = null

	dragged_unit = null
	origin_slot = null

func _can_merge(u1: Node3D, u2: Node3D) -> bool:
	if u1 == null or u2 == null:
		return false
	if u1.level >= GameBalance.MAX_UNIT_LEVEL or u2.level >= GameBalance.MAX_UNIT_LEVEL:
		return false # Max level reached (Clause 47)
	# Same hero class + same level (Clause 45, 620)
	var c1 = u1.hero_class if ("hero_class" in u1) else HeroDefinition.HeroClass.RIFLEMAN
	var c2 = u2.hero_class if ("hero_class" in u2) else HeroDefinition.HeroClass.RIFLEMAN
	return c1 == c2 and u1.level == u2.level

func _move_to_slot(unit: Node3D, from_slot: Node3D, to_slot: Node3D) -> void:
	from_slot.clear_unit()
	to_slot.set_unit(unit)
	unit.set_dragging(false)
	var dest_pos = to_slot.get_placement_position()
	var tween = create_tween()
	tween.tween_property(unit, "global_position", dest_pos, 0.08)

func _execute_merge(dragged: Node3D, from_slot: Node3D, target: Node3D, to_slot: Node3D) -> void:
	from_slot.clear_unit()
	dragged.set_dragging(false)
	
	# Increase target level (Clause 42, 46)
	target.update_level(target.level + 1)
	target.play_merge_effect()
	
	# Camera impulse on merge (Clause 88)
	if camera_ref and camera_ref.has_method("add_trauma"):
		camera_ref.add_trauma(0.28)

	# Check interactive tutorial progression (Clause 55, 143)
	if GameManager.tutorial_step == 3:
		GameManager.advance_tutorial_step(4)
	
	# Free dragged unit
	dragged.queue_free()

func _return_to_origin(unit: Node3D, slot: Node3D) -> void:
	unit.set_dragging(false)
	if slot != null:
		var origin_pos = slot.get_placement_position()
		var tween = create_tween()
		tween.tween_property(unit, "global_position", origin_pos, 0.12)

func _find_closest_slot(pos: Vector3) -> Node3D:
	if board_ref == null:
		return null
	var slots = board_ref.get_slots()
	var closest: Node3D = null
	var min_dist: float = 1.3
	for s in slots:
		var dist = Vector2(pos.x, pos.z).distance_to(Vector2(s.global_position.x, s.global_position.z))
		if dist < min_dist:
			min_dist = dist
			closest = s
	return closest
