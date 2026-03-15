extends Control

@onready var drop_target = $DropTargetCharacter
@onready var hearts = [
	$UI/HeartsContainer/Heart1,
	$UI/HeartsContainer/Heart2,
	$UI/HeartsContainer/Heart3
]
@onready var pause_button = $UI/PauseButton
@onready var level_label = $UI/LevelLabel
# character will be resolved at runtime based on GameState.selected_character
var character: Node = null

# PAUSE OVERLAY
@onready var pause_scene = preload("res://scenes/PauseScene.tscn")
var pause_instance: Node = null

var lives = 3
var matching_faces = []  # Track which faces match the character
var dragged_faces = []  # Track which matching faces have been dragged

func _ready():
	print("GAMEJOY _ready() RUNNING! node=", name, " script=", get_script().resource_path)
	
	if not drop_target:
		print("ERROR: DropTargetCharacter not found!")
		return
	if hearts.size() != 3:
		print("ERROR: Only ", hearts.size(), " hearts found!")
		return
	if not pause_button:
		print("ERROR: PauseButton not found!")
		return
	
	# determine which character node should be used (must match scene naming)
	var char_name = GameState.selected_character.capitalize() + "Char"
	character = get_node_or_null(char_name)
	if not character:
		print("WARNING: character node not found: ", char_name)
	
	# Find all emoticon faces and identify which ones match the target character
	_identify_matching_faces()
	
	# Animate in character with bounce and fade (character resolved above)
	if character:
		character.scale = Vector2(0.8, 0.8)
		character.modulate.a = 0
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_BOUNCE)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(character, "scale", Vector2(1, 1), 0.6)
		tween.tween_property(character, "modulate:a", 1.0, 0.6)
		# Float bob animation
		_create_float_bob(character, 2.5, 10.0)
	
	# Animate in hearts
	for i in range(hearts.size()):
		hearts[i].scale = Vector2.ZERO
		await get_tree().create_timer(0.1 * i).timeout
		create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT).tween_property(hearts[i], "scale", Vector2(1, 1), 0.4)
	
	# Animate level label
	level_label.modulate.a = 0
	create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).tween_property(level_label, "modulate:a", 1.0, 0.8)
	

	drop_target.emotion_dropped.connect(_on_emotion_dropped)
	pause_button.pressed.connect(_on_pause_pressed)
	
	level_label.text = "LEVEL " + str(GameState.current_level)
	print("accepts_emotion = '", drop_target.accepts_emotion, "'")
	print("READY! Drag emojis! Total matching faces: ", matching_faces.size())

func _identify_matching_faces():
	# Get the target character emotion for this level
	var target_emotion = GameState.selected_character.to_lower()  # e.g., "joy"
	
	# Find all emoticon nodes (TextureButton children with emotion_name property)
	for child in get_children():
		if child.name.begins_with("Emoticon") and "emotion_name" in child:
			var emotion = child.emotion_name.to_lower()
			if emotion == target_emotion:
				matching_faces.append(child)
				print("Found matching face: ", child.name, " (", emotion, ")")

func _create_float_bob(node: Node, duration: float, amplitude: float) -> void:
	if not is_instance_valid(node):
		return
	var original_y = node.position.y
	var tween = create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "position:y", original_y + amplitude, duration / 2.0)
	tween.tween_property(node, "position:y", original_y - amplitude, duration / 2.0)

func _on_emotion_dropped(is_correct: bool):
	print("DROP! Correct: ", is_correct)
	if is_correct:
		# Get the emoticon that was just dropped
		var dropped_emoticon = drop_target.last_dropped_emotion
		
		# Hide the correct face
		if dropped_emoticon and dropped_emoticon in matching_faces:
			_hide_emoticon(dropped_emoticon)
			dragged_faces.append(dropped_emoticon)
			print("Correct face matched! ", dragged_faces.size(), "/", matching_faces.size())
			
			# Check if all matching faces have been dragged
			if dragged_faces.size() >= matching_faces.size():
				# Victory! All matching faces have been dragged
				if character:
					create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT).tween_property(character, "scale", Vector2(1.3, 1.3), 0.3)
					await get_tree().create_timer(0.3).timeout
					create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).tween_property(character, "scale", Vector2(1.0, 1.0), 0.2)
				go_to_result(true)
			else:
				# Show progress with animation
				if character:
					create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT).tween_property(character, "scale", Vector2(1.15, 1.15), 0.2)
					await get_tree().create_timer(0.2).timeout
					create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).tween_property(character, "scale", Vector2(1.0, 1.0), 0.15)
	else:
		lose_life()

func _hide_emoticon(emoticon):
	# Fade out and shrink the emoticon
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(emoticon, "modulate:a", 0.0, 0.3)
	tween.tween_property(emoticon, "scale", Vector2(0.5, 0.5), 0.3)
	await tween.finished
	emoticon.visible = false

func lose_life():
	lives -= 1
	print("LIVES: ", lives)
	
	# Shake on wrong answer
	if character:
		_shake(character, 0.4, 8.0)
	
	var heart_index = 2 - lives  # 1st mistake = index 2
	if heart_index >= 0 and heart_index < 3:
		# Animate heart disappearing
		create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).tween_property(hearts[heart_index], "modulate:a", 0.3, 0.4)
		create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_IN).tween_property(hearts[heart_index], "scale", Vector2(0.5, 0.5), 0.4)
		print("Heart ", heart_index + 1, " animated!")
	
	if lives <= 0:
		await get_tree().create_timer(0.5).timeout
		go_to_result(false)

func _shake(node: Node, duration: float, intensity: float) -> void:
	var original_pos = node.position
	var tween = create_tween()
	var shake_count = int(duration * 20)
	
	for _i in range(shake_count):
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(node, "position", original_pos + offset, duration / shake_count / 2.0)
	
	tween.tween_property(node, "position", original_pos, duration / shake_count / 2.0)

func go_to_result(win: bool):
	print("GOING TO RESULT! Win: ", win, " Lives: ", lives)
	ResultData.is_win = win
	ResultData.hearts_remaining = lives
	var tree = get_tree()
	if tree:
		tree.change_scene_to_file("res://scenes/ResultScene.tscn")

func _on_pause_pressed():
	if pause_instance:
		pause_instance.queue_free()
		pause_instance = null
		print("PAUSE CLOSED")
	else:
		pause_instance = pause_scene.instantiate()
		add_child(pause_instance)
		print("PAUSE OPENED")
