extends Node

## Helper to capture visual proof of the Godot 4 Vertical Slice.
## Spawns Riflemen and incoming enemies, renders frames with real lights and shadows,
## and captures a high-resolution screenshot.

var frame_count: int = 0
var main_instance: Node = null

func _ready() -> void:
	var main_scene = load("res://scenes/main.tscn")
	main_instance = main_scene.instantiate()
	add_child(main_instance)
	
	var board = main_instance.find_child("Board", true, false)
	# Spawn Riflemen on tactical pads
	board.spawn_unit_on_slot(board.get_slot_at_index(1), 1) # North pad
	board.spawn_unit_on_slot(board.get_slot_at_index(4), 2) # East pad (Lv.2)
	board.spawn_unit_on_slot(board.get_slot_at_index(3), 1) # West pad
	
	# Spawn incoming enemies
	var enemy_scene = load("res://scenes/enemies/enemy.tscn")
	var enemies_container = main_instance.find_child("Enemies", true, false)
	
	var e1 = enemy_scene.instantiate()
	enemies_container.add_child(e1)
	e1.global_position = Vector3(0.0, 0.0, -7.0)
	
	var e2 = enemy_scene.instantiate()
	enemies_container.add_child(e2)
	e2.global_position = Vector3(5.0, 0.0, -6.0)

	var e3 = enemy_scene.instantiate()
	enemies_container.add_child(e3)
	e3.global_position = Vector3(-4.5, 0.0, -4.5)

func _process(_delta: float) -> void:
	frame_count += 1
	# Wait for rendering pipeline and shaders to settle
	if frame_count == 35:
		var dir = DirAccess.open("res://")
		if not dir.dir_exists("res://screenshots"):
			dir.make_dir("res://screenshots")
		
		var img = get_viewport().get_texture().get_image()
		var save_path = "res://screenshots/vertical_slice_showcase.png"
		var err = img.save_png(save_path)
		if err == OK:
			print("SHOWCASE_SCREENSHOT_SAVED: ", ProjectSettings.globalize_path(save_path))
		else:
			push_error("Failed to save screenshot: %d" % err)
		get_tree().quit(0)
