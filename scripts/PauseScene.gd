extends Control

@onready var resume_btn = $UI/ResumeButton
@onready var retry_btn  = $UI/RetryButton
@onready var next_btn   = $UI/NextButton
@onready var menu_btn   = $UI/MenuButton
@onready var level_btn  = $UI/LevelButton
@onready var background = $Background
@onready var uibg = $UIBg
@onready var level_label = $UI/LevelLabel

var _custom_background_texture: Texture2D = null

# CanvasItems we temporarily hide while paused (word mode).
var _hidden_during_pause: Array[CanvasItem] = []
var _hidden_buttons_during_pause: Array[CanvasItem] = []

# Emotion and Word game file mappings
var emotion_map = {
	"joy": {"prefix": "GameJoy"},
	"sadness": {"prefix": "GameSad"},
	"anger": {"prefix": "GameAnger"},
	"disgust": {"prefix": "GameDisgust"},
	"fear": {"prefix": "GameFear"},
}
var word_map = {
	"joy": {"prefix": "WordJoy"},
	"sadness": {"prefix": "WordSad"},
	"anger": {"prefix": "WordAnger"},
	"disgust": {"prefix": "WordDisgust"},
	"fear": {"prefix": "WordFear"},
}

func _get_game_scene_path(mode: String, level: int) -> String:
	var sel = GameState.selected_character.to_lower()
	var folder = GameState.selected_character.capitalize()
	var mapping = emotion_map if mode == "emotion" else word_map
	var prefix = mapping.get(sel, {"prefix": "Game" + folder}).get("prefix", "Game" + folder)
	var mode_folder = "Emotion Matching" if mode == "emotion" else "Word Matching"
	return "res://scenes/%s/%s/%s%d.tscn" % [mode_folder, folder, prefix, level]

func _get_level_select_scene_path(mode: String) -> String:
	var sel = GameState.selected_character.to_lower()
	var folder = GameState.selected_character.capitalize()
	var mode_folder = "Emotion Matching" if mode == "emotion" else "Word Matching"
	# Word level-select scenes are named like JoyWordLevelSelect, except Sadness uses SadWordLevelSelect.
	if mode == "word":
		var prefix = "Sad" if sel == "sadness" else folder
		return "res://scenes/%s/%s/%sWordLevelSelect.tscn" % [mode_folder, folder, prefix]
	# Emotion level-select scenes are named like JoyLevelSelect, except Sadness uses SadLevelSelect.
	var prefix = "Sad" if sel == "sadness" else folder
	return "res://scenes/%s/%s/%sLevelSelect.tscn" % [mode_folder, folder, prefix]

func _apply_character_background() -> void:
	# Keep the texture configured in each PauseScene .tscn.
	# Runtime should not override scene-authored pause backgrounds.
	return

func _apply_character_theme() -> void:
	var sel = GameState.selected_character.to_lower()
	var color_map := {
		"joy": Color(1.0, 0.9, 0.5, 1.0),
		"sadness": Color(0.6, 0.75, 1.0, 1.0),
		"anger": Color(1.0, 0.55, 0.55, 1.0),
		"disgust": Color(0.6, 1.0, 0.6, 1.0),
		"fear": Color(0.9, 0.7, 1.0, 1.0),
	}
	var level_label_color_map := {
		"joy": Color(1.0, 0.6431373, 0.07058824, 1.0),
		"sadness": Color(0.9607843, 0.9607843, 0.8627451, 1.0),
		"anger": Color(0.999999, 0.80594957, 0.80261725, 1.0),
		"disgust": Color(0.61, 1.0, 0.62950003, 1.0),
		"fear": Color(1.0, 1.0, 1.0, 1.0),
	}
	if uibg:
		# Keep texture but tint it to match the character vibe.
		uibg.modulate = color_map.get(sel, color_map["joy"])
	if level_label:
		level_label.add_theme_color_override("font_color", level_label_color_map.get(sel, level_label_color_map["joy"]))

func set_pause_background(texture: Texture2D) -> void:
	# Intentionally ignored so pause scene background matches editor setup.
	_custom_background_texture = texture

func _ready() -> void:
	# Ensure this overlay (and its children) still receive input while the tree is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("PAUSE SCENE READY!")
	print("Resume: ", resume_btn != null)
	print("Retry:  ", retry_btn != null)
	print("Next:   ", next_btn != null)
	print("Menu:   ", menu_btn != null)
	print("Level:  ", level_btn != null)
	
	_apply_character_background()
	_apply_character_theme()
	if level_label:
		level_label.text = "LEVEL " + str(GameState.current_level)

	_hide_underlying_hint_and_music_buttons()
	_hide_underlying_word_ui_if_needed()
	
	if resume_btn: resume_btn.pressed.connect(_on_resume)
	if retry_btn:  retry_btn.pressed.connect(_on_retry)
	if next_btn:   next_btn.pressed.connect(_on_next)
	if menu_btn:   menu_btn.pressed.connect(_on_menu)
	if level_btn:  level_btn.pressed.connect(_on_level)

func _hide_underlying_hint_and_music_buttons() -> void:
	var owner := get_parent()
	if owner == null:
		return
	var names := ["HintButton", "MusicButton", "LevelLabel"]
	for n in names:
		var btn := owner.find_child(n, true, false)
		if btn is CanvasItem and (btn as CanvasItem).visible:
			_hidden_buttons_during_pause.append(btn as CanvasItem)
			(btn as CanvasItem).visible = false

func _hide_underlying_word_ui_if_needed() -> void:
	var mode := GameState.current_mode if "current_mode" in GameState else "emotion"
	if mode != "word":
		return
	var owner := get_parent()
	if owner == null:
		return
	var candidates: Array[CanvasItem] = []
	_collect_word_like_canvas_items(owner, candidates)
	for item in candidates:
		if is_instance_valid(item) and item.visible:
			_hidden_during_pause.append(item)
			item.visible = false

func _collect_word_like_canvas_items(node: Node, out: Array[CanvasItem]) -> void:
	for child in node.get_children():
		if child is CanvasItem:
			var n := String(child.name)
			# Word-matching scenes name these labels Word1/Word2/Word3, etc.
			if n.begins_with("Word"):
				out.append(child)
		_collect_word_like_canvas_items(child, out)

func _restore_hidden_underlying_ui() -> void:
	for item in _hidden_during_pause:
		if is_instance_valid(item):
			item.visible = true
	_hidden_during_pause.clear()
	for item in _hidden_buttons_during_pause:
		if is_instance_valid(item):
			item.visible = true
	_hidden_buttons_during_pause.clear()

func _on_resume():
	print("RESUME PRESSED")
	_restore_hidden_underlying_ui()
	get_parent()._on_pause_pressed()

func _on_retry():
	print("RETRY PRESSED")
	# Reload the current game scene based on mode and selected character
	var mode = GameState.current_mode if "current_mode" in GameState else "emotion"
	var scene_path = _get_game_scene_path(mode, GameState.current_level)
	var tree := get_tree()
	if tree:
		tree.paused = false
		tree.change_scene_to_file(scene_path)

func _on_next():
	print("NEXT PRESSED")
	# Go to next level IF it is already unlocked; otherwise stay on current level.
	var mode = GameState.current_mode if "current_mode" in GameState else "emotion"
	var next_lvl = min(GameState.current_level + 1, 5)
	if GameState.is_level_unlocked(next_lvl) and next_lvl != GameState.current_level:
		GameState.current_level = next_lvl
	else:
		next_lvl = GameState.current_level
	var scene_path = _get_game_scene_path(mode, next_lvl)
	var tree := get_tree()
	if tree:
		tree.paused = false
		tree.change_scene_to_file(scene_path)

func _on_menu():
	print("MENU PRESSED")
	var tree := get_tree()
	if tree:
		tree.paused = false
		tree.change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_level():
	print("LEVEL PRESSED → Level Select")
	var mode = GameState.current_mode if "current_mode" in GameState else "emotion"
	var tree := get_tree()
	if tree:
		tree.paused = false
		tree.change_scene_to_file(_get_level_select_scene_path(mode))
