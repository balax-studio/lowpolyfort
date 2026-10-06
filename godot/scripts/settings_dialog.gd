class_name SettingsDialog
extends Control

const AppLocalization = preload("res://scripts/localization.gd")

## User settings dialog for audio, haptics, damage numbers, language, and progress resets.
## Source of truth: Flutter lib/ui/settings/settings_dialog.dart (Clauses 138, 664).

signal closed()

@onready var title_badge_label: Label = $SafeContainer/CenterCard/Margin/VBox/TitleBadge/Margin/Label
@onready var language_row_label: Label = $SafeContainer/CenterCard/Margin/VBox/LanguageRow/Label
@onready var btn_en: Button = $SafeContainer/CenterCard/Margin/VBox/LanguageRow/BtnRow/EnglishBtn
@onready var btn_tr: Button = $SafeContainer/CenterCard/Margin/VBox/LanguageRow/BtnRow/TurkishBtn

@onready var master_label: Label = $SafeContainer/CenterCard/Margin/VBox/MasterVolSection/HeaderRow/Label
@onready var master_percent_label: Label = $SafeContainer/CenterCard/Margin/VBox/MasterVolSection/HeaderRow/PercentLabel
@onready var master_slider: HSlider = $SafeContainer/CenterCard/Margin/VBox/MasterVolSection/Slider

@onready var sfx_label: Label = $SafeContainer/CenterCard/Margin/VBox/SfxVolSection/HeaderRow/Label
@onready var sfx_percent_label: Label = $SafeContainer/CenterCard/Margin/VBox/SfxVolSection/HeaderRow/PercentLabel
@onready var sfx_slider: HSlider = $SafeContainer/CenterCard/Margin/VBox/SfxVolSection/Slider

@onready var vibration_label: Label = $SafeContainer/CenterCard/Margin/VBox/VibrationRow/Label
@onready var vibration_toggle: CheckButton = $SafeContainer/CenterCard/Margin/VBox/VibrationRow/Toggle

@onready var damage_numbers_label: Label = $SafeContainer/CenterCard/Margin/VBox/DamageRow/Label
@onready var damage_numbers_toggle: CheckButton = $SafeContainer/CenterCard/Margin/VBox/DamageRow/Toggle

@onready var reset_button: Button = $SafeContainer/CenterCard/Margin/VBox/ResetButton
@onready var reset_btn_label: Label = $SafeContainer/CenterCard/Margin/VBox/ResetButton/Label

@onready var apply_button: Button = $SafeContainer/CenterCard/Margin/VBox/ApplyButton
@onready var apply_btn_label: Label = $SafeContainer/CenterCard/Margin/VBox/ApplyButton/Label

@onready var confirm_dialog: PanelContainer = $ConfirmDialog
@onready var confirm_cancel_btn: Button = $ConfirmDialog/Margin/VBox/BtnRow/CancelButton
@onready var confirm_wipe_btn: Button = $ConfirmDialog/Margin/VBox/BtnRow/WipeButton

var _master_vol: float = 1.0
var _sfx_vol: float = 1.0
var _vibration: bool = true
var _show_damage: bool = true
var _language: String = "en"

func _ready() -> void:
	if btn_en: btn_en.pressed.connect(func(): _set_language("en"))
	if btn_tr: btn_tr.pressed.connect(func(): _set_language("tr"))

	if master_slider:
		master_slider.value_changed.connect(_on_master_slider_changed)
	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_slider_changed)

	if vibration_toggle:
		vibration_toggle.toggled.connect(func(v): _vibration = v)
	if damage_numbers_toggle:
		damage_numbers_toggle.toggled.connect(func(v): _show_damage = v)

	if reset_button:
		reset_button.pressed.connect(_on_reset_pressed)
	if confirm_cancel_btn:
		confirm_cancel_btn.pressed.connect(func(): confirm_dialog.visible = false)
	if confirm_wipe_btn:
		confirm_wipe_btn.pressed.connect(_on_confirm_wipe)

	if apply_button:
		apply_button.pressed.connect(_save_and_close)

	if confirm_dialog:
		confirm_dialog.visible = false

func open() -> void:
	_master_vol = SaveManager.master_volume
	_sfx_vol = SaveManager.sfx_volume
	_vibration = SaveManager.vibration_enabled
	_show_damage = SaveManager.show_damage_numbers
	_language = SaveManager.language

	if master_slider:
		master_slider.value = _master_vol * 100.0
	if sfx_slider:
		sfx_slider.value = _sfx_vol * 100.0
	if vibration_toggle:
		vibration_toggle.button_pressed = _vibration
	if damage_numbers_toggle:
		damage_numbers_toggle.button_pressed = _show_damage

	_update_ui_strings()
	visible = true

func _set_language(lang: String) -> void:
	_language = lang
	_update_ui_strings()

func _update_ui_strings() -> void:
	if title_badge_label:
		title_badge_label.text = "⚙️ %s" % AppLocalization.text("settings", _language)
	if language_row_label:
		language_row_label.text = AppLocalization.text("language", _language)
	if master_label:
		master_label.text = AppLocalization.text("master_vol", _language)
	if sfx_label:
		sfx_label.text = AppLocalization.text("sfx_vol", _language)
	if vibration_label:
		vibration_label.text = AppLocalization.text("vibration", _language)
	if damage_numbers_label:
		damage_numbers_label.text = AppLocalization.text("damage_numbers", _language)
	if reset_btn_label:
		reset_btn_label.text = "🗑️ %s" % AppLocalization.text("wipe_data", _language)
	if apply_btn_label:
		apply_btn_label.text = "✓ %s" % AppLocalization.text("apply_close", _language)

	if master_percent_label:
		master_percent_label.text = "%d%%" % int(_master_vol * 100.0)
	if sfx_percent_label:
		sfx_percent_label.text = "%d%%" % int(_sfx_vol * 100.0)

	# Update active language button styling
	if btn_en:
		btn_en.modulate = Color(1.0, 1.0, 0.2) if _language == "en" else Color(0.7, 0.7, 0.7)
	if btn_tr:
		btn_tr.modulate = Color(1.0, 1.0, 0.2) if _language == "tr" else Color(0.7, 0.7, 0.7)

func _on_master_slider_changed(val: float) -> void:
	_master_vol = val / 100.0
	if master_percent_label:
		master_percent_label.text = "%d%%" % int(val)

func _on_sfx_slider_changed(val: float) -> void:
	_sfx_vol = val / 100.0
	if sfx_percent_label:
		sfx_percent_label.text = "%d%%" % int(val)

func _on_reset_pressed() -> void:
	if confirm_dialog:
		confirm_dialog.visible = true

func _on_confirm_wipe() -> void:
	SaveManager.reset_all_progress()
	_master_vol = 1.0
	_sfx_vol = 1.0
	_vibration = true
	_show_damage = true
	_language = "en"
	if master_slider: master_slider.value = 100.0
	if sfx_slider: sfx_slider.value = 100.0
	if vibration_toggle: vibration_toggle.button_pressed = true
	if damage_numbers_toggle: damage_numbers_toggle.button_pressed = true
	if confirm_dialog: confirm_dialog.visible = false
	_update_ui_strings()

func _save_and_close() -> void:
	SaveManager.master_volume = _master_vol
	SaveManager.sfx_volume = _sfx_vol
	SaveManager.vibration_enabled = _vibration
	SaveManager.show_damage_numbers = _show_damage
	SaveManager.language = _language
	SaveManager.save_to_disk()

	visible = false
	closed.emit()
