extends Camera3D

## Tactical Camera with smooth diorama framing and subtle trauma-based screen shake.
## Restricted to Merge events and Base damage per Clause 88.

var trauma: float = 0.0
var _base_position: Vector3 = Vector3(0.0, 11.5, 10.5)
var _last_hp: float = 1000.0

func _ready() -> void:
	_base_position = position
	GameManager.base_hp_changed.connect(_on_base_hp_changed)

func add_trauma(amount: float) -> void:
	trauma = clamp(trauma + amount, 0.0, 1.0)

func _on_base_hp_changed(current_hp: float, _max_hp: float) -> void:
	if current_hp < _last_hp and current_hp > 0.0:
		# Clause 88: Subtle impulse on base damage
		add_trauma(0.35)
	elif current_hp <= 0.0:
		# Base destruction shake
		add_trauma(0.7)
	_last_hp = current_hp

func _process(delta: float) -> void:
	if trauma > 0.0:
		trauma = max(0.0, trauma - delta * 2.2)
		var shake_amount = trauma * trauma
		var time = Time.get_ticks_msec() * 0.04
		var offset_x = sin(time * 1.3) * 0.22 * shake_amount
		var offset_y = cos(time * 1.7) * 0.15 * shake_amount
		var offset_z = sin(time * 0.9) * 0.18 * shake_amount
		position = _base_position + Vector3(offset_x, offset_y, offset_z)
	else:
		position = _base_position
