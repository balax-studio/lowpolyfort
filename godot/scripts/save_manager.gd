extends Node

## Persistent Save & Meta-Progression Manager.
## Source of truth: Flutter lib/services/save_system.dart & lib/models/player_save.dart.

signal save_updated()

const SAVE_PATH: String = "user://save_data.json"
const CURRENT_VERSION: int = 1

var save_file_path: String = SAVE_PATH

# Schema fields
var save_version: int = CURRENT_VERSION
var total_scrap: int = 0
var highest_wave: int = 1
var total_kills: int = 0
var total_bosses_killed: int = 0
var runs_played: int = 0
var tutorial_completed: bool = false

# Permanent Upgrades (0 to 5)
var perm_base_hp_level: int = 0
var perm_starting_coins_level: int = 0
var perm_damage_level: int = 0
var perm_attack_speed_level: int = 0
var perm_crit_level: int = 0
var perm_bounty_level: int = 0

# Settings
var master_volume: float = 1.0
var sfx_volume: float = 1.0
var music_volume: float = 1.0
var vibration_enabled: bool = true
var show_damage_numbers: bool = true
var language: String = "en"

# Announcements & Mode Unlocks
var announced_unit_unlocks: Array = []
var chaos_unlocked: bool = false
var boss_rush_unlocked: bool = false
var best_chaos_wave: int = 0
var best_boss_rush_round: int = 0

# Rewarded Ad timestamps (epoch ms)
var rewarded_ad_completion_timestamps: Array = []

func _ready() -> void:
	language = _detect_default_language()
	load_from_disk()

func _detect_default_language() -> String:
	var loc = OS.get_locale().to_lower()
	if loc.begins_with("tr"):
		return "tr"
	return "en"

func load_from_disk() -> bool:
	if not FileAccess.file_exists(save_file_path):
		save_to_disk()
		return false

	var file = FileAccess.open(save_file_path, FileAccess.READ)
	if file == null:
		return false

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var err = json.parse(json_text)
	if err != OK or not (json.data is Dictionary):
		return false

	var dict: Dictionary = json.data
	save_version = dict.get("save_version", CURRENT_VERSION)
	total_scrap = maxi(0, int(dict.get("total_scrap", 0)))
	highest_wave = maxi(1, int(dict.get("highest_wave", 1)))
	total_kills = maxi(0, int(dict.get("total_kills", 0)))
	total_bosses_killed = maxi(0, int(dict.get("total_bosses_killed", 0)))
	runs_played = maxi(0, int(dict.get("runs_played", 0)))
	tutorial_completed = bool(dict.get("tutorial_completed", false))

	perm_base_hp_level = clampi(int(dict.get("perm_base_hp_level", 0)), 0, GameBalance.MAX_PERM_UPGRADE_LEVEL)
	perm_starting_coins_level = clampi(int(dict.get("perm_starting_coins_level", 0)), 0, GameBalance.MAX_PERM_UPGRADE_LEVEL)
	perm_damage_level = clampi(int(dict.get("perm_damage_level", 0)), 0, GameBalance.MAX_PERM_UPGRADE_LEVEL)
	perm_attack_speed_level = clampi(int(dict.get("perm_attack_speed_level", 0)), 0, GameBalance.MAX_PERM_UPGRADE_LEVEL)
	perm_crit_level = clampi(int(dict.get("perm_crit_level", 0)), 0, GameBalance.MAX_PERM_UPGRADE_LEVEL)
	perm_bounty_level = clampi(int(dict.get("perm_bounty_level", 0)), 0, GameBalance.MAX_PERM_UPGRADE_LEVEL)

	master_volume = clampf(float(dict.get("master_volume", 1.0)), 0.0, 1.0)
	sfx_volume = clampf(float(dict.get("sfx_volume", 1.0)), 0.0, 1.0)
	music_volume = clampf(float(dict.get("music_volume", 1.0)), 0.0, 1.0)
	vibration_enabled = bool(dict.get("vibration_enabled", true))
	show_damage_numbers = bool(dict.get("show_damage_numbers", true))
	language = str(dict.get("language", _detect_default_language()))

	announced_unit_unlocks = Array(dict.get("announced_unit_unlocks", []))
	chaos_unlocked = bool(dict.get("chaos_unlocked", false))
	boss_rush_unlocked = bool(dict.get("boss_rush_unlocked", false))
	best_chaos_wave = maxi(0, int(dict.get("best_chaos_wave", 0)))
	best_boss_rush_round = clampi(int(dict.get("best_boss_rush_round", 0)), 0, 5)

	rewarded_ad_completion_timestamps = Array(dict.get("rewarded_ad_completion_timestamps", []))

	# Re-check mode unlock milestones from highest_wave
	if highest_wave > 5:
		chaos_unlocked = true
	if highest_wave > 10:
		boss_rush_unlocked = true

	save_updated.emit()
	return true

func save_to_disk() -> bool:
	var dict = {
		"save_version": CURRENT_VERSION,
		"total_scrap": total_scrap,
		"highest_wave": highest_wave,
		"total_kills": total_kills,
		"total_bosses_killed": total_bosses_killed,
		"runs_played": runs_played,
		"tutorial_completed": tutorial_completed,
		"perm_base_hp_level": perm_base_hp_level,
		"perm_starting_coins_level": perm_starting_coins_level,
		"perm_damage_level": perm_damage_level,
		"perm_attack_speed_level": perm_attack_speed_level,
		"perm_crit_level": perm_crit_level,
		"perm_bounty_level": perm_bounty_level,
		"master_volume": master_volume,
		"sfx_volume": sfx_volume,
		"music_volume": music_volume,
		"vibration_enabled": vibration_enabled,
		"show_damage_numbers": show_damage_numbers,
		"language": language,
		"announced_unit_unlocks": announced_unit_unlocks,
		"chaos_unlocked": chaos_unlocked,
		"boss_rush_unlocked": boss_rush_unlocked,
		"best_chaos_wave": best_chaos_wave,
		"best_boss_rush_round": best_boss_rush_round,
		"rewarded_ad_completion_timestamps": rewarded_ad_completion_timestamps
	}

	var json_str = JSON.stringify(dict, "\t")
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(json_str)
	file.close()
	save_updated.emit()
	return true

func reset_all_progress() -> void:
	reset_all()

func reset_all() -> void:
	total_scrap = 0
	highest_wave = 1
	total_kills = 0
	total_bosses_killed = 0
	runs_played = 0
	tutorial_completed = false
	perm_base_hp_level = 0
	perm_starting_coins_level = 0
	perm_damage_level = 0
	perm_attack_speed_level = 0
	perm_crit_level = 0
	perm_bounty_level = 0
	announced_unit_unlocks.clear()
	chaos_unlocked = false
	boss_rush_unlocked = false
	best_chaos_wave = 0
	best_boss_rush_round = 0
	rewarded_ad_completion_timestamps.clear()
	save_to_disk()

func get_unlocked_hero_classes() -> Array[HeroDefinition.HeroClass]:
	var list: Array[HeroDefinition.HeroClass] = [HeroDefinition.HeroClass.RIFLEMAN]
	if highest_wave >= GameBalance.UNLOCK_WAVE_SHOTGUNNER:
		list.append(HeroDefinition.HeroClass.SHOTGUNNER)
	if highest_wave >= GameBalance.UNLOCK_WAVE_SNIPER:
		list.append(HeroDefinition.HeroClass.SNIPER)
	if highest_wave >= GameBalance.UNLOCK_WAVE_HEAVY_GUNNER:
		list.append(HeroDefinition.HeroClass.HEAVY_GUNNER)
	return list

func is_hero_unlocked(h_class: HeroDefinition.HeroClass) -> bool:
	return get_unlocked_hero_classes().has(h_class)

func get_completed_ads_in_rolling_24h() -> int:
	var now_ms = Time.get_unix_time_from_system() * 1000.0
	var cutoff_ms = now_ms - (24.0 * 60.0 * 60.0 * 1000.0)
	var count = 0
	for t in rewarded_ad_completion_timestamps:
		if float(t) >= cutoff_ms:
			count += 1
	return count

func record_ad_completion(timestamp_ms: int = -1) -> void:
	if timestamp_ms == -1:
		timestamp_ms = int(Time.get_unix_time_from_system() * 1000.0)
	var cutoff_ms = float(timestamp_ms) - (24.0 * 60.0 * 60.0 * 1000.0)
	var updated = []
	for t in rewarded_ad_completion_timestamps:
		if float(t) >= cutoff_ms:
			updated.append(t)
	updated.append(timestamp_ms)
	rewarded_ad_completion_timestamps = updated
	save_to_disk()
