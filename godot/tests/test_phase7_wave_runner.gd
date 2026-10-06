extends Node

const WaveDefinition = preload("res://scripts/wave_definition.gd")
const EnemyDefinition = preload("res://scripts/enemy_definition.gd")
const UpgradeCard = preload("res://scripts/upgrade_card.gd")

func _ready() -> void:
	print("\n--- BEGIN TEST PHASE 7: WAVES, UPGRADES & BOSS ENCOUNTERS ---")
	test_wave_definitions()
	test_boss_definition_and_charge()
	test_upgrade_cards_and_application()
	test_wave_5_and_10_mode_unlocks()
	test_upgrade_bounty_scaling()
	print("ALL PHASE 7 PARITY CHECKS PASSED SUCCESSFULLY!\n")
	get_tree().quit(0)

func test_wave_definitions() -> void:
	# Wave 1: 7 Basic
	var w1 = WaveDefinition.generate(1)
	assert(w1.spawns.size() == 7, "Wave 1 must have 7 spawns, got %d" % w1.spawns.size())
	for s in w1.spawns:
		assert(s.enemy_type == EnemyDefinition.EnemyType.BASIC, "Wave 1 should only have BASIC")

	# Wave 2: 7 Basic, 2 Runner (total 9)
	var w2 = WaveDefinition.generate(2)
	assert(w2.spawns.size() == 9, "Wave 2 must have 9 spawns, got %d" % w2.spawns.size())

	# Wave 3: 8 Basic, 3 Runner (total 11)
	var w3 = WaveDefinition.generate(3)
	assert(w3.spawns.size() == 11, "Wave 3 must have 11 spawns, got %d" % w3.spawns.size())

	# Wave 4: 8 Basic, 3 Runner, 2 Swarm (total 13)
	var w4 = WaveDefinition.generate(4)
	assert(w4.spawns.size() == 13, "Wave 4 must have 13 spawns, got %d" % w4.spawns.size())

	# Wave 5: Boss Wave
	var w5 = WaveDefinition.generate(5)
	assert(w5.is_boss_wave == true, "Wave 5 must be marked is_boss_wave")
	var has_boss_w5 = false
	var boss_warn_w5 = false
	for s in w5.spawns:
		if s.enemy_type == EnemyDefinition.EnemyType.BOSS:
			has_boss_w5 = true
			if s.trigger_warning:
				boss_warn_w5 = true
	assert(has_boss_w5, "Wave 5 must contain a BOSS spawn")
	assert(boss_warn_w5, "Wave 5 BOSS must trigger warning banner")

	# Wave 10: Boss Wave with Shielded & Tanks
	var w10 = WaveDefinition.generate(10)
	assert(w10.is_boss_wave == true, "Wave 10 must be marked is_boss_wave")
	var has_boss_w10 = false
	for s in w10.spawns:
		if s.enemy_type == EnemyDefinition.EnemyType.BOSS:
			has_boss_w10 = true
			break
	assert(has_boss_w10, "Wave 10 must contain a BOSS spawn")
	print("PASS: Wave 1-10 definitions and enemy composition verified")

func test_boss_definition_and_charge() -> void:
	var boss_def = EnemyDefinition.get_definition(EnemyDefinition.EnemyType.BOSS)
	assert(boss_def.base_hp == 1200.0, "Boss base HP must be 1200, got %f" % boss_def.base_hp)
	assert(boss_def.base_speed == 0.7, "Boss base speed must be 0.7, got %f" % boss_def.base_speed)
	assert(boss_def.charge_speed == 1.60, "Boss charge speed must be 1.60, got %f" % boss_def.charge_speed)
	assert(boss_def.charge_duration == 1.2, "Boss charge duration must be 1.2, got %f" % boss_def.charge_duration)
	assert(boss_def.charge_cooldown == 7.0, "Boss charge cooldown must be 7.0, got %f" % boss_def.charge_cooldown)
	assert(boss_def.base_damage == 65.0, "Boss base damage must be 65, got %f" % boss_def.base_damage)
	assert(boss_def.base_coin_reward == 100, "Boss base coin reward must be 100, got %d" % boss_def.base_coin_reward)

	# Test Enemy instantiation and scaling with boss
	var enemy_scene: PackedScene = preload("res://scenes/enemies/enemy.tscn")
	var boss_node = enemy_scene.instantiate()
	add_child(boss_node)
	boss_node.setup_from_definition(boss_def, 5)
	assert(boss_node.max_hp > 1200.0, "Wave 5 Boss HP must scale above base HP")
	assert(boss_node.charge_speed == 1.60, "Boss node charge speed must match definition")
	assert(boss_node.coin_reward == 100, "Boss node coin reward must be 100")
	boss_node.queue_free()
	print("PASS: Boss definition, stats, and charge parameters verified")

func test_upgrade_cards_and_application() -> void:
	var pool = UpgradeCard.get_pool()
	assert(pool.size() == 8, "Upgrade pool must have exactly 8 cards, got %d" % pool.size())

	GameManager.reset_run()
	assert(GameManager.upgrade_damage_bonus == 0.0, "Damage bonus should start at 0")
	assert(GameManager.has_armor_piercing_upgrade == false, "AP upgrade should start false")

	# Heavy ammo (+15% dmg)
	var heavy_ammo = UpgradeCard.new("heavy_ammo", "HEAVY AMMO", "+15% UNIT DAMAGE", UpgradeCard.UpgradeRarity.COMMON, UpgradeCard.UpgradeType.HEAVY_AMMO, 0.15)
	GameManager.apply_upgrade(heavy_ammo)
	assert(is_equal_approx(GameManager.upgrade_damage_bonus, 0.15), "Damage bonus must be 0.15")

	# Rapid fire (+10% aspd)
	var rapid_fire = UpgradeCard.new("rapid_fire", "RAPID FIRE", "+10% ATTACK SPEED", UpgradeCard.UpgradeRarity.COMMON, UpgradeCard.UpgradeType.RAPID_FIRE, 0.10)
	GameManager.apply_upgrade(rapid_fire)
	assert(is_equal_approx(GameManager.upgrade_aspd_bonus, 0.10), "Attack speed bonus must be 0.10")

	# Fortified base (+200 HP)
	var prev_max_hp = GameManager.max_base_hp
	var fort_base = UpgradeCard.new("fort_base", "FORTIFIED BASE", "+200 HP", UpgradeCard.UpgradeRarity.COMMON, UpgradeCard.UpgradeType.FORTIFIED_BASE, 200.0)
	GameManager.apply_upgrade(fort_base)
	assert(GameManager.max_base_hp == prev_max_hp + 200.0, "Base max HP must increase by 200")

	# Field repair (+30% heal)
	GameManager.base_hp = 500.0
	var field_repair = UpgradeCard.new("repair", "FIELD REPAIR", "+30% HEAL", UpgradeCard.UpgradeRarity.RARE, UpgradeCard.UpgradeType.FIELD_REPAIR, 0.30)
	GameManager.apply_upgrade(field_repair)
	assert(GameManager.base_hp == 500.0 + (GameManager.max_base_hp * 0.30), "Base HP must heal 30% of max")

	# Armor piercing
	var ap_card = UpgradeCard.new("ap", "ARMOR PIERCING", "+20%", UpgradeCard.UpgradeRarity.EPIC, UpgradeCard.UpgradeType.ARMOR_PIERCING, 0.20)
	GameManager.apply_upgrade(ap_card)
	assert(GameManager.has_armor_piercing_upgrade == true, "AP flag must be true")
	print("PASS: Upgrade pool (8 cards) and stat modification engine verified")

func test_wave_5_and_10_mode_unlocks() -> void:
	SaveManager.save_file_path = "user://test_phase7_save.json"
	SaveManager.reset_all_progress()
	SaveManager.chaos_unlocked = false
	SaveManager.boss_rush_unlocked = false
	SaveManager.save_to_disk()

	GameManager.reset_run()
	GameManager.current_mode = GameManager.GameMode.NORMAL
	GameManager.current_wave = 5

	# Defeating boss on Wave 5 unlocks Chaos
	GameManager.on_boss_defeated(100)
	assert(SaveManager.chaos_unlocked == true, "Defeating Wave 5 Boss must unlock Chaos Mode")
	assert(SaveManager.boss_rush_unlocked == false, "Boss Rush should not be unlocked yet")

	# Defeating boss on Wave 10 unlocks Boss Rush
	GameManager.current_wave = 10
	GameManager.on_boss_defeated(100)
	assert(SaveManager.boss_rush_unlocked == true, "Defeating Wave 10 Boss must unlock Boss Rush Mode")
	assert(GameManager.bosses_defeated_this_run == 2, "Bosses defeated count must be 2")
	print("PASS: Mode unlock milestones (Wave 5 -> Chaos, Wave 10 -> Boss Rush) verified")

func test_upgrade_bounty_scaling() -> void:
	GameManager.reset_run()
	var start_coins = GameManager.coins
	
	# Regular kill without bounty bonus
	GameManager.on_enemy_killed(10)
	assert(GameManager.coins == start_coins + 10, "Base enemy reward must be 10 coins")
	
	# Apply Bounty Hunter (+15% coins)
	var bounty_card = UpgradeCard.new("bounty", "BOUNTY", "+15%", UpgradeCard.UpgradeRarity.RARE, UpgradeCard.UpgradeType.BOUNTY_HUNTER, 0.15)
	GameManager.apply_upgrade(bounty_card)
	
	var coins_before = GameManager.coins
	GameManager.on_enemy_killed(10)
	# 10 * 1.15 = 11.5 -> rounded to 12
	assert(GameManager.coins == coins_before + 12, "Coins with +15% bounty should be 12 (rounded from 11.5)")
	print("PASS: Bounty Hunter coin reward multiplier verified")
