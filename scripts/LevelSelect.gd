extends Control

const EMOTION_GAME_SCENES := {
	"joy": {
		1: preload("res://scenes/Emotion Matching/Joy/GameJoy1.tscn"),
		2: preload("res://scenes/Emotion Matching/Joy/GameJoy2.tscn"),
		3: preload("res://scenes/Emotion Matching/Joy/GameJoy3.tscn"),
		4: preload("res://scenes/Emotion Matching/Joy/GameJoy4.tscn"),
		5: preload("res://scenes/Emotion Matching/Joy/GameJoy5.tscn"),
	},
	"sadness": {
		1: preload("res://scenes/Emotion Matching/Sadness/GameSad1.tscn"),
		2: preload("res://scenes/Emotion Matching/Sadness/GameSad2.tscn"),
		3: preload("res://scenes/Emotion Matching/Sadness/GameSad3.tscn"),
		4: preload("res://scenes/Emotion Matching/Sadness/GameSad4.tscn"),
		5: preload("res://scenes/Emotion Matching/Sadness/GameSad5.tscn"),
	},
	"anger": {
		1: preload("res://scenes/Emotion Matching/Anger/GameAnger1.tscn"),
		2: preload("res://scenes/Emotion Matching/Anger/GameAnger2.tscn"),
		3: preload("res://scenes/Emotion Matching/Anger/GameAnger3.tscn"),
		4: preload("res://scenes/Emotion Matching/Anger/GameAnger4.tscn"),
		5: preload("res://scenes/Emotion Matching/Anger/GameAnger5.tscn"),
	},
	"disgust": {
		1: preload("res://scenes/Emotion Matching/Disgust/GameDisgust1.tscn"),
		2: preload("res://scenes/Emotion Matching/Disgust/GameDisgust2.tscn"),
		3: preload("res://scenes/Emotion Matching/Disgust/GameDisgust3.tscn"),
		4: preload("res://scenes/Emotion Matching/Disgust/GameDisgust4.tscn"),
		5: preload("res://scenes/Emotion Matching/Disgust/GameDisgust5.tscn"),
	},
	"fear": {
		1: preload("res://scenes/Emotion Matching/Fear/GameFear1.tscn"),
		2: preload("res://scenes/Emotion Matching/Fear/GameFear2.tscn"),
		3: preload("res://scenes/Emotion Matching/Fear/GameFear3.tscn"),
		4: preload("res://scenes/Emotion Matching/Fear/GameFear4.tscn"),
		5: preload("res://scenes/Emotion Matching/Fear/GameFear5.tscn"),
	},
}

const EMOTION_LEVEL_SELECT_SCENES := {
	"joy": "res://scenes/Emotion Matching/Joy/JoyLevelSelect.tscn",
	"sadness": "res://scenes/Emotion Matching/Sadness/SadLevelSelect.tscn",
	"anger": "res://scenes/Emotion Matching/Anger/AngerLevelSelect.tscn",
	"disgust": "res://scenes/Emotion Matching/Disgust/DisgustLevelSelect.tscn",
	"fear": "res://scenes/Emotion Matching/Fear/FearLevelSelect.tscn",
}

@onready var button_level1 = $ButtonLevel1
@onready var button_level2 = $ButtonLevel2
@onready var button_level3 = $ButtonLevel3
@onready var button_level4 = $ButtonLevel4
@onready var button_level5 = $ButtonLevel5
@onready var back_button   = $"Back"
@onready var next_button: BaseButton = get_node_or_null("NextBg/Next") as BaseButton

func _find_stars_container(level_num: int) -> Node:
	# Common layouts used across scenes (some have stars under Back/UI by mistake)
	var cont: Node = get_node_or_null("UI/StarsContainer%d" % level_num)
	if cont == null:
		cont = get_node_or_null("StarsContainer%d" % level_num)
	if cont == null:
		cont = get_node_or_null("Back/UI/StarsContainer%d" % level_num)
	if cont == null:
		# Fallback: search anywhere in scene tree.
		cont = find_child("StarsContainer%d" % level_num, true, false)
	return cont

func _apply_level_stars(level_num: int, stars: int) -> void:
	# New layout: StarsContainer1..5 at scene root or under UI
	var cont: Node = _find_stars_container(level_num)
	if cont:
		cont.visible = (stars > 0)
		for j in range(cont.get_child_count()):
			var star_node = cont.get_child(j)
			star_node.visible = (stars > 0 and j < stars)
		return
	
	# Old layout: Stars node inside each button
	var buttons := [button_level1, button_level2, button_level3, button_level4, button_level5]
	if level_num < 1 or level_num > buttons.size():
		return
	var btn: Node = buttons[level_num - 1]
	var star_container: Node = btn.get_node_or_null("Stars")
	if star_container:
		star_container.visible = (stars > 0)
		for j in range(star_container.get_child_count()):
			var star_node = star_container.get_child(j)
			star_node.visible = (stars > 0 and j < stars)

func _ready():
	# Ensure stars/unlocks resolve for the right game mode
	GameState.current_mode = "emotion"

	# Apply revised background for this character's level select if available
	var sel = GameState.selected_character.to_lower()
	var prefix = "Sad" if sel == "sadness" else sel.capitalize()
	var revised_path = "res://assets/Revised Assets/%s BG.png" % prefix
	var bg_node: TextureRect = get_node_or_null("Background") as TextureRect
	if bg_node != null and ResourceLoader.exists(revised_path):
		var tex := load(revised_path) as Texture2D
		if tex:
			bg_node.texture = tex
	
	# Animate buttons in
	var level_buttons = [button_level1, button_level2, button_level3, button_level4, button_level5]
	
	for i in range(level_buttons.size()):
		var btn = level_buttons[i]
		var level_num = i + 1
		btn.scale = Vector2(0.9, 0.9)
		btn.modulate.a = 0
		
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_BOUNCE)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(btn, "scale", Vector2(1, 1), 0.5)
		tween.tween_property(btn, "modulate:a", 1.0, 0.5)
		
		# Check if level is unlocked for current mode/character
		if GameState.is_level_unlocked(level_num):
			btn.disabled = false
			btn.modulate = Color.WHITE
			_set_lock_icon_visible(btn, false)
			btn.pressed.connect(func(): _on_level_pressed(level_num))
		else:
			btn.disabled = true
			btn.modulate = Color(0.5, 0.5, 0.5)
			_set_lock_icon_visible(btn, true)
		
		# Show stars earned for this level (per mode/character)
		var stars = GameState.get_level_stars(level_num)
		_apply_level_stars(level_num, stars)
	
	# Back button
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	if next_button:
		next_button.pressed.connect(_on_next_pressed)

func _on_level_pressed(level: int):
	GameState.current_level = level
	print("🌟 LEVEL ", level, " SELECTED → Loading GameJoy!")
	var sel = GameState.selected_character.to_lower()
	var packed_scene: PackedScene = EMOTION_GAME_SCENES.get(sel, {}).get(level, null)

	# Some mobile hangs look like "change_scene did nothing"; also guarantee the tree isn't paused.
	var tree := get_tree()
	if tree:
		tree.paused = false

	if packed_scene:
		print("LevelSelect: using preloaded scene for char=", sel, " level=", level, " => ", packed_scene.resource_path)
		_change_scene_to_packed(packed_scene)
		return

	# Fallback (should not normally happen if all scenes are preloaded).
	var mapping := {
		"joy": {"folder": "Joy", "prefix": "GameJoy"},
		"sadness": {"folder": "Sadness", "prefix": "GameSad"},
		"anger": {"folder": "Anger", "prefix": "GameAnger"},
		"disgust": {"folder": "Disgust", "prefix": "GameDisgust"},
		"fear": {"folder": "Fear", "prefix": "GameFear"},
	}
	var info = mapping.get(sel, {"folder": sel.capitalize(), "prefix": "Game" + sel.capitalize()})
	var scene_path = "res://scenes/Emotion Matching/%s/%s%d.tscn" % [info["folder"], info["prefix"], level]
	print("WARNING: Emotion scene not preloaded, falling back to path:", scene_path)
	_change_scene_to_file(scene_path)

func _on_back_pressed():
	print("⬅️ Back to Character Select")
	_change_scene_to_file("res://scenes/EmotionCharacterSelect.tscn")

func _on_next_pressed() -> void:
	var next_character: String = _get_next_character(GameState.selected_character)
	if next_character.is_empty():
		next_character = "joy"
	GameState.selected_character = next_character
	GameState.current_mode = "emotion"
	_change_scene_to_file(String(EMOTION_LEVEL_SELECT_SCENES.get(next_character, EMOTION_LEVEL_SELECT_SCENES["joy"])))

func _get_next_character(character_name: String) -> String:
	var chain: Array[String] = GameState.EMOTION_CHAIN
	var current_key: String = character_name.to_lower()
	var current_index: int = chain.find(current_key)
	if current_index == -1:
		return "joy"
	return chain[(current_index + 1) % chain.size()]

func _change_scene_to_file(scene_path: String) -> void:
	var transition_node: Node = get_node_or_null("/root/SceneTransition")
	if transition_node and transition_node.has_method("change_scene_to_file"):
		transition_node.call("change_scene_to_file", scene_path)
		return
	get_tree().change_scene_to_file(scene_path)

func _change_scene_to_packed(packed_scene: PackedScene) -> void:
	var transition_node: Node = get_node_or_null("/root/SceneTransition")
	if transition_node and transition_node.has_method("change_scene_to_packed"):
		transition_node.call("change_scene_to_packed", packed_scene)
		return
	get_tree().change_scene_to_packed(packed_scene)

func _set_lock_icon_visible(container: Node, locked: bool) -> void:
	if container == null:
		return
	var lock_icon: CanvasItem = container.get_node_or_null("Lock Icon") as CanvasItem
	if lock_icon != null:
		lock_icon.visible = locked
