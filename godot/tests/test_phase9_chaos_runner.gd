extends Node

const ChaosModifier = preload("res://scripts/chaos_modifier.gd")
const WaveDefinition = preload("res://scripts/wave_definition.gd")

func _ready() -> void:
	print("\n--- BEGIN TEST PHASE 9: CHAOS MODE ENGINE ---")
	test_chaos_modifiers_definitions()
	test_fixed_sequence_waves_2_to_10()
	test_wave_11_plus_deduplication()
	test_chaos_spawns_scaling()
	test_rapid_fire_unit_speed()
	print("ALL PHASE 9 PARITY CHECKS PASSED SUCCESSFULLY!\n")
	get_tree().quit(0)

func test_chaos_modifiers_definitions() -> void:
	var rush = ChaosModifier.get_rush_hour()
	assert(rush.type == ChaosModifier.ChaosModifierType.RUSH_HOUR, "Rush Hour type check")
	assert(rush.enemy_speed_multiplier == 1.30, "Rush Hour speed multiplier must be 1.30")
	assert(rush.enemy_coin_multiplier == 1.15, "Rush Hour coin multiplier must be 1.15")

	var tough = ChaosModifier.get_tough_crowd()
	assert(tough.type == ChaosModifier.ChaosModifierType.TOUGH_CROWD, "Tough crowd type check")
	assert(tough.enemy_hp_multiplier == 1.35, "Tough crowd HP multiplier must be 1.35")
	assert(tough.enemy_coin_multiplier == 1.20, "Tough crowd coin multiplier must be 1.20")

	var swarm = ChaosModifier.get_swarm_wave()
	assert(swarm.type == ChaosModifier.ChaosModifierType.SWARM_WAVE, "Swarm wave type check")
	assert(swarm.enemy_hp_multiplier == 0.80, "Swarm wave HP multiplier must be 0.80")
	assert(swarm.enemy_count_multiplier == 1.50, "Swarm wave count multiplier must be 1.50")

	var rich = ChaosModifier.get_rich_wave()
	assert(rich.type == ChaosModifier.ChaosModifierType.RICH_WAVE, "Rich wave type check")
	assert(rich.enemy_coin_multiplier == 2.00, "Rich wave coin multiplier must be 2.00")

	var rapid = ChaosModifier.get_rapid_fire()
	assert(rapid.type == ChaosModifier.ChaosModifierType.RAPID_FIRE, "Rapid fire type check")
	assert(rapid.unit_attack_speed_multiplier == 1.50, "Rapid fire unit attack speed multiplier must be 1.50")

	var giants = ChaosModifier.get_giants()
	assert(giants.type == ChaosModifier.ChaosModifierType.GIANTS, "Giants type check")
	assert(giants.enemy_hp_multiplier == 2.00, "Giants HP multiplier must be 2.00")
	assert(giants.enemy_scale_multiplier == 1.40, "Giants scale multiplier must be 1.40")
	assert(giants.enemy_count_multiplier == 0.65, "Giants count multiplier must be 0.65")
	print("PASS: All 6 Chaos modifier definitions verified")

func test_fixed_sequence_waves_2_to_10() -> void:
	# Wave 1: NONE
	assert(ChaosModifier.resolve_for_wave(1).type == ChaosModifier.ChaosModifierType.NONE, "Wave 1 must be NONE")
	# Wave 2: RUSH_HOUR
	assert(ChaosModifier.resolve_for_wave(2).type == ChaosModifier.ChaosModifierType.RUSH_HOUR, "Wave 2 must be RUSH_HOUR")
	# Wave 3: RAPID_FIRE
	assert(ChaosModifier.resolve_for_wave(3).type == ChaosModifier.ChaosModifierType.RAPID_FIRE, "Wave 3 must be RAPID_FIRE")
	# Wave 4: SWARM_WAVE
	assert(ChaosModifier.resolve_for_wave(4).type == ChaosModifier.ChaosModifierType.SWARM_WAVE, "Wave 4 must be SWARM_WAVE")
	# Wave 5: TOUGH_CROWD
	assert(ChaosModifier.resolve_for_wave(5).type == ChaosModifier.ChaosModifierType.TOUGH_CROWD, "Wave 5 must be TOUGH_CROWD")
	# Wave 6: RICH_WAVE
	assert(ChaosModifier.resolve_for_wave(6).type == ChaosModifier.ChaosModifierType.RICH_WAVE, "Wave 6 must be RICH_WAVE")
	# Wave 7: RUSH_HOUR
	assert(ChaosModifier.resolve_for_wave(7).type == ChaosModifier.ChaosModifierType.RUSH_HOUR, "Wave 7 must be RUSH_HOUR")
	# Wave 8: GIANTS
	assert(ChaosModifier.resolve_for_wave(8).type == ChaosModifier.ChaosModifierType.GIANTS, "Wave 8 must be GIANTS")
	# Wave 9: RAPID_FIRE
	assert(ChaosModifier.resolve_for_wave(9).type == ChaosModifier.ChaosModifierType.RAPID_FIRE, "Wave 9 must be RAPID_FIRE")
	# Wave 10: RICH_WAVE
	assert(ChaosModifier.resolve_for_wave(10).type == ChaosModifier.ChaosModifierType.RICH_WAVE, "Wave 10 must be RICH_WAVE")
	print("PASS: Fixed sequence for Waves 2-10 (Clause 312) verified")

func test_wave_11_plus_deduplication() -> void:
	for wave in range(11, 20):
		var prev = ChaosModifier.ChaosModifierType.RAPID_FIRE
		var resolved = ChaosModifier.resolve_for_wave(wave, prev)
		assert(resolved.type != prev, "Wave %d should not repeat previous modifier %s" % [wave, prev])
	print("PASS: Wave 11+ non-repeating modifier selection verified")

func test_chaos_spawns_scaling() -> void:
	# Wave 4 base spawns: 13
	var base_w4 = WaveDefinition.generate(4, ChaosModifier.get_none())
	# Wave 4 with Swarm Wave (+50% enemies): ceil(13 * 1.5) = 20
	var swarm_w4 = WaveDefinition.generate(4, ChaosModifier.get_swarm_wave())
	assert(swarm_w4.spawns.size() == 20, "Swarm wave 4 should scale count to 20, got %d" % swarm_w4.spawns.size())

	# Check Giants wave 8 (0.65x count):
	var base_w8 = WaveDefinition.generate(8, ChaosModifier.get_none())
	var giants_w8 = WaveDefinition.generate(8, ChaosModifier.get_giants())
	assert(giants_w8.spawns.size() < base_w8.spawns.size(), "Giants wave should have fewer enemies")
	for s in giants_w8.spawns:
		assert(s.hp_multiplier == 2.00, "Giants spawn HP multiplier must be 2.00")
		assert(s.visual_scale == 1.40, "Giants spawn visual scale must be 1.40")
	print("PASS: Chaos modifier spawn counts, HP multipliers, and scales verified")

func test_rapid_fire_unit_speed() -> void:
	var unit_scene = preload("res://scenes/units/unit.tscn")
	var unit = unit_scene.instantiate()
	add_child(unit)

	GameManager.reset_run()
	GameManager.current_mode = GameManager.GameMode.NORMAL
	var normal_aspd = unit.get_attack_speed()

	GameManager.current_mode = GameManager.GameMode.CHAOS
	GameManager.active_chaos_modifier = ChaosModifier.get_rapid_fire()
	var rapid_aspd = unit.get_attack_speed()

	assert(is_equal_approx(rapid_aspd, normal_aspd * 1.50), "Unit attack speed in Rapid Fire must be 1.50x normal")
	unit.queue_free()
	print("PASS: Rapid Fire unit attack speed scaling verified")
