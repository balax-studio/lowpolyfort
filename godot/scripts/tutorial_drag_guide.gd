class_name TutorialDragGuide
extends Control

## Animated Bezier Drag Guidance Indicator (Clause 1088).
## Draws a pulsating dotted curve and glowing target drop zone between Slot 0 and Slot 1.

var _progress: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	if not visible:
		return
	_progress = fmod(_progress + delta * 0.72, 1.0)
	queue_redraw()

func _draw() -> void:
	var vp_size = get_viewport_rect().size
	var scale_x = vp_size.x / 450.0
	var scale_y = vp_size.y / 800.0

	var start_pos = Vector2(140.0 * scale_x, 520.0 * scale_y)
	var target_pos = Vector2(230.0 * scale_x, 520.0 * scale_y)
	var ctrl_pos = Vector2((start_pos.x + target_pos.x) * 0.5, start_pos.y - 45.0 * scale_y)

	# Draw curved dashed path
	var points: PackedVector2Array = []
	var steps = 24
	for i in range(steps + 1):
		var t = float(i) / float(steps)
		var p = (1.0 - t) * (1.0 - t) * start_pos + 2.0 * (1.0 - t) * t * ctrl_pos + t * t * target_pos
		points.append(p)

	for i in range(points.size() - 1):
		if i % 2 == 0:
			draw_line(points[i], points[i + 1], Color(0.96, 0.88, 0.15, 0.45), 2.5)

	# Animated moving pulse dot
	var t_dot = _progress
	var dot_pos = (1.0 - t_dot) * (1.0 - t_dot) * start_pos + 2.0 * (1.0 - t_dot) * t_dot * ctrl_pos + t_dot * t_dot * target_pos
	var pulse_radius = 7.0 + sin(_progress * PI) * 3.0

	draw_circle(dot_pos, pulse_radius + 2.0, Color(0.05, 0.05, 0.05, 0.9))
	draw_circle(dot_pos, pulse_radius, Color(0.96, 0.88, 0.15, 1.0))

	# Pulsing target halo
	var halo_radius = 24.0 + abs(sin(_progress * 2.0 * PI)) * 5.0
	draw_arc(target_pos, halo_radius, 0.0, TAU, 32, Color(0.4, 0.85, 0.45, 0.55), 2.5)
