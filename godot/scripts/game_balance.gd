class_name GameBalance
extends RefCounted

## Central game balance parameters and dynamic scaling formulas.
## Source of truth: Flutter lib/constants/game_balance.dart (Clauses 51–177, 634–643).

# --- BASE & DEFENSE (Clause 56) ---
const BASE_STARTING_HP: float = 1000.0
const BASE_DAMAGE_FLASH_DURATION: float = 0.2

# --- ECONOMY (Clauses 56, 57) ---
const STARTING_COINS: int = 150
const UNIT_BASE_COST: int = 50
const UNIT_COST_MULTIPLIER: float = 1.10

static func get_unit_cost(purchase_count: int) -> int:
	var raw: float = float(UNIT_BASE_COST) * pow(UNIT_COST_MULTIPLIER, float(purchase_count))
	# Epsilon correction prevents IEEE-754 binary floating drift (e.g. 55.00000000000001) from bumping ceil
	return int(ceil(snappedf(raw, 0.001)))

# --- PROGRESSION & METAGAME (Clauses 69, 86, 104, 115) ---
const MAX_UNIT_LEVEL: int = 8
const BOSS_INTERVAL: int = 5
const UPGRADE_INTERVAL: int = 3
const SCRAP_PER_WAVE: int = 3
const SCRAP_PER_BOSS: int = 10

static func calculate_scrap_reward(wave_reached: int, bosses_defeated: int) -> int:
	# Clause 104: (waveReached * 3) + (bossesDefeated * 10)
	return (wave_reached * SCRAP_PER_WAVE) + (bosses_defeated * SCRAP_PER_BOSS)

# --- GAME MODES BALANCE (Clauses 320, 326, 329, 343, 347, 348) ---
const CHAOS_SCRAP_MULTIPLIER: float = 1.10
const BOSS_RUSH_STARTING_COINS: int = 300
const BOSS_RUSH_TOTAL_ROUNDS: int = 5
const BOSS_RUSH_INITIAL_PREP_SECONDS: float = 8.0
const BOSS_RUSH_INTER_ROUND_PREP_SECONDS: float = 3.0
const BOSS_RUSH_SCRAP_PER_BOSS: int = 8
const BOSS_RUSH_COMPLETION_BONUS: int = 10
const BOSS_RUSH_MAX_SCRAP: int = 50

static func calculate_chaos_scrap_reward(wave_reached: int, bosses_defeated: int) -> int:
	var base_scrap: int = calculate_scrap_reward(wave_reached, bosses_defeated)
	return int(floor(float(base_scrap) * CHAOS_SCRAP_MULTIPLIER))

static func calculate_boss_rush_scrap_reward(bosses_defeated: int) -> int:
	var base_scrap: int = bosses_defeated * BOSS_RUSH_SCRAP_PER_BOSS
	var bonus: int = BOSS_RUSH_COMPLETION_BONUS if bosses_defeated >= BOSS_RUSH_TOTAL_ROUNDS else 0
	return mini(BOSS_RUSH_MAX_SCRAP, base_scrap + bonus)

# Permanent upgrade costs by tier (Clauses 646, 647)
const MAX_PERM_UPGRADE_LEVEL: int = 5
const PERM_UPGRADE_COSTS: Array[int] = [25, 50, 100, 175, 300]

static func get_permanent_upgrade_cost(current_level: int) -> int:
	if current_level < PERM_UPGRADE_COSTS.size():
		return PERM_UPGRADE_COSTS[current_level]
	return PERM_UPGRADE_COSTS[-1]

# Unit unlock milestones (Clause 115)
const UNLOCK_WAVE_RIFLEMAN: int = 1
const UNLOCK_WAVE_SHOTGUNNER: int = 5
const UNLOCK_WAVE_SNIPER: int = 10
const UNLOCK_WAVE_HEAVY_GUNNER: int = 15

# --- WAVES & PACING (Clauses 71, 72, 83, 84, 85, 634-643) ---
const MAX_ENEMIES_ALIVE: int = 40
const WAVE_COUNTDOWN_SECONDS: float = 1.5
const WAVE_SHORT_BANNER_SECONDS: float = 0.8
const WAVE_CLEAR_INTERMISSION_SECONDS: float = 1.2
const SPAWN_INTERVAL_START: float = 0.85
const SPAWN_INTERVAL_MIN: float = 0.35

static func get_wave_spawn_interval(wave: int) -> float:
	# Clause 637: max(0.85 - 0.02 * (wave - 1), 0.35)
	return maxf(SPAWN_INTERVAL_START - (0.02 * float(wave - 1)), SPAWN_INTERVAL_MIN)

static func get_wave_enemy_count(wave: int) -> int:
	# Clause 634: min(5 + wave * 2, 45)
	return mini(5 + (wave * 2), 45)

static func get_wave_enemy_hp_multiplier(wave: int) -> float:
	# Clauses 638–641: 3-tier HP multiplier capped at 8.00x
	if wave <= 20:
		return 1.0 + (float(wave) * 0.12)
	elif wave <= 40:
		return 3.40 + (float(wave - 20) * 0.08)
	else:
		return minf(5.00 + (float(wave - 40) * 0.05), 8.00)

static func get_wave_enemy_damage_multiplier(wave: int) -> float:
	# Clause 642: 3-tier Base damage multiplier capped at 3.50x
	if wave <= 20:
		return 1.0 + (float(wave) * 0.05)
	elif wave <= 40:
		return 2.00 + (float(wave - 20) * 0.035)
	else:
		return minf(2.70 + (float(wave - 40) * 0.02), 3.50)

static func get_wave_enemy_speed_multiplier(_wave: int) -> float:
	# Clause 643: Normal mode enemy movement speed does not scale with wave
	return 1.0

# --- TIMERS & COMBAT (Clauses 65, 68, 89) ---
const TARGET_SCAN_INTERVAL: float = 0.16
const MERGE_DURATION_SECONDS: float = 0.50
const DRAG_SPRING_RETURN_DURATION_SECONDS: float = 0.20
const FLOATING_TEXT_DURATION_SECONDS: float = 0.85
const MAX_CRIT_CHANCE_CAP: float = 0.75

# Unit scaling multipliers (Clause 65)
static func get_hero_damage_multiplier(level: int) -> float:
	return pow(1.75, float(level - 1))

static func get_hero_attack_speed_multiplier(level: int) -> float:
	return pow(1.04, float(level - 1))

static func get_hero_range_multiplier(level: int) -> float:
	return pow(1.02, float(level - 1))
