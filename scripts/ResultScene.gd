extends Control

@onready var compliment   = $UI/Compliment
@onready var stars_cont   = $UI/StarsContainer
@onready var level_label  = $UI/LevelLabel
@onready var next_btn     = $UI/NextButton
@onready var retry_btn    = $UI/RetryButton
@onready var menu_btn     = $UI/MenuButton

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
	var selected = GameState.selected_character.to_lower()
	var character = GameState.selected_character.capitalize()
	if character == "":
		character = "Joy"
		selected = "joy"
		print("ResultScene: selected_character empty, defaulting to Joy")

	if mode == "word":
		var path = "res://scenes/Word Matching/%s/Word%s%d.tscn" % [character, character, level]
		if not FileAccess.file_exists(path):
			print("ResultScene: expected word scene not found: ", path)
			# Fallback to default character
			path = "res://scenes/Word Matching/Joy/WordJoy%d.tscn" % level
			print("ResultScene: falling back to: ", path)
		return path

	var sel = selected
	var folder = character
	var mapping = emotion_map if mode == "emotion" else word_map
	var prefix = mapping.get(sel, {"prefix": "Game" + folder}).get("prefix", "Game" + folder)
	var mode_folder = "Emotion Matching" if mode == "emotion" else "Word Matching"
	var path = "res://scenes/%s/%s/%s%d.tscn" % [mode_folder, folder, prefix, level]
	if not FileAccess.file_exists(path):
		print("ResultScene: expected scene not found: ", path)
		# fallback to first level in same mode
		if mode == "word":
			path = "res://scenes/Word Matching/Joy/WordJoy1.tscn"
		else:
			path = "res://scenes/Emotion Matching/Joy/GameJoy1.tscn"
		print("ResultScene: fallback scene path: ", path)
	return path

func _get_level_select_scene_path(mode: String) -> String:
	# Determine folder and prefix; sadness uses "Sad" instead of full name
	var sel = GameState.selected_character.to_lower()
	var folder = GameState.selected_character.capitalize()
	var mode_folder = "Emotion Matching" if mode == "emotion" else "Word Matching"
	var suffix = "LevelSelect" if mode == "emotion" else "WordLevelSelect"
	var file_prefix = folder
	if sel == "sadness":
		# scenes are named SadLevelSelect / SadWordLevelSelect
		file_prefix = "Sad"
	return "res://scenes/%s/%s/%s%s.tscn" % [mode_folder, folder, file_prefix, suffix]

func _ready() -> void:
	print("ResultScene ready – UI loaded")
	
	# Fade in compliment
	if compliment:
		compliment.modulate.a = 0
		create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).tween_property(compliment, "modulate:a", 1.0, 0.8)
	
	if next_btn:   next_btn.pressed.connect(_on_next_pressed)
	if retry_btn:  retry_btn.pressed.connect(_on_retry_pressed)
	if menu_btn:   menu_btn.pressed.connect(_on_menu_pressed)
	
	_update_display()

func _update_display() -> void:
	var lives := ResultData.hearts_remaining
	var win   := ResultData.is_win

	var stars_to_show = 0
	if win and lives > 0:
		stars_to_show = lives

	_show_stars(stars_to_show)

	if win and lives > 0:
		match lives:
			3: compliment.text = "PERFECT!"
			2: compliment.text = "GREAT JOB!"
			1: compliment.text = "GOOD TRY!"
			_: compliment.text = "YOU DID IT!"
	else:
		compliment.text = "TRY AGAIN!"

	if next_btn:
		next_btn.visible = (win and lives > 0)
	if level_label:
		level_label.text = "LEVEL " + str(GameState.current_level)

func _show_stars(count: int) -> void:
	if not stars_cont:
		print("StarsContainer null!")
		return

	for i in stars_cont.get_child_count():
		stars_cont.get_child(i).visible = false

	# Animate stars appearing one by one with rotation and scale
	for i in count:
		if i < stars_cont.get_child_count():
			var star = stars_cont.get_child(i)
			star.visible = true
			star.scale = Vector2.ZERO
			star.rotation = 0
			
			await get_tree().create_timer(0.3 * (i + 1)).timeout
			
			# Spin and scale in animation
			var tween = create_tween()
			tween.set_parallel(true)
			tween.set_trans(Tween.TRANS_ELASTIC)
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_property(star, "scale", Vector2(1, 1), 0.6)
			
			var spin_tween = create_tween()
			spin_tween.set_trans(Tween.TRANS_LINEAR)
			spin_tween.tween_property(star, "rotation", TAU, 0.6)
	
	print("Showing ", count, " stars")

func _is_expected_scene_script(scene_path: String, mode: String) -> bool:
	var res = ResourceLoader.load(scene_path)
	if not res or not res is PackedScene:
		print("ResultScene: failed to load PackedScene for validation: ", scene_path)
		return false
	var instance = res.instantiate()
	var script = instance.get_script()
	if not script:
		print("ResultScene: scene has no script: ", scene_path)
		return false
	var script_path = script.resource_path
	if mode == "word":
		if script_path.find("WordJoy") == -1 and script_path.find("WordSad") == -1 and script_path.find("WordAnger") == -1 and script_path.find("WordDisgust") == -1 and script_path.find("WordFear") == -1:
			print("ResultScene: unexpected script for word mode: ", script_path)
			return false
	return true

func _on_next_pressed():
	print("NEXT pressed - is_win: ", ResultData.is_win, " current_level: ", GameState.current_level, " current_mode: ", GameState.current_mode)
	
	# Check win status BEFORE resetting
	var player_won: bool = ResultData.is_win
	var current_level: int = GameState.current_level
	var current_mode: String = GameState.current_mode if "current_mode" in GameState else "emotion"
	if current_mode != "emotion" and current_mode != "word":
		current_mode = "word" if GameState.selected_character != "" else "emotion"
		GameState.current_mode = current_mode
		print("ResultScene: current_mode fallback to: ", current_mode)
	
	# Now reset
	ResultData.reset()
	
	# Unlock next level if player won
	if player_won and current_level < 5:
		GameState.current_level = current_level + 1
		GameState.unlock_level(GameState.current_level)
		print("Advanced to level: ", GameState.current_level)
	
		# Load appropriate scene based on mode
		var scene_path = _get_game_scene_path(current_mode, GameState.current_level)
		print("ResultScene: changing to scene: ", scene_path)
		if not _is_expected_scene_script(scene_path, current_mode):
			print("ResultScene: invalid script in target scene, falling back to default word scene")
			GameState.current_level = max(GameState.current_level, 1)
			scene_path = _get_game_scene_path("word", GameState.current_level)
			print("ResultScene: fallback path: ", scene_path)
		get_tree().change_scene_to_file(scene_path)
	elif player_won and current_level == 5:
		# All levels completed
		GameState.current_level = 1
		var scene_path = _get_level_select_scene_path(current_mode)
		get_tree().change_scene_to_file(scene_path)
	else:
		# Lost, go back to level select
		var scene_path = _get_level_select_scene_path(current_mode)
		get_tree().change_scene_to_file(scene_path)

func _on_retry_pressed():
	print("RETRY pressed; current_mode=", GameState.current_mode)
	ResultData.reset()
	
	var current_mode: String = GameState.current_mode if "current_mode" in GameState else "emotion"
	if current_mode != "emotion" and current_mode != "word":
		current_mode = "word" if GameState.selected_character != "" else "emotion"
		GameState.current_mode = current_mode
	var scene_path = _get_game_scene_path(current_mode, GameState.current_level)
	get_tree().change_scene_to_file(scene_path)

func _on_menu_pressed():
	print("MENU pressed")
	ResultData.reset()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
