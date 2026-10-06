class_name TutorialOverlay
extends Control

## Interactive Guided Tutorial Overlay for fresh players.
## Source of truth: Flutter lib/ui/tutorial/tutorial_overlay.dart (Clauses 55, 143, 1086–1088).

const AppLocalization = preload("res://scripts/localization.gd")

@onready var banner_panel: PanelContainer = $BannerContainer/BannerPanel
@onready var banner_container: Control = $BannerContainer
@onready var title_label: Label = $BannerContainer/BannerPanel/Margin/HBox/VBox/TitleLabel
@onready var desc_label: Label = $BannerContainer/BannerPanel/Margin/HBox/VBox/DescLabel
@onready var icon_label: Label = $BannerContainer/BannerPanel/Margin/HBox/IconBox/Label
@onready var drag_guide: Control = $DragGuide

var _current_step: int = 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameManager.tutorial_step_changed.connect(_on_tutorial_step_changed)
	_on_tutorial_step_changed(GameManager.tutorial_step)

func _on_tutorial_step_changed(step: int) -> void:
	_current_step = step
	if step <= 0 or step > 3:
		visible = false
		return

	visible = true
	var is_tr = AppLocalization.is_turkish()

	match step:
		1:
			title_label.text = "İLK ASKERİNİ AL" if is_tr else "BUY FIRST UNIT"
			desc_label.text = "Aşağıdaki + UNIT butonuna dokun!" if is_tr else "Tap the + UNIT button below!"
			icon_label.text = "👆"
			banner_container.anchor_top = 0.62
			banner_container.anchor_bottom = 0.62
			if drag_guide: drag_guide.visible = false
		2:
			title_label.text = "İKİNCİ ASKERİNİ AL" if is_tr else "BUY SECOND UNIT"
			desc_label.text = "Birleştirmek için bir asker daha satın al." if is_tr else "Buy another unit to merge them."
			icon_label.text = "➕"
			banner_container.anchor_top = 0.62
			banner_container.anchor_bottom = 0.62
			if drag_guide: drag_guide.visible = false
		3:
			title_label.text = "AYNI ASKERLERİ BİRLEŞTİR" if is_tr else "MERGE MATCHING UNITS"
			desc_label.text = "Bir askeri diğerinin üzerine sürükle ve bırak!" if is_tr else "Drag one unit onto the other and release!"
			icon_label.text = "⚡"
			# Positioned at top area so target units remain unobstructed (Clause 1086, 1087)
			banner_container.anchor_top = 0.18
			banner_container.anchor_bottom = 0.18
			if drag_guide:
				drag_guide.visible = true
				drag_guide.queue_redraw()
