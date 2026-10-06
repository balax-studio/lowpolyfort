class_name UpgradeSelectionDialog
extends Control

## Neo-Brutalist 3-Card Roguelite Upgrade Selection Dialog.
## Source of truth: Flutter lib/ui/upgrade_menu/upgrade_selection_dialog.dart (Clause 88).

signal upgrade_selected(card: UpgradeCard)

@onready var card_1_btn: Button = $CardContainer/VBoxContainer/CardsRow/Card1
@onready var card_2_btn: Button = $CardContainer/VBoxContainer/CardsRow/Card2
@onready var card_3_btn: Button = $CardContainer/VBoxContainer/CardsRow/Card3

var current_cards: Array[UpgradeCard] = []

func _ready() -> void:
	add_to_group("upgrade_dialog")
	visible = false
	card_1_btn.pressed.connect(func(): _on_card_picked(0))
	card_2_btn.pressed.connect(func(): _on_card_picked(1))
	card_3_btn.pressed.connect(func(): _on_card_picked(2))

func open_draft() -> void:
	var pool = UpgradeCard.get_pool().duplicate()
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	pool.shuffle()
	
	current_cards.clear()
	for i in range(mini(3, pool.size())):
		current_cards.append(pool[i])
	
	_render_card(card_1_btn, current_cards[0])
	_render_card(card_2_btn, current_cards[1])
	_render_card(card_3_btn, current_cards[2])
	
	visible = true

func _render_card(btn: Button, card: UpgradeCard) -> void:
	var title_lbl: Label = btn.get_node("VBox/TitleLabel")
	var desc_lbl: Label = btn.get_node("VBox/DescLabel")
	var rarity_lbl: Label = btn.get_node("VBox/RarityBadge/Label")
	
	if title_lbl: title_lbl.text = card.title
	if desc_lbl: desc_lbl.text = card.description
	if rarity_lbl:
		rarity_lbl.text = card.get_rarity_label()
		rarity_lbl.modulate = card.get_rarity_color()

func _on_card_picked(index: int) -> void:
	if index >= 0 and index < current_cards.size():
		var picked = current_cards[index]
		GameManager.apply_upgrade(picked)
		upgrade_selected.emit(picked)
	visible = false
