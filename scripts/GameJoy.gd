extends Control

const UNLOCK_CONFIRM_SCENE: PackedScene = preload("res://scenes/unlock_confirmation.tscn")
const EMOTION_HINT_COST: int = 1
const EMOTION_HINT_SCENE_PATH: String = "res://scenes/EmoticonHints.tscn"
const VOICE_OVER_MANAGER = preload("res://scripts/VoiceOverManager.gd")

@onready var drop_target = get_node_or_null("DropTargetCharacter")
@onready var hearts = [
	$UI/HeartsContainer/Heart1,
	$UI/HeartsContainer/Heart2,
	$UI/HeartsContainer/Heart3
]
@onready var pause_button = $UI/PauseButton
@onready var hint_button = $UI/HintButton
@onready var level_label = $UI/LevelLabel
@onready var visual_cue = $VisualCue
@onready var cue_label = $VisualCue/CueLabel
@onready var coin_counter: Label = get_node_or_null("UI/CoinsContainer/CoinCounter") as Label
# character will be resolved at runtime based on GameState.selected_character
var character: Node = null

# PAUSE OVERLAY
var pause_scene: PackedScene = null
var pause_instance: Node = null
var hint_confirm_popup: Control = null
var hint_instance: Node = null
var _cue_token: int = 0

const WRONG_CUES := {
"joy": ["That one is not for me.", "I am the happy one.", "That does not match my bright feeling.", "Try a word that fits my sunshine mood.", "Nope, that is not my feeling."],
"sadness": ["That one is not for me.", "I am the sad one.", "That does not match my rainy feeling.", "Try a word that fits my blue mood.", "Nope, that is not my feeling."],
"anger": ["That one is not for me.", "I am the angry one.", "That does not match my fiery feeling.", "Try a word that fits my grumpy mood.", "Nope, that is not my feeling."],
"disgust": ["That one is not for me.", "I am the disgusted one.", "That does not match my yucky feeling.", "Try a word that fits my icky mood.", "Nope, that is not my feeling."],
"fear": ["That one is not for me.", "I am the scared one.", "That does not match my worried feeling.", "Try a word that fits my shaky mood.", "Nope, that is not my feeling."],
}
const CORRECT_CUES := {
	"joy": ["Yes! I am so happy!", "You found my big smile!", "That is the perfect fit!", "I feel so bouncy now!", "You are doing great, friend!"],
	"sadness": ["Yes, that feels like me.", "You found my blue heart.", "That is my rainy face.", "I feel much better now.", "You are a kind friend."],
	"anger": ["Grrr! That is my face!", "You found my grumpy look!", "Yes! That makes me mad!", "I am very upset, see?", "You know how I feel!"],
	"disgust": ["Ew! That is so gross!", "Yuck! You found my face!", "Yes! That is very stinky!", "Bleck! I do not like!", "You found the yucky one!"],
	"fear": ["Eek! That is very scary!", "You found my worried eyes!", "Yes! I am quite afraid!", "Oh! That gave me chills!", "You saved me, thank you!"],
}

var lives = 3
var matching_faces = []  # Track which faces match the character
var dragged_faces = []  # Track which matching faces have been dragged
var _round_input_locked: bool = false

func _ready():
	print("GAMEJOY _ready() RUNNING! node=", name, " script=", get_script().resource_path)
	GameState.current_mode = "emotion"
	if GameState != null and GameState.has_method("set_round_input_locked"):
		GameState.call("set_round_input_locked", false)
	if drop_target == null:
		drop_target = get_node_or_null("DropTargetCharacter2")
	
	if not drop_target:
		print("ERROR: DropTargetCharacter/DropTargetCharacter2 not found!")
		return
	if hearts.size() != 3:
		print("ERROR: Only ", hearts.size(), " hearts found!")
		return
	if not pause_button:
		print("ERROR: PauseButton not found!")
		return
	if not hint_button:
		print("ERROR: HintButton not found!")
		return

	_ensure_coin_hud()
	_update_coin_counter()
	if GameState != null and GameState.has_signal("coins_changed"):
		var coin_sync: Callable = Callable(self, "_on_coins_changed")
		if not GameState.coins_changed.is_connected(coin_sync):
			GameState.coins_changed.connect(coin_sync)
	
	# Select character‑specific pause scene (JoyPauseScene, SadnessPauseScene, etc.)
	var pause_char = GameState.selected_character.capitalize()
	var pause_path = "res://scenes/%sPauseScene.tscn" % pause_char
	if ResourceLoader.exists(pause_path):
		pause_scene = load(pause_path)
	else:
		# Fallback to Joy pause if something is misnamed
		pause_scene = load("res://scenes/JoyPauseScene.tscn")
		print("WARNING: pause scene not found at ", pause_path, " – falling back to JoyPauseScene")

	# Apply revised background asset if available (use central Revised Assets folder)
	var emotion_key: String = GameState.selected_character.to_lower()
	var prefix: String = ""
	match emotion_key:
		"sadness":
			prefix = "Sad"
		_:
			prefix = emotion_key.capitalize()
	var revised_bg_path: String = "res://assets/Revised Assets/%s BG.png" % prefix
	if ResourceLoader.exists(revised_bg_path):
		var revised_tex: Texture2D = load(revised_bg_path) as Texture2D
		var bg_node: TextureRect = get_node_or_null("Background") as TextureRect
		if bg_node and revised_tex != null:
			bg_node.texture = revised_tex
		else:
			print("GameJoy: could not set revised background (node or texture missing): ", revised_bg_path)
	
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
		var tween = create_tween().bind_node(character)
		tween.set_trans(Tween.TRANS_BOUNCE)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(character, "scale", Vector2(1, 1), 0.6)
		tween.tween_property(character, "modulate:a", 1.0, 0.6)
		# Float bob animation
		_create_float_bob(character, 2.5, 10.0)

	if visual_cue != null:
		visual_cue.visible = false
	
	# Animate in hearts
	for i in range(hearts.size()):
		hearts[i].scale = Vector2.ZERO
		await get_tree().create_timer(0.1 * i).timeout
		create_tween().bind_node(hearts[i]).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT).tween_property(hearts[i], "scale", Vector2(1, 1), 0.4)
	
	# Animate level label
	level_label.modulate.a = 0
	create_tween().bind_node(level_label).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).tween_property(level_label, "modulate:a", 1.0, 0.8)
	

	drop_target.emotion_dropped.connect(_on_emotion_dropped)
	pause_button.pressed.connect(_on_pause_pressed)
	hint_button.pressed.connect(_on_hint_pressed)
	
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
	var tween = create_tween().bind_node(node)
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
			if dragged_faces.size() + 1 >= matching_faces.size():
				_set_round_input_locked(true)
			_show_cue(CORRECT_CUES.get(GameState.selected_character.to_lower(), CORRECT_CUES["joy"]))
			_hide_emoticon(dropped_emoticon)
			dragged_faces.append(dropped_emoticon)
			print("Correct face matched! ", dragged_faces.size(), "/", matching_faces.size())
			
			# Check if all matching faces have been dragged
			if dragged_faces.size() >= matching_faces.size():
				# Victory! All matching faces have been dragged
				if character:
					create_tween().bind_node(character).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT).tween_property(character, "scale", Vector2(1.3, 1.3), 0.3)
					await get_tree().create_timer(0.3).timeout
					create_tween().bind_node(character).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).tween_property(character, "scale", Vector2(1.0, 1.0), 0.2)
				go_to_result(true)
			else:
				# Show progress with animation
				if character:
					create_tween().bind_node(character).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT).tween_property(character, "scale", Vector2(1.15, 1.15), 0.2)
					await get_tree().create_timer(0.2).timeout
					create_tween().bind_node(character).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).tween_property(character, "scale", Vector2(1.0, 1.0), 0.15)
	else:
		_show_cue(WRONG_CUES.get(GameState.selected_character.to_lower(), WRONG_CUES["joy"]))
		lose_life()

func _hide_emoticon(emoticon):
	# Fade out and shrink the emoticon
	var tween = create_tween().bind_node(emoticon)
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
		create_tween().bind_node(hearts[heart_index]).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).tween_property(hearts[heart_index], "modulate:a", 0.3, 0.4)
		create_tween().bind_node(hearts[heart_index]).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_IN).tween_property(hearts[heart_index], "scale", Vector2(0.5, 0.5), 0.4)
		print("Heart ", heart_index + 1, " animated!")
	
	if lives <= 0:
		await get_tree().create_timer(0.5).timeout
		go_to_result(false)

func _show_cue(lines: Array) -> void:
	if visual_cue == null or cue_label == null:
		return
	if lines.is_empty():
		return
	_cue_token += 1
	var token: int = _cue_token
	var selected_line: String = String(lines[randi() % lines.size()])
	cue_label.text = selected_line
	VOICE_OVER_MANAGER.play_matching_cue(String(GameState.selected_character), VOICE_OVER_MANAGER.MODE_EMOTION, selected_line)
	visual_cue.visible = true
	await get_tree().create_timer(5.0).timeout
	if token == _cue_token and is_instance_valid(visual_cue):
		visual_cue.visible = false

func _shake(node: Node, duration: float, intensity: float) -> void:
	var original_pos = node.position
	var tween = create_tween().bind_node(node)
	var shake_count = int(duration * 20)
	
	for _i in range(shake_count):
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(node, "position", original_pos + offset, duration / shake_count / 2.0)
	
	tween.tween_property(node, "position", original_pos, duration / shake_count / 2.0)

func go_to_result(win: bool):
	print("GOING TO RESULT! Win: ", win, " Lives: ", lives)
	_set_round_input_locked(true)
	ResultData.is_win = win
	ResultData.hearts_remaining = lives
	if AudioManager != null and AudioManager.has_method("wait_for_voiceover"):
		await AudioManager.wait_for_voiceover(6.0)
	var tree = get_tree()
	if tree:
		# Ensure the tree is not paused when going to result.
		tree.paused = false
		tree.change_scene_to_file("res://scenes/ResultScene.tscn")

func _on_pause_pressed():
	if _round_input_locked:
		return
	if pause_instance:
		pause_instance.queue_free()
		pause_instance = null
		if level_label:
			level_label.visible = true
		if pause_button:
			pause_button.visible = true
		get_tree().paused = false
		print("PAUSE CLOSED")
	else:
		pause_instance = pause_scene.instantiate()
		# If the pause overlay has a Background node, set the revised background texture there as well.
		var emotion_key2: String = GameState.selected_character.to_lower()
		var prefix2: String = ""
		match emotion_key2:
			"sadness":
				prefix2 = "Sad"
			_:
				prefix2 = emotion_key2.capitalize()
		var revised_bg_path2: String = "res://assets/Revised Assets/%s BG.png" % prefix2
		if ResourceLoader.exists(revised_bg_path2):
			var revised_tex2: Texture2D = load(revised_bg_path2) as Texture2D
			var pause_bg: TextureRect = pause_instance.get_node_or_null("Background") as TextureRect if pause_instance != null else null
			if pause_bg != null and revised_tex2 != null:
				pause_bg.texture = revised_tex2
			elif pause_instance != null and pause_instance.has_method("set_background_texture") and revised_tex2 != null:
				pause_instance.call("set_background_texture", revised_tex2)
		add_child(pause_instance)
		if level_label:
			level_label.visible = false
		if pause_button:
			pause_button.visible = false
		get_tree().paused = true
		print("PAUSE OPENED")

func _set_round_input_locked(locked: bool) -> void:
	_round_input_locked = locked
	if GameState != null and GameState.has_method("set_round_input_locked"):
		GameState.call("set_round_input_locked", locked)
	if pause_button != null:
		pause_button.disabled = locked
	if hint_button != null:
		hint_button.disabled = locked
	for child in get_children():
		if child.name.begins_with("Emoticon") and child is BaseButton:
			(child as BaseButton).disabled = locked

func _on_hint_pressed() -> void:
	if hint_confirm_popup != null or hint_instance != null:
		return
	var hint_resource := load(EMOTION_HINT_SCENE_PATH) as PackedScene
	if hint_resource == null:
		push_error("GameJoy: failed to load emotion hint scene at %s" % EMOTION_HINT_SCENE_PATH)
		return
	var hint_scene := hint_resource.instantiate()
	hint_scene.process_mode = Node.PROCESS_MODE_ALWAYS
	if hint_scene.has_method("set_emotion_entries"):
		hint_scene.call("set_emotion_entries", _build_emotion_hint_entries(), _character_color_for_mode())
	if hint_scene.has_method("set_background_texture"):
		hint_scene.call("set_background_texture", _get_level_background_texture())
	hint_scene.close_requested.connect(_on_hint_close_requested)
	hint_instance = hint_scene
	var ui_layer: CanvasLayer = get_node_or_null("UI") as CanvasLayer
	if ui_layer != null:
		ui_layer.add_child(hint_instance)
	else:
		add_child(hint_instance)
	get_tree().paused = true

func _on_hint_close_requested() -> void:
	if hint_instance != null:
		hint_instance.queue_free()
		hint_instance = null
	if pause_instance == null:
		get_tree().paused = false

func _build_emotion_hint_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var emotion_label: String = String(GameState.selected_character).strip_edges().capitalize()
	for i in range(matching_faces.size()):
		var face: Node = matching_faces[i]
		if face == null:
			continue
		var face_index: int = i + 1
		var face_texture: Texture2D = null
		if face is TextureButton:
			face_texture = (face as TextureButton).texture_normal
		entries.append({
			"word": "%s Face %d" % [emotion_label, face_index],
			"definition": "Correct emoticon %d for %s." % [face_index, emotion_label],
			"texture": face_texture,
			"key": "emotion_%s_%d_%d" % [GameState.selected_character.to_lower(), GameState.current_level, face_index]
		})
	return entries

func _show_emotion_hint_confirmation() -> void:
	if hint_confirm_popup != null:
		return
	var popup: Control = UNLOCK_CONFIRM_SCENE.instantiate() as Control
	popup.process_mode = Node.PROCESS_MODE_ALWAYS
	if popup.has_method("set_background_texture"):
		popup.call("set_background_texture", _get_level_background_texture())
	if popup.has_method("set_message"):
		popup.call("set_message", "BUY A HINT TO BRIGHTEN THE CORRECT EMOTION?")
	if popup.has_method("set_cost"):
		popup.call("set_cost", EMOTION_HINT_COST, "coin")
	if popup.has_signal("confirmed"):
		popup.connect("confirmed", Callable(self, "_on_emotion_hint_confirmed"))
	if popup.has_signal("cancelled"):
		popup.connect("cancelled", Callable(self, "_on_emotion_hint_cancelled"))
	hint_confirm_popup = popup
	var ui_layer: CanvasLayer = get_node_or_null("UI") as CanvasLayer
	if ui_layer != null:
		ui_layer.add_child(popup)
	else:
		add_child(popup)
	get_tree().paused = true

func _on_emotion_hint_confirmed() -> void:
	if GameState.spend_coins(EMOTION_HINT_COST):
		GameState.unlock_hint_word(_emotion_hint_key())
		if AudioManager != null:
			AudioManager.play_sfx("correct_choice")
		_update_coin_counter()
		_show_emotion_hint_highlight()
	else:
		if AudioManager != null:
			AudioManager.play_sfx("wrong_choice")
	_cleanup_hint_confirmation()

func _on_emotion_hint_cancelled() -> void:
	_cleanup_hint_confirmation()

func _cleanup_hint_confirmation() -> void:
	hint_confirm_popup = null
	if pause_instance == null:
		get_tree().paused = false

func _is_emotion_hint_unlocked_for_level() -> bool:
	return GameState.is_hint_word_unlocked(_emotion_hint_key())

func _emotion_hint_key() -> String:
	return "emotion_hint_%s_%d" % [GameState.selected_character.to_lower(), GameState.current_level]

func _show_emotion_hint_highlight() -> void:
	var target_emotion: String = GameState.selected_character.to_lower()
	var target: Control = null
	for child in get_children():
		if child.name.begins_with("Emoticon") and "emotion_name" in child:
			if String(child.emotion_name).to_lower() == target_emotion and child.visible:
				target = child as Control
				break
	if target == null:
		return
	var original_scale: Vector2 = target.scale
	var original_modulate: Color = target.modulate
	target.modulate = Color(1.0, 1.0, 1.0, 1.0)
	var tween: Tween = create_tween().bind_node(target)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(target, "scale", original_scale * 1.22, 0.18)
	tween.tween_property(target, "modulate", Color(1.0, 1.0, 0.45, 1.0), 0.18)
	tween.tween_property(target, "scale", original_scale, 0.2)
	tween.tween_property(target, "modulate", original_modulate, 0.24)

func _ensure_coin_hud() -> void:
	if coin_counter != null:
		return
	var ui_layer: CanvasLayer = get_node_or_null("UI") as CanvasLayer
	if ui_layer == null:
		return
	var coin_container: TextureRect = TextureRect.new()
	coin_container.name = "CoinsContainer"
	coin_container.offset_left = 245.0
	coin_container.offset_top = 19.0
	coin_container.offset_right = 338.0
	coin_container.offset_bottom = 70.0
	coin_container.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var panel_tex: Texture2D = load("res://assets/UI/ButtonsText/ButtonText_Orange_OnOffBackground.png") as Texture2D
	coin_container.texture = panel_tex
	var coin_icon: TextureRect = TextureRect.new()
	coin_icon.name = "Coin"
	coin_icon.offset_left = 12.0
	coin_icon.offset_top = 9.0
	coin_icon.offset_right = 45.0
	coin_icon.offset_bottom = 42.0
	coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_icon.texture = load("res://assets/UI/Icons/Icon_Small_Coin.png") as Texture2D
	coin_container.add_child(coin_icon)
	coin_counter = Label.new()
	coin_counter.name = "CoinCounter"
	coin_counter.offset_left = 51.0
	coin_counter.offset_top = 4.0
	coin_counter.offset_right = 86.0
	coin_counter.offset_bottom = 40.0
	coin_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coin_counter.add_theme_constant_override("outline_size", 10)
	var coin_font: FontFile = load("res://assets/fonts/Fredoka/static/Fredoka_Condensed-Bold.ttf") as FontFile
	coin_counter.add_theme_font_override("font", coin_font)
	coin_counter.add_theme_font_size_override("font_size", 30)
	coin_container.add_child(coin_counter)
	ui_layer.add_child(coin_container)

func _update_coin_counter() -> void:
	if coin_counter != null:
		coin_counter.text = str(GameState.coins)

func _on_coins_changed(new_amount: int) -> void:
	if coin_counter != null:
		coin_counter.text = str(new_amount)

func _get_level_background_texture() -> Texture2D:
	var background: TextureRect = get_node_or_null("Background") as TextureRect
	if background != null:
		return background.texture
	return null

func _character_color_for_mode() -> Color:
	match GameState.selected_character.to_lower():
		"joy":
			return Color(0.976, 0.89, 0.16, 1.0)
		"sadness":
			return Color(0.39, 0.66, 0.98, 1.0)
		"anger":
			return Color(0.97, 0.37, 0.32, 1.0)
		"disgust":
			return Color(0.33, 0.82, 0.45, 1.0)
		"fear":
			return Color(0.66, 0.42, 0.92, 1.0)
		_:
			return Color(1, 1, 1, 1)
