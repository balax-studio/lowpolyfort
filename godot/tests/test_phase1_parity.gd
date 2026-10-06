extends SceneTree

func _init() -> void:
	print("--- BEGIN TEST PHASE 1: SHARED DATA / CONSTANTS / RESOURCES ---")
	var failed: int = 0

	# 1. Base & Economy constants
	if GameBalance.BASE_STARTING_HP != 1000.0:
		print("FAIL: BASE_STARTING_HP mismatch")
		failed += 1
	if GameBalance.STARTING_COINS != 150:
		print("FAIL: STARTING_COINS mismatch")
		failed += 1
	if GameBalance.UNIT_BASE_COST != 50:
		print("FAIL: UNIT_BASE_COST mismatch")
		failed += 1

	# Test cost curve: count=0 -> 50, count=1 -> 55, count=2 -> 61, count=3 -> 67
	var c0 = GameBalance.get_unit_cost(0)
	var c1 = GameBalance.get_unit_cost(1)
	var c2 = GameBalance.get_unit_cost(2)
	var c3 = GameBalance.get_unit_cost(3)
	if c0 != 50 or c1 != 55 or c2 != 61 or c3 != 67:
		print("FAIL: Cost curve mismatch! c0=%d, c1=%d, c2=%d, c3=%d" % [c0, c1, c2, c3])
		failed += 1
	else:
		print("PASS: Cost curve matches Flutter exactly (50, 55, 61, 67)")

	# 2. Hero scaling exponents
	# pow(1.75, 0) = 1.0, pow(1.75, 1) = 1.75, pow(1.75, 2) = 3.0625
	var d1 = GameBalance.get_hero_damage_multiplier(1)
	var d2 = GameBalance.get_hero_damage_multiplier(2)
	var d3 = GameBalance.get_hero_damage_multiplier(3)
	if not is_equal_approx(d1, 1.0) or not is_equal_approx(d2, 1.75) or not is_equal_approx(d3, 3.0625):
		print("FAIL: Hero damage scaling mismatch! d1=%f, d2=%f, d3=%f" % [d1, d2, d3])
		failed += 1
	else:
		print("PASS: Hero damage scaling matches Flutter exactly (1.0, 1.75, 3.0625)")

	# 3. Scrap calculations
	var scrap_norm = GameBalance.calculate_scrap_reward(10, 2) # (10*3) + (2*10) = 50
	if scrap_norm != 50:
		print("FAIL: Normal scrap mismatch: %d" % scrap_norm)
		failed += 1
	var scrap_chaos = GameBalance.calculate_chaos_scrap_reward(10, 2) # floor(50 * 1.10) = 55
	if scrap_chaos != 55:
		print("FAIL: Chaos scrap mismatch: %d" % scrap_chaos)
		failed += 1
	var scrap_br = GameBalance.calculate_boss_rush_scrap_reward(5) # min(50, 5*8 + 10) = 50
	if scrap_br != 50:
		print("FAIL: Boss Rush scrap mismatch: %d" % scrap_br)
		failed += 1
	print("PASS: Scrap formulas match Flutter exactly (Normal=50, Chaos=55, BossRush=50)")

	# 4. Hero definitions check
	var heroes = HeroDefinition.get_registry()
	if heroes.size() != 4:
		print("FAIL: Expected 4 heroes, got %d" % heroes.size())
		failed += 1
	var rm: HeroDefinition = heroes[HeroDefinition.HeroClass.RIFLEMAN]
	var sg: HeroDefinition = heroes[HeroDefinition.HeroClass.SHOTGUNNER]
	var sn: HeroDefinition = heroes[HeroDefinition.HeroClass.SNIPER]
	var hg: HeroDefinition = heroes[HeroDefinition.HeroClass.HEAVY_GUNNER]
	if rm.base_damage != 12.0 or sg.base_damage != 9.0 or sn.base_damage != 55.0 or hg.base_damage != 6.0:
		print("FAIL: Hero base damage mismatch")
		failed += 1
	if sg.projectile_count != 5 or sg.spread_angle != 0.38:
		print("FAIL: Shotgunner projectile count/spread mismatch")
		failed += 1
	print("PASS: 4 Hero definitions verified (Rifleman, Shotgunner, Sniper, Heavy Gunner)")

	# 5. Enemy definitions check
	var enemies = EnemyDefinition.get_registry()
	if enemies.size() != 6:
		print("FAIL: Expected 6 enemy types, got %d" % enemies.size())
		failed += 1
	var basic = enemies[EnemyDefinition.EnemyType.BASIC]
	var boss = enemies[EnemyDefinition.EnemyType.BOSS]
	var shielded = enemies[EnemyDefinition.EnemyType.SHIELDED]
	if basic.base_hp != 55.0 or boss.base_hp != 1200.0 or shielded.base_shield != 80.0:
		print("FAIL: Enemy HP/Shield mismatch")
		failed += 1
	if boss.charge_speed != 1.60 or boss.charge_duration != 1.2 or boss.charge_cooldown != 7.0:
		print("FAIL: Boss charge parameters mismatch")
		failed += 1
	print("PASS: 6 Enemy definitions verified (Basic, Runner, Tank, Swarm, Shielded, Boss)")

	# 6. Upgrade Cards pool
	var pool = UpgradeCard.get_pool()
	if pool.size() != 8:
		print("FAIL: Expected 8 upgrade cards, got %d" % pool.size())
		failed += 1
	else:
		print("PASS: 8 Upgrade Cards verified")

	# 7. Chaos Modifiers
	var mod_w2 = ChaosModifier.resolve_for_wave(2)
	var mod_w3 = ChaosModifier.resolve_for_wave(3)
	var mod_w8 = ChaosModifier.resolve_for_wave(8)
	if mod_w2.type != ChaosModifier.ChaosModifierType.RUSH_HOUR:
		print("FAIL: Wave 2 Chaos modifier should be RUSH_HOUR")
		failed += 1
	if mod_w3.type != ChaosModifier.ChaosModifierType.RAPID_FIRE:
		print("FAIL: Wave 3 Chaos modifier should be RAPID_FIRE")
		failed += 1
	if mod_w8.type != ChaosModifier.ChaosModifierType.GIANTS:
		print("FAIL: Wave 8 Chaos modifier should be GIANTS")
		failed += 1
	print("PASS: Chaos modifier sequence verified")

	# 8. Boss Rush rounds
	var r1 = BossRushRoundData.get_round(1)
	var r5 = BossRushRoundData.get_round(5)
	if r1.boss_coin_reward != 120 or r5.boss_coin_reward != 250 or r5.boss_hp_multiplier != 3.0:
		print("FAIL: Boss rush round data mismatch")
		failed += 1
	else:
		print("PASS: Boss rush round data verified")

	if failed == 0:
		print("ALL PHASE 1 PARITY CHECKS PASSED SUCCESSFULLY!")
	else:
		print("TOTAL FAILURES: %d" % failed)

	quit(failed)
