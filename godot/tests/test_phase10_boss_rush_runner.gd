extends Node

const BossRushRoundData = preload("res://scripts/boss_rush_round_data.gd")
const WaveDefinition = preload("res://scripts/wave_definition.gd")

func _ready() -> void:
	print("\n--- BEGIN TEST PHASE 10: BOSS RUSH MODE ---")
	test_boss_rush_round_specs()
	test_boss_rush_starting_economy()
	test_boss_rush_wave_generation()
	test_boss_rush_victory_and_scrap()
	print("ALL PHASE 10 PARITY CHECKS PASSED SUCCESSFULLY!\n")
	get_tree().quit(0)

func test_boss_rush_round_specs() -> void:
	var r1 = BossRushRoundData.get_round(1)
	assert(r1.boss_hp_multiplier == 1.00, "R1 HP mult")
	assert(r1.boss_coin_reward == 120, "R1 coin reward")
	assert(r1.support_roster.is_empty(), "R1 solo boss")

	var r2 = BossRushRoundData.get_round(2)
	assert(r2.boss_hp_multiplier == 1.35, "R2 HP mult")
	assert(r2.support_roster[EnemyDefinition.EnemyType.RUNNER] == 4, "R2 4 runners")

	var r3 = BossRushRoundData.get_round(3)
	assert(r3.boss_hp_multiplier == 1.75, "R3 HP mult")
	assert(r3.support_roster[EnemyDefinition.EnemyType.TANK] == 2, "R3 2 tanks")
	assert(r3.support_roster[EnemyDefinition.EnemyType.BASIC] == 4, "R3 4 basics")

	var r4 = BossRushRoundData.get_round(4)
	assert(r4.boss_hp_multiplier == 2.25, "R4 HP mult")
	assert(r4.support_roster[EnemyDefinition.EnemyType.SHIELDED] == 3, "R4 3 shielded")
	assert(r4.support_roster[EnemyDefinition.EnemyType.SWARM] == 6, "R4 6 swarms")

	var r5 = BossRushRoundData.get_round(5)
	assert(r5.boss_hp_multiplier == 3.00, "R5 HP mult")
	assert(r5.support_roster[EnemyDefinition.EnemyType.TANK] == 2, "R5 2 tanks")
	assert(r5.support_roster[EnemyDefinition.EnemyType.SHIELDED] == 2, "R5 2 shielded")
	assert(r5.support_roster[EnemyDefinition.EnemyType.RUNNER] == 6, "R5 6 runners")
	print("PASS: Boss Rush 5 round specifications verified")

func test_boss_rush_starting_economy() -> void:
	GameManager.current_mode = GameManager.GameMode.BOSS_RUSH
	GameManager.reset_run()
	assert(GameManager.coins == 300, "Boss Rush must start with 300 coins, got %d" % GameManager.coins)
	print("PASS: Boss Rush starting economy (300 coins) verified")

func test_boss_rush_wave_generation() -> void:
	# Round 1 has 1 spawn (solo boss)
	var w1 = WaveDefinition.generate_boss_rush_round(1)
	assert(w1.spawns.size() == 1, "R1 must have exactly 1 spawn (solo boss)")
	assert(w1.spawns[0].enemy_type == EnemyDefinition.EnemyType.BOSS, "R1 spawn must be BOSS")

	# Round 2 has 1 boss + 4 runners = 5 spawns
	var w2 = WaveDefinition.generate_boss_rush_round(2)
	assert(w2.spawns.size() == 5, "R2 must have 5 spawns (1 boss + 4 runners)")

	# Round 5 has 1 boss + 2 tanks + 2 shielded + 6 runners = 11 spawns
	var w5 = WaveDefinition.generate_boss_rush_round(5)
	assert(w5.spawns.size() == 11, "R5 must have 11 spawns")
	print("PASS: Boss Rush wave generation & support rosters verified")

func test_boss_rush_victory_and_scrap() -> void:
	SaveManager.save_file_path = "user://test_phase10_save.json"
	SaveManager.reset_all_progress()
	SaveManager.best_boss_rush_round = 0
	SaveManager.save_to_disk()

	GameManager.current_mode = GameManager.GameMode.BOSS_RUSH
	GameManager.reset_run()

	# Simulate completing all 5 rounds
	GameManager.trigger_boss_rush_victory()

	assert(GameManager.state == GameManager.GameState.GAME_OVER, "State must be GAME_OVER")
	assert(GameManager.scrap_earned_this_run == 50, "Victory scrap must be 50, got %d" % GameManager.scrap_earned_this_run)
	assert(SaveManager.best_boss_rush_round == 5, "Best round in save must be 5")
	assert(SaveManager.total_scrap == 50, "Total scrap must be 50")
	print("PASS: Boss Rush victory sequence and 50 scrap payout verified")
