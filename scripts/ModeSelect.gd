extends Control

func _ready():
	# Animate in the label
	var label = get_node_or_null("LabelSelect")
	if label:
		label.modulate.a = 0
		create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).tween_property(label, "modulate:a", 1.0, 0.8)
	
	# Connect buttons
	$VBoxContainer/StoryMode.pressed.connect(_on_story_mode_pressed)
	$VBoxContainer/EmotionMatching.pressed.connect(_on_emotion_matching_pressed)
	$VBoxContainer/WordMatching.pressed.connect(_on_word_matching_pressed)
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
	var tree = get_tree()
	await tree.process_frame
	tree.change_scene_to_file("res://scenes/StoryIntro.tscn")

func _on_emotion_matching_pressed():
	print("😊 Emotion Matching")
	GameState.current_mode = "emotion"
	var tree = get_tree()
	await tree.process_frame
	tree.change_scene_to_file("res://scenes/EmotionCharacterSelect.tscn")

func _on_word_matching_pressed():
	print("📝 Word Matching")
	GameState.current_mode = "word"
	var tree = get_tree()
	await tree.process_frame
	tree.change_scene_to_file("res://scenes/WordCharacterSelect.tscn")

func _on_back_pressed():
	var tree = get_tree()
	await tree.process_frame
	tree.change_scene_to_file("res://scenes/MainMenu.tscn")
