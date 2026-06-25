extends Control

const StyledPopup = preload("res://scripts/StyledPopup.gd")

@onready var story_button: Button = $VBoxContainer/StoryMode
@onready var emotion_button: Button = $VBoxContainer/EmotionMatching
@onready var word_button: Button = $VBoxContainer/WordMatching

var _unlock_popup_queue: Array[Dictionary] = []

func _ready():
	# Animate in the label
	var label = get_node_or_null("LabelSelect")
	if label:
		label.modulate.a = 0
		create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).tween_property(label, "modulate:a", 1.0, 0.8)
	
	# Connect buttons
	story_button.pressed.connect(_on_story_mode_pressed)
	emotion_button.pressed.connect(_on_emotion_matching_pressed)
	word_button.pressed.connect(_on_word_matching_pressed)
	$Back.pressed.connect(_on_back_pressed)
	
	# Animate buttons with simple fade and scale (no stagger for now)
	var buttons = $VBoxContainer.get_children()
	for button in buttons:
		button.modulate.a = 0
		button.scale = Vector2(0.9, 0.9)
		
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(button, "scale", Vector2(1, 1), 0.5)
		tween.tween_property(button, "modulate:a", 1.0, 0.5)
		
		# Add hover scale effect
		_add_button_hover(button)

	_apply_mode_lock_visuals()
	await get_tree().process_frame
	_show_pending_unlock_popups()

func _add_button_hover(button: Button) -> void:
	var original_scale = button.scale
	button.mouse_entered.connect(func():
		create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).tween_property(button, "scale", original_scale * 1.1, 0.2)
	)
	button.mouse_exited.connect(func():
		create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).tween_property(button, "scale", original_scale, 0.2)
	)

func _on_story_mode_pressed():
	print("📖 Story Mode (Week 2)")
	_change_scene_to_file("res://scenes/Story/StoryActSelect.tscn")

func _on_emotion_matching_pressed():
	if not GameState.is_mode_unlocked("emotion"):
		_show_warning("This game mode is still locked. Finish Act 2 Story to continue.")
		return
	print("😊 Emotion Matching")
	GameState.current_mode = "emotion"
	_change_scene_to_file("res://scenes/EmotionCharacterSelect.tscn")

func _on_word_matching_pressed():
	if not GameState.is_mode_unlocked("word"):
		_show_warning("Please clear at least 5 Emotion Matching levels to unlock this mode.")
		return
	print("📝 Word Matching")
	GameState.current_mode = "word"
	_change_scene_to_file("res://scenes/WordCharacterSelect.tscn")

func _on_back_pressed():
	_change_scene_to_file("res://scenes/MainMenu.tscn")

func _change_scene_to_file(scene_path: String) -> void:
	var transition_node: Node = get_node_or_null("/root/SceneTransition")
	if transition_node and transition_node.has_method("change_scene_to_file"):
		transition_node.call("change_scene_to_file", scene_path)
		return
	get_tree().change_scene_to_file(scene_path)

func _apply_mode_lock_visuals() -> void:
	_set_mode_button_locked(emotion_button, not GameState.is_mode_unlocked("emotion"))
	_set_mode_button_locked(word_button, not GameState.is_mode_unlocked("word"))

func _set_mode_button_locked(button: Button, locked: bool) -> void:
	if button == null:
		return
	_set_mode_lock_icon_visible(button, locked)
	if locked:
		button.modulate = Color(0.58, 0.58, 0.58, 0.95)
		button.tooltip_text = "Locked"
	else:
		button.modulate = Color(1, 1, 1, 1)
		button.tooltip_text = ""

func _set_mode_lock_icon_visible(button: Button, locked: bool) -> void:
	if button == null:
		return
	for child in button.get_children():
		if child is CanvasItem and String(child.name).to_lower().find("lock") != -1:
			(child as CanvasItem).visible = locked

func _show_warning(message: String) -> void:
	StyledPopup.open_popup(self, "MODE LOCKED", message, "OK", Color(1.0, 0.45, 0.25, 1.0))

func _show_pending_unlock_popups() -> void:
	var all_events: Array[Dictionary] = GameState.consume_pending_unlock_events()
	var keep_events: Array[Dictionary] = []
	_unlock_popup_queue.clear()
	for event in all_events:
		var kind: String = String(event.get("kind", "")).to_lower()
		if kind == "mode":
			_unlock_popup_queue.append(event)
		else:
			keep_events.append(event)
	for event in _unlock_popup_queue:
		await _show_unlock_popup(event)
	for remaining in keep_events:
		GameState.pending_unlock_events.append(remaining)
	_apply_mode_lock_visuals()

func _show_unlock_popup(event: Dictionary) -> void:
	var title: String = String(event.get("title", "Unlocked!"))
	var message: String = String(event.get("message", "New content unlocked."))
	var kind: String = String(event.get("kind", "")).to_lower()
	var accent: Color = Color(1.0, 0.66, 0.28, 1.0)
	if kind == "mode":
		if title.to_lower().find("emotion") != -1:
			_animate_unlock_button(emotion_button)
			accent = Color(0.41, 0.86, 1.0, 1.0)
		elif title.to_lower().find("word") != -1:
			_animate_unlock_button(word_button)
			accent = Color(1.0, 0.54, 0.36, 1.0)

	var popup: StyledPopup = StyledPopup.open_popup(self, title.to_upper(), message, "AWESOME", accent)
	await popup.confirmed

func _animate_unlock_button(button: Button) -> void:
	if button == null:
		return
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(button, "scale", Vector2(1.16, 1.16), 0.26)
	tw.tween_property(button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.26)
	tw.tween_property(button, "scale", Vector2.ONE, 0.22)
