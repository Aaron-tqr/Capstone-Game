extends Control

const HINT_SCENE: PackedScene = preload("res://scenes/HintScene.tscn")


@onready var drop_target = $Character/DropTargetWord
@onready var hearts = [$UI/HeartsContainer/Heart1, $UI/HeartsContainer/Heart2, $UI/HeartsContainer/Heart3]
@onready var pause_button = $UI/PauseButton
@onready var hint_button = $UI/HintButton
@onready var music_button = get_node_or_null("UI/MusicButton") as BaseButton
@onready var volume_button = get_node_or_null("UI/VolumeButton") as BaseButton
@onready var level_label = $UI/LevelLabel
@onready var word_container = $WordContainer
@onready var character_sprite = $Character  # added to generic scene

var lives = 3
var pause_instance: Node = null
var pause_scene: PackedScene = null
var hint_instance: Node = null
var matching_words = []
var dragged_words = []
var draggable_labels = []
var _round_input_locked: bool = false

# master word bank per emotion; each entry is a pool of possible words
var word_bank = {
	"joy": ["happy","glad","jolly","cheerful","excited","angry","sad","scared"],
	"sadness": ["sad","depressed","mournful","blue","tearful","happy","angry","scared"],
	"anger": ["furious","mad","irate","irritated","rage","happy","calm","sad"],
	"fear": ["scared","terrified","afraid","nervous","brave","calm","relaxed","angry"],
	"disgust": ["gross","nasty","repulsive","pleasant","nice","clean","happy","sad"]
}

# how many correct words per level (index 0 = level1, …)
var correct_count_by_level = [1,2,3,4,5]

func _ready():
	# determine which character/level we're on
	var char_sel = GameState.selected_character.to_lower() if "selected_character" in GameState else "joy"
	var lvl = GameState.current_level if "current_level" in GameState else 1

	# Ensure global state is consistent for ResultScene and pause logic
	GameState.current_mode = "word"
	GameState.current_level = lvl
	if GameState != null and GameState.has_method("set_round_input_locked"):
		GameState.call("set_round_input_locked", false)

	# Select character‑specific pause scene (JoyPauseScene, SadnessPauseScene, etc.)
	var pause_char_name = GameState.selected_character.capitalize()
	var pause_path = "res://scenes/%sPauseScene.tscn" % pause_char_name
	if ResourceLoader.exists(pause_path):
		pause_scene = load(pause_path)
	else:
		pause_scene = load("res://scenes/JoyPauseScene.tscn")
		print("WARNING (WordGame): pause scene not found at ", pause_path, " – falling back to JoyPauseScene")

	# Apply revised background asset if available
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
			print("WordGame: could not set revised background (node or texture missing): ", revised_bg_path)

	# character sprite setup
	if character_sprite:
		var tex_path = "res://assets/characters/%s%d.png" % [char_sel.capitalize(), lvl]
		if ResourceLoader.exists(tex_path):
			character_sprite.texture = load(tex_path)
		else:
			print("Warning: character texture not found: ", tex_path)

	# pick words for this round
	var pool = word_bank.get(char_sel, word_bank["joy"]).duplicate()
	pool.shuffle()
	var words = []
	for i in range(5):
		words.append(pool[i])

	var correct_count = correct_count_by_level[(lvl - 1) % correct_count_by_level.size()]
	var correct = words.slice(0, correct_count)

	# Clear any existing labels
	for c in word_container.get_children():
		c.queue_free()

	# create draggable labels and mark correct ones
	for i in range(words.size()):
		var w = words[i]
		var lbl = Label.new()
		lbl.text = w.capitalize()
		lbl.name = "Word_%s" % w
		# style copying could be added here (font, size)
		word_container.add_child(lbl)
		var draggable = DraggableLabel.new(lbl, w)
		draggable_labels.append(draggable)
		if w in correct:
			matching_words.append(draggable)

	# Setup drop target with correct list
	if not drop_target:
		push_error("WordGame: drop_target not found")
		return
	drop_target.correct_words = correct
	if not drop_target.has_signal("word_dropped"):
		push_error("WordGame: drop_target does not have word_dropped signal (script=%s)" % drop_target.get_script())
		return
	drop_target.word_dropped.connect(_on_word_dropped)
	pause_button.pressed.connect(_on_pause_pressed)
	level_label.text = "LEVEL %d" % lvl
	print("📝 WordGame READY! char=", char_sel, " level=", lvl, " words=", words, " correct=", correct)
	
	# animate character floating
	if character_sprite:
		_create_float_bob(character_sprite, 2.5, 10.0)

	if not hint_button:
		print("ERROR (WordGame): HintButton not found!")
		return
	hint_button.pressed.connect(_on_hint_pressed)

	WordHintHelper.watch_coin_counter(self)

func _on_word_dropped(is_correct: bool):
	if is_correct:
		var dropped_word = drop_target.last_dropped_word
		if dropped_word and dropped_word in matching_words:
			if dragged_words.size() + 1 >= matching_words.size():
				_set_round_input_locked(true)
			_hide_word(dropped_word)
			dragged_words.append(dropped_word)
			if dragged_words.size() >= matching_words.size():
				go_to_result(true)
	else:
		lose_life()

func _hide_word(word_button):
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(word_button, "modulate:a", 0.0, 0.3)
	tween.tween_property(word_button, "scale", Vector2(0.5, 0.5), 0.3)
	await tween.finished
	word_button.visible = false

func lose_life():
	lives -= 1
	var heart_index = 2 - lives
	if heart_index >= 0 and heart_index < 3:
		hearts[heart_index].modulate = Color.BLACK
	if lives <= 0:
		go_to_result(false)

func go_to_result(win: bool):
	_set_round_input_locked(true)
	ResultData.is_win = win
	ResultData.hearts_remaining = lives
	if AudioManager != null and AudioManager.has_method("wait_for_voiceover"):
		await AudioManager.wait_for_voiceover(6.0)
	var tree = get_tree()
	if tree:
		# Make sure the tree is unpaused when leaving the game
		tree.paused = false
		_change_scene_to_file("res://scenes/ResultScene.tscn")

func _on_pause_pressed():
	if _round_input_locked:
		return
	if pause_instance:
		pause_instance.queue_free()
		pause_instance = null
		_set_match_hud_visible(true)
		get_tree().paused = false
	else:
		if not pause_scene:
			# Safety: build a default pause scene path if _ready was skipped
			var pause_char_name2 = GameState.selected_character.capitalize()
			var fallback_path = "res://scenes/%sPauseScene.tscn" % pause_char_name2
			if ResourceLoader.exists(fallback_path):
				pause_scene = load(fallback_path)
			else:
				pause_scene = load("res://scenes/JoyPauseScene.tscn")
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
		if pause_instance != null and ResourceLoader.exists(revised_bg_path2):
			var revised_tex2: Texture2D = load(revised_bg_path2) as Texture2D
			var pause_bg: TextureRect = pause_instance.get_node_or_null("Background") as TextureRect
			if pause_bg != null and revised_tex2 != null:
				pause_bg.texture = revised_tex2
			elif pause_instance != null and pause_instance.has_method("set_pause_background") and character_sprite != null:
				# fallback: previous behavior expected a character texture; keep that if no revised bg present
				pause_instance.call("set_pause_background", character_sprite.texture)
		add_child(pause_instance)
		_set_match_hud_visible(false)
		get_tree().paused = true

func _set_round_input_locked(locked: bool) -> void:
	_round_input_locked = locked
	if GameState != null and GameState.has_method("set_round_input_locked"):
		GameState.call("set_round_input_locked", locked)
	if pause_button != null:
		pause_button.disabled = locked
	if hint_button != null:
		hint_button.disabled = locked
	if music_button != null:
		music_button.disabled = locked
	if volume_button != null:
		volume_button.disabled = locked
	for draggable in draggable_labels:
		if draggable != null and draggable.label != null:
			draggable.label.mouse_filter = Control.MOUSE_FILTER_IGNORE if locked else Control.MOUSE_FILTER_STOP

func _on_hint_pressed() -> void:
	if _round_input_locked:
		return
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

func _set_match_hud_visible(visible: bool) -> void:
	if level_label != null:
		level_label.visible = visible
	if pause_button != null:
		pause_button.visible = visible
	if hint_button != null:
		hint_button.visible = visible
	if music_button != null:
		music_button.visible = visible
	if volume_button != null:
		volume_button.visible = visible
	var ui_root: Node = get_node_or_null("UI")
	if ui_root != null:
			_toggle_named_canvas_items(ui_root, visible)

func _toggle_named_canvas_items(node: Node, visible: bool) -> void:
	for child in node.get_children():
		if child is CanvasItem:
			var child_name := String(child.name).to_lower()
			if child_name.find("pause") != -1 or child_name.find("hint") != -1 or child_name.find("music") != -1 or child_name.find("volume") != -1 or child_name.find("sound") != -1:
				(child as CanvasItem).visible = visible
		_toggle_named_canvas_items(child, visible)

func _on_hint_close_requested() -> void:
	if hint_instance != null:
		hint_instance.queue_free()
		hint_instance = null
	get_tree().paused = false

func _build_word_hint_entries() -> Array[String]:
	var words: Array[String] = []
	for child in word_container.get_children():
		if child is Label:
			var word_text: String = String(child.text).strip_edges()
			if not word_text.is_empty():
				words.append(word_text)
	words = words.duplicate()
	words.sort_custom(func(a: String, b: String) -> bool:
		return a.to_lower() < b.to_lower()
	)
	return words

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

func _get_level_background_texture() -> Texture2D:
	var background: TextureRect = get_node_or_null("Background") as TextureRect
	if background != null:
		return background.texture
	return null

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
