extends Control

const WORD_LEVEL_SELECT_SCENES := {
	"joy": "res://scenes/Word Matching/Joy/JoyWordLevelSelect.tscn",
	"sadness": "res://scenes/Word Matching/Sadness/SadWordLevelSelect.tscn",
	"anger": "res://scenes/Word Matching/Anger/AngerWordLevelSelect.tscn",
	"disgust": "res://scenes/Word Matching/Disgust/DisgustWordLevelSelect.tscn",
	"fear": "res://scenes/Word Matching/Fear/FearWordLevelSelect.tscn",
}

@onready var button_level1 = $ButtonLevel1
@onready var button_level2 = $ButtonLevel2
@onready var button_level3 = $ButtonLevel3
@onready var button_level4 = $ButtonLevel4
@onready var button_level5 = $ButtonLevel5
@onready var back_button = get_node_or_null("Back") as BaseButton
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

func _set_lock_icon_visible(button: Node, locked: bool) -> void:
	if button == null:
		return
	var lock_icon: CanvasItem = button.get_node_or_null("Lock Icon") as CanvasItem
	if lock_icon != null:
		lock_icon.visible = locked

func _ready():
	print("📝 Word Level Select for: ", GameState.selected_character)
	GameState.current_mode = "word"

	# Apply revised background if present on this Word Level Select scene
	var sel = GameState.selected_character.to_lower()
	var prefix = "Sad" if sel == "sadness" else sel.capitalize()
	var revised_path = "res://assets/Revised Assets/%s BG.png" % prefix
	var bg_node: TextureRect = get_node_or_null("Background") as TextureRect
	if bg_node != null and ResourceLoader.exists(revised_path):
		var tex := load(revised_path) as Texture2D
		if tex:
			bg_node.texture = tex

	# Animate buttons in and connect them
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

func _load_level(level: int):
	_on_level_pressed(level)

func _on_level_pressed(level: int):
	GameState.current_level = level
	print("📝 Word Level ", level, " SELECTED → Loading Word Game!")
	var character_sel = GameState.selected_character.capitalize()
	var scene_path = "res://scenes/Word Matching/%s/Word%s%d.tscn" % [character_sel, character_sel, level]
	print("📝 Loading word scene: ", scene_path)
	_change_scene_to_file(scene_path)

func _on_back_pressed():
	print("⬅️ Back to Word Character Select")
	_change_scene_to_file("res://scenes/WordCharacterSelect.tscn")

func _on_next_pressed() -> void:
	var next_character: String = _get_next_character(GameState.selected_character)
	if next_character.is_empty():
		next_character = "joy"
	GameState.selected_character = next_character
	GameState.current_mode = "word"
	_change_scene_to_file(String(WORD_LEVEL_SELECT_SCENES.get(next_character, WORD_LEVEL_SELECT_SCENES["joy"])))

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
