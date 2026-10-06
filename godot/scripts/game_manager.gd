extends Node

const RewardedAdService = preload("res://scripts/rewarded_ad_service.gd")

## Core Game Manager Autoload Singleton for Poly Fort Godot 4 Vertical Slice.
## Manages game state, coins economy, Base HP, unit purchase, and run lifecycle.

signal coins_changed(amount: int)
signal base_hp_changed(current_hp: float, max_hp: float)
signal wave_changed(wave_num: int)
signal game_over_triggered()
signal game_restarted()
signal boss_warning_triggered(wave_num: int)
signal new_mode_unlocked(mode_name: String)
signal tutorial_step_changed(step: int)
signal second_chance_offered()

enum GameState { MENU, PLAYING, WAVE_BREAK, UPGRADE_SELECTION, GAME_OVER, TUTORIAL }
enum GameMode { NORMAL, CHAOS, BOSS_RUSH }

var state: GameState = GameState.MENU
var current_mode: GameMode = GameMode.NORMAL
var tutorial_step: int = 0 # 0 = not active, 1 = Buy 1st, 2 = Buy 2nd, 3 = Merge, 4 = Ready
var coins: int = 150
var purchase_count: int = 0
var base_hp: float = 1000.0
var max_base_hp: float = 1000.0
var current_wave: int = 1

# Rewarded Ads Monetization State (Clauses 426–444)
var run_rewarded_count: int = 0
var last_rewarded_ad_completed_timestamp: float = -1.0
var supply_drop_used_this_run: bool = false
var second_chance_used_this_run: bool = false
var extra_scrap_used_this_run: bool = false
var extra_scrap_awarded_this_run: bool = false
var is_rewarded_ad_showing: bool = false

# Run Statistics (Clauses 104, 320, 343)
var kills_this_run: int = 0
var bosses_defeated_this_run: int = 0
var scrap_earned_this_run: int = 0
var is_new_high_score: bool = false
var active_chaos_modifier: ChaosModifier = null

# Roguelite Upgrade bonuses
var upgrade_damage_bonus: float = 0.0
var upgrade_aspd_bonus: float = 0.0
var upgrade_range_bonus: float = 0.0
var upgrade_crit_bonus: float = 0.0
var upgrade_bounty_bonus: float = 0.0
var has_armor_piercing_upgrade: bool = false

var board_ref: Node = null
var base_ref: Node = null

func _ready() -> void:
	reset_run()

func reset_run() -> void:
	if not SaveManager.tutorial_completed and current_mode == GameMode.NORMAL:
		state = GameState.TUTORIAL
		tutorial_step = 1
	else:
		state = GameState.PLAYING
		tutorial_step = 0
	coins = GameBalance.BOSS_RUSH_STARTING_COINS if current_mode == GameMode.BOSS_RUSH else GameBalance.STARTING_COINS
	purchase_count = 0
	base_hp = GameBalance.BASE_STARTING_HP
	max_base_hp = GameBalance.BASE_STARTING_HP
	current_wave = 1
	kills_this_run = 0
	bosses_defeated_this_run = 0
	scrap_earned_this_run = 0
	is_new_high_score = false
	run_rewarded_count = 0
	supply_drop_used_this_run = false
	second_chance_used_this_run = false
	extra_scrap_used_this_run = false
	extra_scrap_awarded_this_run = false
	is_rewarded_ad_showing = false
	upgrade_damage_bonus = 0.0
	upgrade_aspd_bonus = 0.0
	upgrade_range_bonus = 0.0
	upgrade_crit_bonus = 0.0
	upgrade_bounty_bonus = 0.0
	has_armor_piercing_upgrade = false
	active_chaos_modifier = null
	coins_changed.emit(coins)
	base_hp_changed.emit(base_hp, max_base_hp)
	wave_changed.emit(current_wave)
	game_restarted.emit()
	tutorial_step_changed.emit(tutorial_step)

func has_armor_piercing() -> bool:
	return has_armor_piercing_upgrade

func apply_upgrade(card: UpgradeCard) -> void:
	match card.type:
		UpgradeCard.UpgradeType.HEAVY_AMMO:
			upgrade_damage_bonus += card.value_multiplier
		UpgradeCard.UpgradeType.RAPID_FIRE:
			upgrade_aspd_bonus += card.value_multiplier
		UpgradeCard.UpgradeType.LONG_BARRELS:
			upgrade_range_bonus += card.value_multiplier
		UpgradeCard.UpgradeType.CRITICAL_TRAINING:
			upgrade_crit_bonus += card.value_multiplier
		UpgradeCard.UpgradeType.FORTIFIED_BASE:
			max_base_hp += card.value_multiplier
			base_hp += card.value_multiplier
			base_hp_changed.emit(base_hp, max_base_hp)
		UpgradeCard.UpgradeType.FIELD_REPAIR:
			var heal = max_base_hp * card.value_multiplier
			base_hp = minf(max_base_hp, base_hp + heal)
			base_hp_changed.emit(base_hp, max_base_hp)
		UpgradeCard.UpgradeType.BOUNTY_HUNTER:
			upgrade_bounty_bonus += card.value_multiplier
		UpgradeCard.UpgradeType.ARMOR_PIERCING:
			has_armor_piercing_upgrade = true

func get_unit_cost() -> int:
	return GameBalance.get_unit_cost(purchase_count)

func can_afford_unit() -> bool:
	return coins >= get_unit_cost()

func add_coins(amount: int) -> void:
	coins += amount
	coins_changed.emit(coins)

func spend_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		coins_changed.emit(coins)
		return true
	return false

func try_purchase_unit() -> bool:
	if state == GameState.GAME_OVER:
		return false
	if not can_afford_unit():
		return false
	if board_ref == null:
		return false

	var empty_slot = board_ref.get_first_empty_slot()
	if empty_slot == null:
		return false # Board full

	var cost = get_unit_cost()
	if spend_coins(cost):
		purchase_count += 1
		var unlocked = SaveManager.get_unlocked_hero_classes()
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		var rolled_class = HeroDefinition.roll_unit_with_rng(rng, unlocked)
		board_ref.spawn_unit_on_slot(empty_slot, 1, rolled_class)

		# Check tutorial progression (Clause 55, 143)
		if tutorial_step == 1:
			advance_tutorial_step(2)
		elif tutorial_step == 2:
			advance_tutorial_step(3)

		return true
	return false

func advance_tutorial_step(new_step: int) -> void:
	tutorial_step = new_step
	if tutorial_step > 3:
		SaveManager.tutorial_completed = true
		SaveManager.save_to_disk()
		state = GameState.PLAYING
	tutorial_step_changed.emit(tutorial_step)

func damage_base(amount: float) -> void:
	if state == GameState.GAME_OVER:
		return
	base_hp = max(0.0, base_hp - amount)
	base_hp_changed.emit(base_hp, max_base_hp)

	if base_ref != null and base_ref.has_method("trigger_damage_flash"):
		base_ref.trigger_damage_flash()

	if base_hp <= 0.0:
		if can_offer_second_chance():
			second_chance_offered.emit()
		else:
			trigger_game_over()

func on_enemy_killed(coin_reward: int) -> void:
	kills_this_run += 1
	var bounty_mult = 1.0 + upgrade_bounty_bonus
	var final_coins = int(round(float(coin_reward) * bounty_mult))
	add_coins(final_coins)

func on_boss_defeated(coin_reward: int) -> void:
	bosses_defeated_this_run += 1
	kills_this_run += 1
	var bounty_mult = 1.0 + upgrade_bounty_bonus
	var final_coins = int(round(float(coin_reward) * bounty_mult))
	add_coins(final_coins)

	# Mode unlock milestones evaluated in NORMAL mode (Clauses 283–288)
	if current_mode == GameMode.NORMAL:
		if current_wave == 5 and not SaveManager.chaos_unlocked:
			SaveManager.chaos_unlocked = true
			SaveManager.save_to_disk()
			new_mode_unlocked.emit("CHAOS")
		elif current_wave == 10 and not SaveManager.boss_rush_unlocked:
			SaveManager.boss_rush_unlocked = true
			SaveManager.save_to_disk()
			new_mode_unlocked.emit("BOSS RUSH")

func trigger_game_over() -> void:
	state = GameState.GAME_OVER

	# Calculate scrap based on mode (Clauses 104, 320, 343)
	if current_mode == GameMode.NORMAL:
		scrap_earned_this_run = GameBalance.calculate_scrap_reward(current_wave, bosses_defeated_this_run)
		is_new_high_score = current_wave > SaveManager.highest_wave
		if current_wave > SaveManager.highest_wave:
			SaveManager.highest_wave = current_wave
	elif current_mode == GameMode.CHAOS:
		scrap_earned_this_run = GameBalance.calculate_chaos_scrap_reward(current_wave, bosses_defeated_this_run)
		is_new_high_score = current_wave > SaveManager.best_chaos_wave
		if current_wave > SaveManager.best_chaos_wave:
			SaveManager.best_chaos_wave = current_wave
	else:
		scrap_earned_this_run = GameBalance.calculate_boss_rush_scrap_reward(bosses_defeated_this_run)
		is_new_high_score = bosses_defeated_this_run > SaveManager.best_boss_rush_round
		if bosses_defeated_this_run > SaveManager.best_boss_rush_round:
			SaveManager.best_boss_rush_round = bosses_defeated_this_run

	SaveManager.total_scrap += scrap_earned_this_run
	SaveManager.total_kills += kills_this_run
	SaveManager.total_bosses_killed += bosses_defeated_this_run
	SaveManager.runs_played += 1
	SaveManager.save_to_disk()

	game_over_triggered.emit()
	if base_ref != null and base_ref.has_method("trigger_destruction"):
		base_ref.trigger_destruction()

func trigger_boss_rush_victory() -> void:
	state = GameState.GAME_OVER
	bosses_defeated_this_run = GameBalance.BOSS_RUSH_TOTAL_ROUNDS
	scrap_earned_this_run = GameBalance.calculate_boss_rush_scrap_reward(5)
	is_new_high_score = 5 > SaveManager.best_boss_rush_round
	if is_new_high_score:
		SaveManager.best_boss_rush_round = 5

	SaveManager.total_scrap += scrap_earned_this_run
	SaveManager.total_kills += kills_this_run
	SaveManager.total_bosses_killed += bosses_defeated_this_run
	SaveManager.runs_played += 1
	SaveManager.save_to_disk()

	game_over_triggered.emit()

func is_global_cooldown_expired() -> bool:
	if last_rewarded_ad_completed_timestamp < 0:
		return true
	return (Time.get_unix_time_from_system() - last_rewarded_ad_completed_timestamp) >= RewardedAdService.REWARDED_GLOBAL_COOLDOWN_SECONDS

func can_offer_supply_drop() -> bool:
	if SaveManager.highest_wave < RewardedAdService.UNLOCK_WAVE_MILESTONE or not SaveManager.tutorial_completed:
		return false
	if not RewardedAdService.is_ad_ready():
		return false
	if SaveManager.get_completed_ads_in_rolling_24h() >= RewardedAdService.REWARDED_DAILY_CAP:
		return false
	if run_rewarded_count >= RewardedAdService.MAX_REWARDED_PER_RUN:
		return false
	if not is_global_cooldown_expired():
		return false
	if supply_drop_used_this_run:
		return false
	if coins >= get_unit_cost():
		return false
	if board_ref != null and board_ref.get_first_empty_slot() == null:
		return false
	return true

func can_offer_second_chance() -> bool:
	if SaveManager.highest_wave < RewardedAdService.UNLOCK_WAVE_MILESTONE or not SaveManager.tutorial_completed:
		return false
	if not RewardedAdService.is_ad_ready():
		return false
	if SaveManager.get_completed_ads_in_rolling_24h() >= RewardedAdService.REWARDED_DAILY_CAP:
		return false
	if run_rewarded_count >= RewardedAdService.MAX_REWARDED_PER_RUN:
		return false
	if not is_global_cooldown_expired():
		return false
	if second_chance_used_this_run:
		return false
	if current_mode == GameMode.BOSS_RUSH:
		return bosses_defeated_this_run < 5
	return current_wave >= 3

func can_offer_extra_scrap() -> bool:
	if SaveManager.highest_wave < RewardedAdService.UNLOCK_WAVE_MILESTONE:
		return false
	if not RewardedAdService.is_ad_ready():
		return false
	if SaveManager.get_completed_ads_in_rolling_24h() >= RewardedAdService.REWARDED_DAILY_CAP:
		return false
	if run_rewarded_count >= RewardedAdService.MAX_REWARDED_PER_RUN:
		return false
	if not is_global_cooldown_expired():
		return false
	if extra_scrap_used_this_run:
		return false
	if scrap_earned_this_run <= 0:
		return false
	return true

func claim_supply_drop() -> void:
	if not can_offer_supply_drop() or is_rewarded_ad_showing:
		return
	var pending_coins = get_unit_cost()
	is_rewarded_ad_showing = true
	RewardedAdService.show_ad(
		RewardedAdService.RewardedPlacement.SUPPLY_DROP,
		func():
			add_coins(pending_coins)
			supply_drop_used_this_run = true
			run_rewarded_count += 1
			last_rewarded_ad_completed_timestamp = Time.get_unix_time_from_system()
			SaveManager.record_ad_completion()
	)
	is_rewarded_ad_showing = false

func claim_second_chance() -> void:
	if not can_offer_second_chance() or is_rewarded_ad_showing:
		return
	is_rewarded_ad_showing = true
	RewardedAdService.show_ad(
		RewardedAdService.RewardedPlacement.SECOND_CHANCE,
		func():
			base_hp = ceil(max_base_hp * RewardedAdService.SECOND_CHANCE_HP_PERCENT)
			base_hp_changed.emit(base_hp, max_base_hp)
			state = GameState.PLAYING
			second_chance_used_this_run = true
			run_rewarded_count += 1
			last_rewarded_ad_completed_timestamp = Time.get_unix_time_from_system()
			SaveManager.record_ad_completion()
	)
	is_rewarded_ad_showing = false

func dismiss_second_chance() -> void:
	second_chance_used_this_run = true
	trigger_game_over()

func claim_extra_scrap() -> void:
	if not can_offer_extra_scrap() or is_rewarded_ad_showing:
		return
	is_rewarded_ad_showing = true
	RewardedAdService.show_ad(
		RewardedAdService.RewardedPlacement.EXTRA_SCRAP,
		func():
			SaveManager.total_scrap += scrap_earned_this_run
			SaveManager.save_to_disk()
			extra_scrap_used_this_run = true
			extra_scrap_awarded_this_run = true
			run_rewarded_count += 1
			last_rewarded_ad_completed_timestamp = Time.get_unix_time_from_system()
			SaveManager.record_ad_completion()
	)
	is_rewarded_ad_showing = false



