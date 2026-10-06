class_name SecondChanceDialog
extends Control

## Modal dialog presented when Base HP reaches zero, offering a single 50% HP revive.
## Source of truth: Flutter lib/ui/second_chance/second_chance_dialog.dart (Clauses 462–480, 512).

@onready var watch_ad_button: Button = $SafeCenter/Card/Margin/VBox/WatchAdButton
@onready var end_run_button: Button = $SafeCenter/Card/Margin/VBox/EndRunButton

func _ready() -> void:
	visible = false
	GameManager.second_chance_offered.connect(_on_second_chance_offered)
	if watch_ad_button:
		watch_ad_button.pressed.connect(_on_watch_ad_pressed)
	if end_run_button:
		end_run_button.pressed.connect(_on_end_run_pressed)

func _on_second_chance_offered() -> void:
	visible = true

func _on_watch_ad_pressed() -> void:
	visible = false
	GameManager.claim_second_chance()

func _on_end_run_pressed() -> void:
	visible = false
	GameManager.dismiss_second_chance()
