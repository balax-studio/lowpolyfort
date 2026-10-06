extends Node

## 360-Degree Central Base Combat Staging & Screenshot Capture
## Normal Mode, Wave 2, 4 Riflemen stationed on pads covering sectors,
## 7 Basic Enemies advancing from all 360-degree perimeter sectors,
## and active projectile tracers in flight.

const HeroDefinition = preload("res://scripts/hero_definition.gd")
const EnemyDefinition = preload("res://scripts/enemy_definition.gd")

var frame_count: int = 0
var main_instance: Node = null
var spawned_enemies: Array = []
var units_list: Array = []

const SAVE_PATH = "res://screenshots/gameplay_v2.png"

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
		# Place 4 Riflemen covering the 360-degree perimeter
		var u1 = board.spawn_unit_on_slot(board.get_slot_at_index(1), 1, HeroDefinition.HeroClass.RIFLEMAN) # Slot 1: North (rear)
		var u2 = board.spawn_unit_on_slot(board.get_slot_at_index(3), 2, HeroDefinition.HeroClass.RIFLEMAN) # Slot 3: West (Lv.2)
		var u3 = board.spawn_unit_on_slot(board.get_slot_at_index(4), 1, HeroDefinition.HeroClass.RIFLEMAN) # Slot 4: East
		var u4 = board.spawn_unit_on_slot(board.get_slot_at_index(6), 1, HeroDefinition.HeroClass.RIFLEMAN) # Slot 6: South
		units_list = [u1, u2, u3, u4]

		for u in units_list:
			if u:
				u._attack_timer = 2.0
				u._target_scan_timer = 2.0

	var enemies_container = main_instance.find_child("Enemies", true, false)
	var enemy_scene = load("res://scenes/enemies/enemy.tscn")
	if enemies_container and enemy_scene:
		var basic_def = EnemyDefinition.get_definition(EnemyDefinition.EnemyType.BASIC)
		
		# 7 Basic Enemies positioned across all 360-degree compass sectors within portrait framing
		var spawn_configs = [
			Vector3(0.0, 0.0, -6.5),    # North
			Vector3(2.8, 0.0, -4.6),    # North-East
			Vector3(3.4, 0.0, -0.6),    # East
			Vector3(2.4, 0.0, 3.6),     # South-East
			Vector3(-2.4, 0.0, 3.6),    # South-West
			Vector3(-3.4, 0.0, -0.6),   # West
			Vector3(-2.8, 0.0, -4.6),   # North-West
		]

		for pos in spawn_configs:
			var e = enemy_scene.instantiate()
			enemies_container.add_child(e)
			e.setup_from_definition(basic_def, 2)
			e.global_position = pos
			e.look_at(Vector3(0.0, pos.y, 0.0), Vector3.UP)
			spawned_enemies.append(e)

	# Orient defenders to engage incoming threats with distinct 3/4 profile readability
	if units_list.size() >= 4 and spawned_enemies.size() >= 7:
		var u1 = units_list[0]
		var u2 = units_list[1]
		var u3 = units_list[2]
		var u4 = units_list[3]
		
		# u1 (North) engages North-East enemy: slight profile displays rifle length
		var u1_model = u1.find_child("ModelRoot")
		if u1_model:
			u1_model.rotation.y = deg_to_rad(30.0)

		# u2 (West) engages North-West enemy
		var u2_model = u2.find_child("ModelRoot")
		if u2_model:
			u2_model.rotation.y = deg_to_rad(-55.0)

		# u3 (East) engages East enemy
		var u3_model = u3.find_child("ModelRoot")
		if u3_model:
			u3_model.rotation.y = deg_to_rad(85.0)

		# u4 (South) engages South-East enemy
		var u4_model = u4.find_child("ModelRoot")
		if u4_model:
			u4_model.rotation.y = deg_to_rad(140.0)

	# Spawn active tracer projectiles mid-air between rifle muzzles and enemies
	var proj_container = main_instance.find_child("Projectiles", true, false)
	var proj_scene = load("res://scenes/combat/projectile.tscn")
	if proj_container and proj_scene and units_list.size() >= 4 and spawned_enemies.size() >= 7:
		# Tracer 1: from North unit towards NE enemy
		var p1 = proj_scene.instantiate()
		proj_container.add_child(p1)
		p1.setup(spawned_enemies[1], 25.0, 4.0, false)
		p1.global_position = Vector3(1.2, 0.5, -3.0)

		# Tracer 2: from East unit towards East enemy
		var p2 = proj_scene.instantiate()
		proj_container.add_child(p2)
		p2.setup(spawned_enemies[2], 25.0, 4.0, true)
		p2.global_position = Vector3(1.8, 0.5, -0.4)

		# Tracer 3: from South unit towards SE enemy
		var p3 = proj_scene.instantiate()
		proj_container.add_child(p3)
		p3.setup(spawned_enemies[3], 25.0, 4.0, false)
		p3.global_position = Vector3(0.6, 0.5, 1.8)

		# Tracer 4: from West unit towards NW enemy
		var p4 = proj_scene.instantiate()
		proj_container.add_child(p4)
		p4.setup(spawned_enemies[6], 25.0, 4.0, false)
		p4.global_position = Vector3(-1.8, 0.5, -2.4)

	var hud = main_instance.find_child("HUD", true, false)
	if hud and hud.has_method("_update_hud_display"):
		hud._update_hud_display()

func _process(_delta: float) -> void:
	frame_count += 1
	# Clear any hit flash on enemies so they show their organic mutant colors
	for e in spawned_enemies:
		if is_instance_valid(e):
			e._flash_timer = 0.0

	# Capture at frame 6 when lighting and tracers are settled mid-air
	if frame_count == 6:
		var dir = DirAccess.open("res://")
		if not dir.dir_exists("res://screenshots"):
			dir.make_dir("res://screenshots")

		var img = get_viewport().get_texture().get_image()
		var err = img.save_png(SAVE_PATH)
		if err == OK:
			print("360_COMBAT_SCREENSHOT_SAVED: ", ProjectSettings.globalize_path(SAVE_PATH))
		else:
			push_error("Failed to save screenshot: %d" % err)
		get_tree().quit(0)
