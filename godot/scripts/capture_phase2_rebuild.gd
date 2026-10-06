extends Node

## Visual Rebuild Phase 2 Staging & Screenshot Capture
## Normal Mode, 3 Riflemen on tactical pads (including Slot 1 rear-middle pad),
## 4 Basic Enemies advancing along lanes, soft diorama shadows.

const HeroDefinition = preload("res://scripts/hero_definition.gd")
const EnemyDefinition = preload("res://scripts/enemy_definition.gd")

var frame_count: int = 0
var main_instance: Node = null

const SAVE_PATH = "res://screenshots/phase2_visual_rebuild.png"

func _ready() -> void:
	SaveManager.tutorial_completed = true
	GameManager.current_mode = GameManager.GameMode.NORMAL
	GameManager.reset_run()
	GameManager.current_wave = 2
	GameManager.coins = 160
	GameManager.base_hp = 1000.0

	var main_scene = load("res://scenes/main.tscn")
	main_instance = main_scene.instantiate()
	add_child(main_instance)

	var board = main_instance.find_child("Board", true, false)
	if board:
		# Place 3 Riflemen: Slot 1 (rear-middle to prove clearance), Slot 3 (West), Slot 4 (East)
		var u1 = board.spawn_unit_on_slot(board.get_slot_at_index(1), 1, HeroDefinition.HeroClass.RIFLEMAN) # Rear-Middle
		var u2 = board.spawn_unit_on_slot(board.get_slot_at_index(3), 2, HeroDefinition.HeroClass.RIFLEMAN) # West (Lv.2)
		var u3 = board.spawn_unit_on_slot(board.get_slot_at_index(4), 1, HeroDefinition.HeroClass.RIFLEMAN) # East

		# Aim weapons towards incoming threats for distinct tactical silhouette
		if u1 and u1.find_child("WeaponPivot"):
			u1.find_child("WeaponPivot").rotation.y = deg_to_rad(5.0)
		if u2 and u2.find_child("WeaponPivot"):
			u2.find_child("WeaponPivot").rotation.y = deg_to_rad(35.0)
		if u3 and u3.find_child("WeaponPivot"):
			u3.find_child("WeaponPivot").rotation.y = deg_to_rad(-30.0)

	var enemies_container = main_instance.find_child("Enemies", true, false)
	var enemy_scene = load("res://scenes/enemies/enemy.tscn")
	if enemies_container and enemy_scene:
		var basic_def = EnemyDefinition.get_definition(EnemyDefinition.EnemyType.BASIC)
		
		# 4 Basic Enemies with distinct bipedal prowler anatomy advancing toward fort
		var e1 = enemy_scene.instantiate()
		enemies_container.add_child(e1)
		e1.setup_from_definition(basic_def, 2)
		e1.global_position = Vector3(0.0, 0.0, -6.8)

		var e2 = enemy_scene.instantiate()
		enemies_container.add_child(e2)
		e2.setup_from_definition(basic_def, 2)
		e2.global_position = Vector3(3.6, 0.0, -6.0)

		var e3 = enemy_scene.instantiate()
		enemies_container.add_child(e3)
		e3.setup_from_definition(basic_def, 2)
		e3.global_position = Vector3(-3.5, 0.0, -5.6)

		var e4 = enemy_scene.instantiate()
		enemies_container.add_child(e4)
		e4.setup_from_definition(basic_def, 2)
		e4.global_position = Vector3(1.2, 0.0, -8.4)

	var hud = main_instance.find_child("HUD", true, false)
	if hud and hud.has_method("_update_hud_display"):
		hud._update_hud_display()

func _process(_delta: float) -> void:
	frame_count += 1
	# Capture at frame 22: soft lighting settled, tracer bullets active, models fully drawn
	if frame_count == 22:
		var dir = DirAccess.open("res://")
		if not dir.dir_exists("res://screenshots"):
			dir.make_dir("res://screenshots")

		var img = get_viewport().get_texture().get_image()
		var err = img.save_png(SAVE_PATH)
		if err == OK:
			print("PHASE2_SCREENSHOT_SAVED: ", ProjectSettings.globalize_path(SAVE_PATH))
		else:
			push_error("Failed to save screenshot: %d" % err)
		get_tree().quit(0)
