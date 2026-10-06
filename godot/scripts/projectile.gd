extends Node3D

## Projectile representing a ballistic round fired by friendly defenders.
## Flies directly toward target; if target dies mid-air, bullet continues straight and despawns.

var target_node: Node3D = null
var target_last_pos: Vector3 = Vector3.ZERO
var direction: Vector3 = Vector3.FORWARD
var speed: float = 18.0
var damage: float = 12.0
var is_critical: bool = false
var lifetime: float = 2.0
var _hit_distance: float = 0.45

func setup(target: Node3D, p_damage: float, p_speed: float, p_is_crit: bool) -> void:
	target_node = target
	damage = p_damage
	speed = p_speed
	is_critical = p_is_crit
	if target != null and is_instance_valid(target):
		target_last_pos = target.global_position + Vector3(0, 0.4, 0)
		direction = (target_last_pos - global_position).normalized()
	else:
		direction = -global_transform.basis.z

func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return

	# Update direction if target is alive
	if target_node != null and is_instance_valid(target_node) and not target_node.is_dead:
		target_last_pos = target_node.global_position + Vector3(0, 0.4, 0)
		var to_target = target_last_pos - global_position
		direction = to_target.normalized()
		
		# Hit check
		if to_target.length() <= _hit_distance:
			_apply_hit(target_node)
			return
	else:
		# Target is dead, continue along current trajectory (Clause 27)
		target_node = null

	global_position += direction * speed * delta
	if direction.length_squared() > 0.001:
		look_at(global_position + direction, Vector3.UP)

func _apply_hit(target: Node3D) -> void:
	if target.has_method("take_damage"):
		target.take_damage(damage, is_critical)
	queue_free()
