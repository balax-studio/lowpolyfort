extends Node

## Automated test runner for Phase 14: Interactive Guided Tutorial Parity.
## Source of truth: Flutter lib/ui/tutorial/tutorial_overlay.dart & lib/managers/game_manager.dart (Clauses 55, 143, 1086–1088).

func _ready() -> void:
	print("==================================================")
	print("--- PHASE 14: INTERACTIVE TUTORIAL PARITY TESTS ---")
	print("==================================================")

	var all_passed = true

	# Test 1: Fresh save triggers tutorial
	SaveManager.reset_all_progress()
	if SaveManager.tutorial_completed != false:
		print("FAIL: Fresh save has tutorial_completed != false")
		all_passed = false
	else:
		print("PASS: Fresh save initializes tutorialCompleted=false")

	# Test 2: Starting Normal mode enters TUTORIAL state
	GameManager.current_mode = GameManager.GameMode.NORMAL
	GameManager.reset_run()

	if GameManager.state != GameManager.GameState.TUTORIAL or GameManager.tutorial_step != 1:
		print("FAIL: Reset run did not enter TUTORIAL state (step: %d, state: %d)" % [GameManager.tutorial_step, GameManager.state])
		all_passed = false
	else:
		print("PASS: Fresh run enters TUTORIAL state at Step 1 (Buy 1st unit)")

	# Test 3: Tutorial Overlay UI reflects Step 1
	var overlay_scene = load("res://scenes/ui/tutorial_overlay.tscn")
	var overlay = overlay_scene.instantiate()
	add_child(overlay)

	var title_lbl: Label = overlay.get_node("BannerContainer/BannerPanel/Margin/HBox/VBox/TitleLabel")
	var guide_node: Control = overlay.get_node("DragGuide")

	if not overlay.visible:
		print("FAIL: Overlay not visible in Step 1")
		all_passed = false
	if title_lbl == null or not ("UNIT" in title_lbl.text or "ASKER" in title_lbl.text):
		print("FAIL: Banner title mismatch in Step 1: %s" % (title_lbl.text if title_lbl else "null"))
		all_passed = false
	if guide_node != null and guide_node.visible:
		print("FAIL: Drag guide should NOT be visible in Step 1")
		all_passed = false

	print("PASS: TutorialOverlay mounts and displays Step 1 banner cleanly")

	# Test 4: Advance to Step 2 (Buy 2nd unit)
	GameManager.advance_tutorial_step(2)
	if GameManager.tutorial_step != 2:
		print("FAIL: Step not advanced to 2")
		all_passed = false
	if not overlay.visible or guide_node.visible:
		print("FAIL: Step 2 overlay state invalid")
		all_passed = false
	print("PASS: Step 2 transition confirmed")

	# Test 5: Advance to Step 3 (Merge units)
	GameManager.advance_tutorial_step(3)
	if GameManager.tutorial_step != 3:
		print("FAIL: Step not advanced to 3")
		all_passed = false
	if not overlay.visible or not guide_node.visible:
		print("FAIL: Step 3 drag guide must be visible")
		all_passed = false
	if not ("MERGE" in title_lbl.text or "BİRLEŞTİR" in title_lbl.text):
		print("FAIL: Step 3 title mismatch: %s" % title_lbl.text)
		all_passed = false
	print("PASS: Step 3 (Merge) activates drag guidance indicator")

	# Test 6: Advance to Step 4 (Completion)
	GameManager.advance_tutorial_step(4)
	if GameManager.state != GameManager.GameState.PLAYING:
		print("FAIL: Game state not transitioned to PLAYING after tutorial")
		all_passed = false
	if not SaveManager.tutorial_completed:
		print("FAIL: SaveManager.tutorial_completed not set to true")
		all_passed = false
	if overlay.visible:
		print("FAIL: Overlay should be hidden after completion")
		all_passed = false
	print("PASS: Tutorial completes, flags SaveManager, transitions to PLAYING, hides overlay")

	# Test 7: Persistence and subsequent runs skip tutorial
	SaveManager.save_to_disk()
	SaveManager.load_from_disk()

	if not SaveManager.tutorial_completed:
		print("FAIL: tutorial_completed did not persist to disk")
		all_passed = false

	GameManager.reset_run()
	if GameManager.state != GameManager.GameState.PLAYING or GameManager.tutorial_step != 0:
		print("FAIL: Completed player should start directly in PLAYING with step=0")
		all_passed = false
	else:
		print("PASS: Subsequent runs start directly in PLAYING state without tutorial")

	# Clean up
	overlay.queue_free()
	SaveManager.reset_all_progress()

	if all_passed:
		print(">>> ALL PHASE 14 PARITY TESTS PASSED! <<<")
		get_tree().quit(0)
	else:
		print(">>> SOME PHASE 14 PARITY TESTS FAILED! <<<")
		get_tree().quit(1)
