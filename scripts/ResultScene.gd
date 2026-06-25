extends Control

@onready var compliment = $UI/Compliment
@onready var stars_cont = $UI/StarsContainer
@onready var level_label = $UI/LevelLabel
@onready var next_btn = $UI/NextButton
@onready var retry_btn = $UI/RetryButton
@onready var menu_btn = $UI/MenuButton
@onready var background = $Background
@onready var uibg = $UIBg
@onready var total_coin_label: Label = get_node_or_null("UI/CoinsContainer/CoinCounter") as Label
@onready var earned_coin_label: Label = get_node_or_null("CoinsEarned") as Label
@onready var earned_coin_icon: TextureRect = get_node_or_null("CoinsEarned/Coin") as TextureRect
@onready var party_popper_left: TextureRect = get_node_or_null("PartyPopperL") as TextureRect
@onready var party_popper_right: TextureRect = get_node_or_null("PartyPopperR") as TextureRect
var _result_sfx_played: bool = false
var _coins_applied: bool = false

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

func _scene_exists(path: String) -> bool:
	# In exported builds (Android), resources live in the PCK; ResourceLoader is the
	# reliable way to check for res:// scene availability.
	return ResourceLoader.exists(path) or FileAccess.file_exists(path)

func _get_game_scene_path(mode: String, level: int) -> String:
	# Safety: prevent fallback to Joy when character is lost
	if GameState.selected_character == "":
		GameState.selected_character = "joy"
		print("ResultScene: selected_character was empty → forced to 'joy'")
	
	var selected = GameState.selected_character.to_lower()
	var character = GameState.selected_character.capitalize()
	
	if character == "":
		character = "Joy"
		selected = "joy"
		print("ResultScene: selected_character empty, defaulting to Joy")
	
	if mode == "word":
		var path = "res://scenes/Word Matching/%s/%s%d.tscn" % [character, "Word" + character, level]
		if not _scene_exists(path):
			print("ResultScene: expected word scene not found: ", path)
			path = "res://scenes/Word Matching/Joy/WordJoy%d.tscn" % level
			print("ResultScene: falling back to: ", path)
		return path
	
	var mapping = emotion_map if mode == "emotion" else word_map
	var prefix = mapping.get(selected, {"prefix": "Game" + character}).get("prefix", "Game" + character)
	var mode_folder = "Emotion Matching" if mode == "emotion" else "Word Matching"
	var path = "res://scenes/%s/%s/%s%d.tscn" % [mode_folder, character, prefix, level]
	
	if not _scene_exists(path):
		print("ResultScene: expected scene not found: ", path)
		if mode == "word":
			path = "res://scenes/Word Matching/Joy/WordJoy1.tscn"
		else:
			path = "res://scenes/Emotion Matching/Joy/GameJoy1.tscn"
		print("ResultScene: fallback scene path: ", path)
	
	return path

func _get_level_select_scene_path(mode: String) -> String:
	var sel = GameState.selected_character.to_lower()
	var folder = GameState.selected_character.capitalize()
	var mode_folder = "Emotion Matching" if mode == "emotion" else "Word Matching"
	var suffix = "LevelSelect" if mode == "emotion" else "WordLevelSelect"
	var file_prefix = folder
	if sel == "sadness":
		file_prefix = "Sad"
	return "res://scenes/%s/%s/%s%s.tscn" % [mode_folder, folder, file_prefix, suffix]

func _ready() -> void:
	print("ResultScene ready – UI loaded")
	_apply_character_background()
	_apply_character_theme()
	
	if compliment:
		compliment.modulate.a = 0
		create_tween().bind_node(self).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).tween_property(compliment, "modulate:a", 1.0, 0.8)
	
	if next_btn: next_btn.pressed.connect(_on_next_pressed)
	if retry_btn: retry_btn.pressed.connect(_on_retry_pressed)
	if menu_btn: menu_btn.pressed.connect(_on_menu_pressed)
	if $UI/LevelButton:
		$UI/LevelButton.pressed.connect(_on_level_button_pressed)
	
	_update_display()

func _apply_character_background() -> void:
	if not background:
		return
	var sel = GameState.selected_character.to_lower()
	# Prefer the revised assets folder images named like 'Joy BG.png', 'Sad BG.png', etc.
	var prefix = "Sad" if sel == "sadness" else sel.capitalize()
	var revised_path = "res://assets/Revised Assets/%s BG.png" % prefix
	if ResourceLoader.exists(revised_path):
		var tex := load(revised_path)
		if tex:
			background.texture = tex
			return
	# Fallback to previous background map if revised asset is missing
	var bg_map := {
		"joy": "res://assets/background/Gemini_Generated_Image_o95efo95efo95efo.png",
		"sadness": "res://assets/background/Gemini_Generated_Image_w2zisxw2zisxw2zi.png",
		"anger": "res://assets/background/Gemini_Generated_Image_w2r2u8w2r2u8w2r2.png",
		"disgust": "res://assets/background/Gemini_Generated_Image_7260cn7260cn7260.png",
		"fear": "res://assets/background/Gemini_Generated_Image_mrznoemrznoemrzn.png",
	}
	var path: String = bg_map.get(sel, bg_map["joy"])
	var tex2 := load(path)
	if tex2:
		background.texture = tex2

func _apply_character_theme() -> void:
	var sel = GameState.selected_character.to_lower()
	if not uibg:
		pass
	# Match the per‑character pause UI boxes (colors/textures)
	var box_map := {
		"joy": "res://assets/UI/BoxesBanners/Box_Orange_Square.png",
		"sadness": "res://assets/UI/BoxesBanners/Box_Blue_Square1.png",
		"anger": "res://assets/UI/BoxesBanners/Box_Red_Square.png",
		"disgust": "res://assets/UI/BoxesBanners/Box_Green_Square.png",
		"fear": "res://assets/UI/BoxesBanners/Box_Purple_Square.png",
	}
	if uibg:
		var box_path: String = box_map.get(sel, box_map["joy"])
		var tex := load(box_path)
		if tex:
			uibg.texture = tex

	var level_label_color_map := {
		"joy": Color(1.0, 0.6431373, 0.07058824, 1.0),
		"sadness": Color(0.9607843, 0.9607843, 0.8627451, 1.0),
		"anger": Color(0.999999, 0.80594957, 0.80261725, 1.0),
		"disgust": Color(0.61, 1.0, 0.62950003, 1.0),
		"fear": Color(1.0, 1.0, 1.0, 1.0),
	}
	if level_label != null:
		level_label.add_theme_color_override("font_color", level_label_color_map.get(sel, level_label_color_map["joy"]))

func _update_display() -> void:
	var lives := ResultData.hearts_remaining
	var win := ResultData.is_win
	var did_clear_level: bool = (win and lives > 0)
	var current_mode := GameState.current_mode if "current_mode" in GameState else "emotion"
	if not _result_sfx_played and AudioManager != null:
		if did_clear_level:
			AudioManager.play_sfx("level_clear")
		elif GameState.current_mode != "story":
			AudioManager.play_sfx("level_failed")
		_result_sfx_played = true
	var stars_to_show = 0
	var coins_to_award = 0
	if did_clear_level and (current_mode == "emotion" or current_mode == "word"):
		stars_to_show = lives
		# Persist best stars and unlock next level for this mode/character,
		# regardless of which button the player clicks after.
		var current_level := GameState.current_level
		var cleared_character: String = String(GameState.selected_character).to_lower()
		var previous_best_stars: int = GameState.get_level_stars(current_level)
		var previous_best_coin_reward: int = _coins_for_stars(previous_best_stars)
		var current_coin_reward: int = _coins_for_stars(stars_to_show)
		coins_to_award = maxi(0, current_coin_reward - previous_best_coin_reward)
		GameState.set_level_stars(current_level, stars_to_show)
		GameState.process_progression_after_level_clear(current_mode, cleared_character, current_level)
		if current_level < 5:
			GameState.unlock_level(current_level + 1)

	ResultData.coins_earned = coins_to_award
	var total_before_award: int = GameState.coins
	if coins_to_award > 0 and not _coins_applied:
		GameState.add_coins(coins_to_award)
		_coins_applied = true
		if total_coin_label != null:
			total_before_award = maxi(0, GameState.coins - coins_to_award)
	_show_stars(stars_to_show)
	_update_coin_labels(total_before_award)

	if party_popper_left != null:
		party_popper_left.visible = did_clear_level
	if party_popper_right != null:
		party_popper_right.visible = did_clear_level
	if party_popper_left != null:
		party_popper_left.z_index = 10
	if party_popper_right != null:
		party_popper_right.z_index = 10
	
	if did_clear_level:
		match lives:
			3: compliment.text = "PERFECT!"
			2: compliment.text = "GREAT JOB!"
			1: compliment.text = "GOOD TRY!"
			_: compliment.text = "YOU DID IT!"
		# Play confetti animation on win
		_play_confetti_animation()
		if ResultData.coins_earned > 0:
			_play_result_coin_gain_animation(total_before_award, GameState.coins)
	else:
		compliment.text = "TRY AGAIN!"
	
	if next_btn:
		next_btn.visible = did_clear_level
	
	if level_label:
		level_label.text = "LEVEL " + str(GameState.current_level)

func _coins_for_stars(stars: int) -> int:
	match clampi(stars, 0, 3):
		1:
			return 1
		2:
			return 2
		3:
			return 3
		_:
			return 0

func _update_coin_labels(previous_total: int) -> void:
	if total_coin_label != null:
		total_coin_label.text = str(maxi(0, previous_total))
	if earned_coin_label != null:
		earned_coin_label.visible = ResultData.coins_earned > 0
		earned_coin_label.text = "+ %d" % ResultData.coins_earned
	if earned_coin_icon != null:
		earned_coin_icon.visible = ResultData.coins_earned > 0

func _play_result_coin_gain_animation(from_total: int, to_total: int) -> void:
	if total_coin_label != null:
		var tw_total: Tween = create_tween().bind_node(total_coin_label)
		tw_total.set_trans(Tween.TRANS_QUAD)
		tw_total.set_ease(Tween.EASE_OUT)
		tw_total.tween_method(_set_total_coin_count, float(from_total), float(to_total), 0.45)

	if earned_coin_label != null:
		earned_coin_label.modulate = Color(1, 1, 1, 0)
		earned_coin_label.scale = Vector2(0.75, 0.75)
		var tw_earned: Tween = create_tween().bind_node(earned_coin_label)
		tw_earned.set_trans(Tween.TRANS_BACK)
		tw_earned.set_ease(Tween.EASE_OUT)
		tw_earned.set_parallel(true)
		tw_earned.tween_property(earned_coin_label, "modulate:a", 1.0, 0.18)
		tw_earned.tween_property(earned_coin_label, "scale", Vector2.ONE, 0.2)

	if earned_coin_icon != null:
		earned_coin_icon.rotation = -0.2
		var tw_icon: Tween = create_tween().bind_node(earned_coin_icon)
		tw_icon.set_trans(Tween.TRANS_BACK)
		tw_icon.set_ease(Tween.EASE_OUT)
		tw_icon.tween_property(earned_coin_icon, "rotation", 0.0, 0.24)

func _set_total_coin_count(value: float) -> void:
	if total_coin_label != null:
		total_coin_label.text = str(int(round(value)))

func _show_stars(count: int) -> void:
	if not stars_cont:
		print("StarsContainer null!")
		return
	
	for i in stars_cont.get_child_count():
		stars_cont.get_child(i).visible = false
	
	for i in count:
		if i < stars_cont.get_child_count():
			var star = stars_cont.get_child(i)
			star.visible = true
			star.scale = Vector2.ZERO
			star.rotation = 0
			await get_tree().create_timer(0.3 * (i + 1)).timeout
			
			var tween = create_tween().bind_node(star).set_parallel(true)
			tween.set_trans(Tween.TRANS_ELASTIC)
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_property(star, "scale", Vector2(1, 1), 0.6)
			
			var spin_tween = create_tween().bind_node(star)
			spin_tween.set_trans(Tween.TRANS_LINEAR)
			spin_tween.tween_property(star, "rotation", TAU, 0.6)
	
	print("Showing ", count, " stars")

func _on_next_pressed():
	print("NEXT pressed - Win:", ResultData.is_win, " Level:", GameState.current_level, 
		" Mode:", GameState.current_mode, " Char:", GameState.selected_character)
	
	var player_won = ResultData.is_win
	var current_level = GameState.current_level
	var current_mode = GameState.current_mode if "current_mode" in GameState else "emotion"
	
	if current_mode != "emotion" and current_mode != "word":
		current_mode = "emotion"   # assuming emotion mode is default/fallback
		GameState.current_mode = current_mode
	
	# Advance level BEFORE reset (unlock already handled in _update_display)
	if player_won and current_level < 5:
		GameState.current_level = current_level + 1
		print("→ Advancing to Level ", GameState.current_level, " of ", current_mode)
	ResultData.reset()
	
	if player_won and current_level < 5:
		var scene_path = _get_game_scene_path(current_mode, GameState.current_level)
		print("Changing to next level → ", scene_path)
		await get_tree().process_frame   # helps mobile timing
		get_tree().change_scene_to_file(scene_path)
	
	elif player_won and current_level == 5:
		GameState.current_level = 1
		var scene_path = _get_level_select_scene_path(current_mode)
		await get_tree().process_frame
		get_tree().change_scene_to_file(scene_path)
	
	else:
		var scene_path = _get_level_select_scene_path(current_mode)
		await get_tree().process_frame
		get_tree().change_scene_to_file(scene_path)

func _on_retry_pressed():
	print("RETRY pressed; current_mode=", GameState.current_mode)
	ResultData.reset()
	var current_mode: String = GameState.current_mode if "current_mode" in GameState else "emotion"
	if current_mode != "emotion" and current_mode != "word":
		current_mode = "emotion"
		GameState.current_mode = current_mode
	var scene_path = _get_game_scene_path(current_mode, GameState.current_level)
	get_tree().change_scene_to_file(scene_path)

func _on_menu_pressed():
	print("MENU pressed")
	ResultData.reset()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_level_button_pressed():
	print("LEVEL BUTTON pressed on result")
	var current_mode: String = GameState.current_mode if "current_mode" in GameState else "emotion"
	var scene_path = _get_level_select_scene_path(current_mode)
	ResultData.reset()
	get_tree().change_scene_to_file(scene_path)

func _play_confetti_animation() -> void:
	# Create a celebration layer if it doesn't exist
	var celebration_layer: Control = get_node_or_null("ConfettiLayer")
	if celebration_layer == null:
		celebration_layer = Control.new()
		celebration_layer.name = "ConfettiLayer"
		celebration_layer.anchor_right = 1.0
		celebration_layer.anchor_bottom = 1.0
		celebration_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		celebration_layer.z_index = 30
		add_child(celebration_layer)
	
	# Center point for confetti burst
	var center_x: float = get_viewport_rect().size.x * 0.5
	var origin_y: float = get_viewport_rect().size.y * 0.3
	
	# Create 50 confetti pieces for a festive effect
	for i in range(50):
		var confetti: ColorRect = ColorRect.new()
		# Random bright colors for confetti
		confetti.color = Color.from_hsv(randf(), 0.8, 1.0, 1.0)
		confetti.custom_minimum_size = Vector2(8, 16)
		confetti.size = Vector2(8, 16)
		confetti.position = Vector2(center_x, origin_y)
		celebration_layer.add_child(confetti)
		
		# Random target position where confetti will land
		var target: Vector2 = Vector2(
			center_x + randf_range(-500.0, 500.0),
			origin_y + randf_range(150.0, 400.0)
		)
		
		# Animate confetti falling and spinning
		var tween: Tween = create_tween()
		tween.set_parallel(true)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(confetti, "position", target, 1.0)
		tween.tween_property(confetti, "rotation", randf_range(-2.6, 2.6), 1.0)
		tween.tween_property(confetti, "modulate:a", 0.0, 1.0)
		tween.finished.connect(func() -> void:
			if is_instance_valid(confetti):
				confetti.queue_free()
		)
	
	# Wait for animation to complete
	await get_tree().create_timer(1.05).timeout
