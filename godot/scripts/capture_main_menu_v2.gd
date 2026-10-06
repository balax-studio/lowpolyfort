extends Node

## Captures high fidelity screenshot of Updated Main Menu matching Image B reference.

var frame_count: int = 0
const SAVE_PATH = "res://screenshots/main_menu_v2.png"

func _ready() -> void:
	SaveManager.highest_wave = 14
	SaveManager.total_scrap = 135
	SaveManager.chaos_unlocked = true

	var menu_scene = load("res://scenes/ui/main_menu.tscn")
	var menu = menu_scene.instantiate()
	add_child(menu)
	menu.refresh_stats()

func _process(_delta: float) -> void:
	frame_count += 1
	if frame_count == 8:
		var dir = DirAccess.open("res://")
		if not dir.dir_exists("res://screenshots"):
			dir.make_dir("res://screenshots")

		var img = get_viewport().get_texture().get_image()
		var err = img.save_png(SAVE_PATH)
		if err == OK:
			print("MAIN_MENU_V2_SAVED: ", ProjectSettings.globalize_path(SAVE_PATH))
		else:
			push_error("Failed to save screenshot: %d" % err)
		get_tree().quit(0)
