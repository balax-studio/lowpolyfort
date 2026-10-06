class_name BossRushRoundData
extends RefCounted

## Boss Rush Round Specifications.
## Source of truth: Flutter lib/models/game_mode_data.dart (Clauses 324–337).

var round_number: int = 1
var boss_hp_multiplier: float = 1.00
var boss_damage_multiplier: float = 1.00
var boss_speed_multiplier: float = 1.00
var boss_coin_reward: int = 120
var support_roster: Dictionary = {} # EnemyDefinition.EnemyType -> count

func _init(
	p_round: int,
	p_hp: float,
	p_dmg: float,
	p_spd: float,
	p_coin: int,
	p_support: Dictionary
) -> void:
	round_number = p_round
	boss_hp_multiplier = p_hp
	boss_damage_multiplier = p_dmg
	boss_speed_multiplier = p_spd
	boss_coin_reward = p_coin
	support_roster = p_support

static var _rounds: Array[BossRushRoundData] = []

static func get_rounds() -> Array[BossRushRoundData]:
	if _rounds.is_empty():
		_rounds = [
			BossRushRoundData.new(1, 1.00, 1.00, 1.00, 120, {}),
			BossRushRoundData.new(2, 1.35, 1.10, 1.00, 140, { EnemyDefinition.EnemyType.RUNNER: 4 }),
			BossRushRoundData.new(3, 1.75, 1.20, 1.05, 160, { EnemyDefinition.EnemyType.TANK: 2, EnemyDefinition.EnemyType.BASIC: 4 }),
			BossRushRoundData.new(4, 2.25, 1.35, 1.10, 180, { EnemyDefinition.EnemyType.SHIELDED: 3, EnemyDefinition.EnemyType.SWARM: 6 }),
			BossRushRoundData.new(5, 3.00, 1.50, 1.15, 250, { EnemyDefinition.EnemyType.TANK: 2, EnemyDefinition.EnemyType.SHIELDED: 2, EnemyDefinition.EnemyType.RUNNER: 6 }),
		]
	return _rounds

static func get_round(round_num: int) -> BossRushRoundData:
	var list = get_rounds()
	var idx = clampi(round_num - 1, 0, list.size() - 1)
	return list[idx]
