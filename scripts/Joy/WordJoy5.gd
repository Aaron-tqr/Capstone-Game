extends Control

@onready var drop_target = null
@onready var hearts = [$UI/HeartsContainer/Heart1, $UI/HeartsContainer/Heart2, $UI/HeartsContainer/Heart3]
@onready var pause_button = $UI/PauseButton
@onready var hint_button = $UI/HintButton
@onready var level_label = $UI/LevelLabel
@onready var joy_char = $JoyChar
@onready var visual_cue = $VisualCue
@onready var cue_label = $VisualCue/CueLabel

const HINT_SCENE: PackedScene = preload("res://scenes/HintScene.tscn")
const VOICE_OVER_MANAGER = preload("res://scripts/VoiceOverManager.gd")

const WRONG_CUES := {
"joy": ["That word is not mine.", "I need a happy word.", "Try a word that feels bright."],
"sadness": ["That word does not fit me.", "I need a sad word.", "Try a softer, blue feeling word."],
"anger": ["That word is not for me.", "I need an angry word.", "Try a stronger, fiery word."],
"disgust": ["Nope, that word is not mine.", "I need a disgust word.", "Try a word that sounds yucky."],
"fear": ["That word is not mine.", "I need a fear word.", "Try a worried-sounding word."],
}
const CORRECT_CUES := {
	"joy": ["That's my word!", "That word fits me!", "Yes, that happy word is mine!"],
	"sadness": ["That's my word.", "That word fits my feeling.", "Yes, that sad word is mine."],
	"anger": ["That's my word!", "That word fits my mood.", "Yes, that angry word is mine!"],
	"disgust": ["That's my word.", "That word fits me.", "Yes, that yucky word is mine."],
	"fear": ["That's my word.", "That word fits my worried feeling.", "Yes, that fear word is mine."],
}

var lives = 3
var pause_instance: Node = null
var hint_instance: Node = null
var matching_words = []
var dragged_words = []
var draggable_labels = []
var _cue_token: int = 0

# Correct words for joy level 5
var correct_words = ["cheerful", "jolly", "sunny", "excited", "delighted"]

func _ready():
	GameState.current_mode = "word"

	# Apply revised background texture from Revised Assets if available
	var sel = GameState.selected_character.to_lower()
	var prefix = "Sad" if sel == "sadness" else sel.capitalize()
	var revised_path = "res://assets/Revised Assets/%s BG.png" % prefix
	var bg_node: TextureRect = get_node_or_null("Background") as TextureRect
	if bg_node != null and ResourceLoader.exists(revised_path):
		var tex := load(revised_path) as Texture2D
		if tex:
			bg_node.texture = tex
	# Animate in Joy character
	if joy_char:
		joy_char.modulate.a = 0
		create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).tween_property(joy_char, "modulate:a", 1.0, 0.6)
		# Float bob animation
		_create_float_bob(joy_char, 2.5, 10.0)
	
	# Resolve drop target node
	drop_target = _find_drop_target()
	print("WordJoy5 drop_target chosen:", drop_target)
	if drop_target and drop_target.get_script():
		print("drop_target script path:", drop_target.get_script().resource_path)
	if drop_target and (not drop_target.has_method("receive_drop") or not drop_target.has_signal("word_dropped")):
		print("WordJoy5: drop_target missing API; forcing DropTargetWord script")
		drop_target.set_script(preload("res://scripts/DropTargetWord.gd"))
		drop_target.add_to_group("word_drop_targets")

	# Find all word labels and attach dragging component (search recursively)
	print("🔍 Looking for word labels in scene...")
	_collect_word_labels(self, "LEVEL 5")
	
	# Setup drop target
	if not drop_target:
		push_error("WordJoy5: drop_target not found")
		return
	if not drop_target.has_method("receive_drop") or not drop_target.has_signal("word_dropped"):
		drop_target.set_script(preload("res://scripts/DropTargetWord.gd"))
		drop_target.add_to_group("word_drop_targets")
	drop_target.set("correct_words", correct_words)

	if not drop_target.has_signal("word_dropped"):
		push_error("WordJoy5: drop_target does not have word_dropped signal (found: %s)" % drop_target.get_script())
		return
	drop_target.word_dropped.connect(_on_word_dropped)
	pause_button.pressed.connect(_on_pause_pressed)
	if hint_button:
		hint_button.pressed.connect(_on_hint_pressed)
	WordHintHelper.watch_coin_counter(self)
	level_label.text = "LEVEL %d" % GameState.current_level
	print("📝 WordJoy5 READY! Draggable labels: ", draggable_labels.size(), " | Matching words: ", matching_words.size())
	if visual_cue != null:
		visual_cue.visible = false

func _find_drop_target():
	var names = ["DropTargetWord", "DropTargetCharacter"]
	for name in names:
		var candidate = get_node_or_null(name)
		if candidate:
			return candidate
		candidate = find_child(name, true, false)
		if candidate:
			return candidate
	for child in get_children():
		if child.name in names:
			return child
	for node in get_tree().get_nodes_in_group("word_drop_targets"):
		if node:
			return node
	return null

func _collect_word_labels(node: Node, level_text: String):
	for child in node.get_children():
		if child is Label and String(child.name).begins_with("Word") and child.text != level_text:
			var word = child.text.to_lower()
			print("  ✓ Found word label: ", child.name, " text=", child.text)
			var draggable = DraggableLabel.new(child, word)
			draggable_labels.append(draggable)
			
			if word in correct_words:
				matching_words.append(draggable)
				print("    ✓ Marked as matching word!")
		_collect_word_labels(child, level_text)

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

func _process(_delta):
	# Update draggable labels
	for draggable in draggable_labels:
		draggable.process()

func _on_word_dropped(is_correct: bool):
	if is_correct:
		var dropped_word = drop_target.last_dropped_word
		if dropped_word and dropped_word in matching_words and dropped_word not in dragged_words:
			_show_cue(CORRECT_CUES.get(GameState.selected_character.to_lower(), CORRECT_CUES["joy"]))
			_hide_word(dropped_word)
			dragged_words.append(dropped_word)
			print("Correct word matched! ", dragged_words.size(), "/", matching_words.size())
			
			if dragged_words.size() >= matching_words.size():
				go_to_result(true)
		else:
			print("Word already used or not in matching list!")
	else:
		_show_cue(WRONG_CUES.get(GameState.selected_character.to_lower(), WRONG_CUES["joy"]))
		lose_life()

func _hide_word(word_label):
	var label_node = word_label.label
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(label_node, "modulate:a", 0.0, 0.3)
	tween.tween_property(label_node, "scale", Vector2(0.5, 0.5), 0.3)
	await tween.finished
	label_node.visible = false

func lose_life():
	lives -= 1
	print("LIVES: ", lives)
	var heart_index = 2 - lives
	if heart_index >= 0 and heart_index < 3:
		create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).tween_property(hearts[heart_index], "modulate:a", 0.3, 0.4)
		create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_IN).tween_property(hearts[heart_index], "scale", Vector2(0.5, 0.5), 0.4)
	if lives <= 0:
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
	VOICE_OVER_MANAGER.play_matching_cue(String(GameState.selected_character), VOICE_OVER_MANAGER.MODE_WORD, selected_line)
	visual_cue.visible = true
	await get_tree().create_timer(5.0).timeout
	if token == _cue_token and is_instance_valid(visual_cue):
		visual_cue.visible = false

func _on_hint_pressed() -> void:
	if hint_instance != null:
		return
	var hint_scene := HINT_SCENE.instantiate()
	hint_scene.process_mode = Node.PROCESS_MODE_ALWAYS
	if hint_scene.has_method("set_word_entries"):
		hint_scene.call("set_word_entries", _build_word_hint_entries(), _character_color())
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
	get_tree().paused = false

func _build_word_hint_entries() -> Array[String]:
	var words: Array[String] = []
	for draggable in draggable_labels:
		if draggable != null and "word" in draggable:
			words.append(String(draggable.word))
	return words

func _get_level_background_texture() -> Texture2D:
	var background: TextureRect = get_node_or_null("Background") as TextureRect
	if background != null:
		return background.texture
	return null

func _character_color() -> Color:
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

func go_to_result(win: bool):
	ResultData.is_win = win
	ResultData.hearts_remaining = lives
	if AudioManager != null and AudioManager.has_method("wait_for_voiceover"):
		await AudioManager.wait_for_voiceover(6.0)
	get_tree().change_scene_to_file("res://scenes/ResultScene.tscn")

func _on_pause_pressed():
	if pause_instance:
		pause_instance.queue_free()
		pause_instance = null
	else:
		var pause_char_name = GameState.selected_character.capitalize()
		var pause_path = "res://scenes/%sPauseScene.tscn" % pause_char_name
		var pause_scene: PackedScene = null
		if ResourceLoader.exists(pause_path):
			pause_scene = load(pause_path)
		else:
			pause_scene = load("res://scenes/JoyPauseScene.tscn")
		pause_instance = pause_scene.instantiate()
		add_child(pause_instance)
