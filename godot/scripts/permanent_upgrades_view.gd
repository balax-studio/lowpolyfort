class_name PermanentUpgradesView
extends Control

## Permanent Meta-Progression Shop.
## Source of truth: Flutter lib/ui/upgrades/permanent_upgrades_view.dart (Clauses 105–112, 646, 647).

signal closed()

@onready var scrap_badge_label: Label = $SafeContainer/VBox/Header/ScrapBadge/Margin/Label
@onready var back_button: Button = $SafeContainer/VBox/BackButton
@onready var perks_container: VBoxContainer = $SafeContainer/VBox/Scroll/PerksContainer

func _ready() -> void:
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	refresh_shop()

func open() -> void:
	refresh_shop()
	visible = true

func refresh_shop() -> void:
	if scrap_badge_label:
		scrap_badge_label.text = "%d SCRAP ⚙️" % SaveManager.total_scrap

	_setup_perk_card("BaseArmorCard", "BASE ARMOR", "+50 Starting Base HP per level", SaveManager.perm_base_hp_level, "base_armor")
	_setup_perk_card("StartingCashCard", "STARTING CASH", "+10 Starting Coins each deployment", SaveManager.perm_starting_coins_level, "starting_cash")
	_setup_perk_card("UnitTrainingCard", "UNIT TRAINING", "+2.0% Squad damage per level", SaveManager.perm_damage_level, "unit_training")
	_setup_perk_card("RapidTrainingCard", "RAPID TRAINING", "+1.5% Squad attack speed per level", SaveManager.perm_attack_speed_level, "rapid_training")
	_setup_perk_card("LuckCard", "LUCK", "+0.5% Critical strike chance per level", SaveManager.perm_crit_level, "luck")
	_setup_perk_card("BountyCard", "BOUNTY", "+2.0% Extra coin rewards from fallen foes", SaveManager.perm_bounty_level, "bounty")

func _setup_perk_card(card_name: String, title: String, desc: String, current_level: int, perk_key: String) -> void:
	if perks_container == null:
		return
	var card = perks_container.get_node_or_null(card_name)
	if card == null:
		return

	var is_max = current_level >= GameBalance.MAX_PERM_UPGRADE_LEVEL
	var cost = 0 if is_max else GameBalance.get_permanent_upgrade_cost(current_level)
	var can_afford = not is_max and (SaveManager.total_scrap >= cost)

	var title_lbl: Label = card.get_node_or_null("Margin/HBox/InfoVBox/HeaderRow/TitleLabel")
	var level_lbl: Label = card.get_node_or_null("Margin/HBox/InfoVBox/HeaderRow/LevelLabel")
	var desc_lbl: Label = card.get_node_or_null("Margin/HBox/InfoVBox/DescLabel")
	var buy_btn: Button = card.get_node_or_null("Margin/HBox/BuyButton")
	var buy_btn_label: Label = card.get_node_or_null("Margin/HBox/BuyButton/Label")

	if title_lbl: title_lbl.text = title
	if desc_lbl: desc_lbl.text = desc

	if level_lbl:
		if is_max:
			level_lbl.text = "LVL 5 (MAX)"
			level_lbl.modulate = Color(0.4, 0.85, 0.45) # Lime
		else:
			level_lbl.text = "LVL %d" % current_level
			level_lbl.modulate = Color(0.75, 0.45, 0.95) # Purple

	if buy_btn and buy_btn_label:
		if is_max:
			buy_btn_label.text = "MAX"
			buy_btn.disabled = true
		else:
			buy_btn_label.text = "%d SCRAP" % cost
			buy_btn.disabled = not can_afford

		# Disconnect previous connections if any
		for conn in buy_btn.pressed.get_connections():
			buy_btn.pressed.disconnect(conn.callable)
		buy_btn.pressed.connect(_on_perk_buy.bind(perk_key))

func _on_perk_buy(perk_key: String) -> void:
	var current_level = 0
	match perk_key:
		"base_armor": current_level = SaveManager.perm_base_hp_level
		"starting_cash": current_level = SaveManager.perm_starting_coins_level
		"unit_training": current_level = SaveManager.perm_damage_level
		"rapid_training": current_level = SaveManager.perm_attack_speed_level
		"luck": current_level = SaveManager.perm_crit_level
		"bounty": current_level = SaveManager.perm_bounty_level

	if current_level >= GameBalance.MAX_PERM_UPGRADE_LEVEL:
		return

	var cost = GameBalance.get_permanent_upgrade_cost(current_level)
	if SaveManager.total_scrap < cost:
		return

	SaveManager.total_scrap -= cost
	match perk_key:
		"base_armor": SaveManager.perm_base_hp_level += 1
		"starting_cash": SaveManager.perm_starting_coins_level += 1
		"unit_training": SaveManager.perm_damage_level += 1
		"rapid_training": SaveManager.perm_attack_speed_level += 1
		"luck": SaveManager.perm_crit_level += 1
		"bounty": SaveManager.perm_bounty_level += 1

	SaveManager.save_to_disk()
	refresh_shop()

func _on_back_pressed() -> void:
	visible = false
	closed.emit()
