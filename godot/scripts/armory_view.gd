class_name ArmoryView
extends Control

## Unit Codex / Armory Showcase.
## Source of truth: Flutter lib/ui/armory/armory_view.dart (Clauses 117, 118).

signal closed()

@onready var best_wave_label: Label = $SafeContainer/VBox/Header/BestWaveBadge/Margin/Label
@onready var back_button: Button = $SafeContainer/VBox/BackButton
@onready var cards_container: VBoxContainer = $SafeContainer/VBox/Scroll/CardsContainer

func _ready() -> void:
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	refresh_armory()

func open() -> void:
	refresh_armory()
	visible = true

func refresh_armory() -> void:
	if best_wave_label:
		best_wave_label.text = "BEST WAVE: %d" % SaveManager.highest_wave

	_setup_card("RiflemanCard", HeroDefinition.HeroClass.RIFLEMAN)
	_setup_card("ShotgunnerCard", HeroDefinition.HeroClass.SHOTGUNNER)
	_setup_card("SniperCard", HeroDefinition.HeroClass.SNIPER)
	_setup_card("HeavyGunnerCard", HeroDefinition.HeroClass.HEAVY_GUNNER)

func _setup_card(card_name: String, hero_class: HeroDefinition.HeroClass) -> void:
	if cards_container == null:
		return
	var card = cards_container.get_node_or_null(card_name)
	if card == null:
		return

	var def = HeroDefinition.get_definition(hero_class)
	if def == null:
		return

	var is_unlocked = SaveManager.is_hero_unlocked(hero_class)

	var title_lbl: Label = card.get_node_or_null("Margin/HBox/InfoVBox/HeaderRow/TitleLabel")
	var status_badge: PanelContainer = card.get_node_or_null("Margin/HBox/InfoVBox/HeaderRow/StatusBadge")
	var status_lbl: Label = card.get_node_or_null("Margin/HBox/InfoVBox/HeaderRow/StatusBadge/Margin/Label")
	var desc_lbl: Label = card.get_node_or_null("Margin/HBox/InfoVBox/DescLabel")
	var icon_box: PanelContainer = card.get_node_or_null("Margin/HBox/IconBox")
	var icon_lbl: Label = card.get_node_or_null("Margin/HBox/IconBox/Label")

	if title_lbl:
		title_lbl.text = def.name.to_upper()
	if status_lbl and status_badge:
		if is_unlocked:
			status_lbl.text = "UNLOCKED"
			status_badge.self_modulate = Color(0.4, 0.85, 0.45) # Lime
		else:
			status_lbl.text = "WAVE %d" % def.unlock_wave_requirement
			status_badge.self_modulate = Color(0.92, 0.22, 0.22) # Red

	if desc_lbl:
		if is_unlocked:
			desc_lbl.text = def.role_description
		else:
			desc_lbl.text = "SURVIVE TO WAVE %d TO DEPLOY THIS SPECIALIST." % def.unlock_wave_requirement

	if icon_box:
		icon_box.self_modulate = def.theme_color if is_unlocked else Color(0.3, 0.35, 0.4)
	if icon_lbl:
		icon_lbl.text = "🔒" if not is_unlocked else _get_hero_emoji(hero_class)

	# Stats
	var stats_box = card.get_node_or_null("Margin/HBox/InfoVBox/StatsBox")
	if stats_box:
		stats_box.visible = is_unlocked
		if is_unlocked:
			var dmg_lbl: Label = stats_box.get_node_or_null("DmgLabel")
			var spd_lbl: Label = stats_box.get_node_or_null("SpdLabel")
			var rng_lbl: Label = stats_box.get_node_or_null("RngLabel")
			if dmg_lbl: dmg_lbl.text = "DMG: %d" % int(def.base_damage)
			if spd_lbl: spd_lbl.text = "SPD: %.1f/s" % def.attacks_per_second
			if rng_lbl: rng_lbl.text = "RNG: %.1fm" % def.range_meters

func _get_hero_emoji(h_class: HeroDefinition.HeroClass) -> String:
	match h_class:
		HeroDefinition.HeroClass.RIFLEMAN: return "🎯"
		HeroDefinition.HeroClass.SHOTGUNNER: return "💥"
		HeroDefinition.HeroClass.SNIPER: return "🔭"
		HeroDefinition.HeroClass.HEAVY_GUNNER: return "⚡"
	return "🛡️"

func _on_back_pressed() -> void:
	visible = false
	closed.emit()
