extends Control

@onready var resume_btn = $UI/ResumeButton
@onready var retry_btn  = $UI/RetryButton
@onready var next_btn   = $UI/NextButton
@onready var menu_btn   = $UI/MenuButton

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

func _ready() -> void:
	print("PAUSE SCENE READY!")
	print("Resume: ", resume_btn != null)
	print("Retry:  ", retry_btn != null)
	print("Next:   ", next_btn != null)
	print("Menu:   ", menu_btn != null)
	
	if resume_btn: resume_btn.pressed.connect(_on_resume)
	if retry_btn:  retry_btn.pressed.connect(_on_retry)
	if next_btn:   next_btn.pressed.connect(_on_next)
	if menu_btn:   menu_btn.pressed.connect(_on_menu)

func _on_resume():
	print("RESUME PRESSED")
	get_parent()._on_pause_pressed()

func _on_retry():
	print("RETRY PRESSED")
	# Reload the current game scene based on mode and selected character
	var mode = GameState.current_mode if "current_mode" in GameState else "emotion"
	var scene_path = _get_game_scene_path(mode, GameState.current_level)
	get_tree().change_scene_to_file(scene_path)

func _on_next():
	print("NEXT PRESSED")
	# Go to next level (if exists) for current mode/character
	var mode = GameState.current_mode if "current_mode" in GameState else "emotion"
	var next_lvl = min(GameState.current_level + 1, 5)
	var scene_path = _get_game_scene_path(mode, next_lvl)
	get_tree().change_scene_to_file(scene_path)

func _on_menu():
	print("MENU PRESSED")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
