extends Control

const StyledPopup = preload("res://scripts/StyledPopup.gd")

@onready var joy_char = $JoyCharacter
@onready var sadness_char = $SadCharacter
@onready var anger_char = $AngerCharacter
@onready var disgust_char = $DisgustCharacter
@onready var fear_char = $FearCharacter
@onready var back_button = $Back

var _character_nodes := {}

func _ready():
	_connect_click(joy_char, "joy")
	_connect_click(sadness_char, "sadness")
	_connect_click(anger_char, "anger")
	_connect_click(disgust_char, "disgust")
	_connect_click(fear_char, "fear")
	_character_nodes = {
		"joy": joy_char,
		"sadness": sadness_char,
		"anger": anger_char,
		"disgust": disgust_char,
		"fear": fear_char,
	}
	_apply_lock_visuals()
	
	back_button.pressed.connect(_on_back_pressed)
	
	# Animate in all characters
	var characters = [joy_char, sadness_char, anger_char, disgust_char, fear_char]
	for i in range(characters.size()):
		var character_item = characters[i]
		if character_item:
			character_item.modulate.a = 0
			character_item.scale = Vector2(0.8, 0.8)
			await get_tree().create_timer(0.1 * i).timeout
			var tween = create_tween()
			tween.set_parallel(true)
			tween.set_trans(Tween.TRANS_QUAD)
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_property(character_item, "modulate:a", 1.0, 0.4)
			tween.tween_property(character_item, "scale", Vector2(1.0, 1.0), 0.4)
			_create_float_bob(character_item, 2.0, 15.0)
	
	# Animate back button
	back_button.modulate.a = 0
	back_button.scale = Vector2(0.9, 0.9)
	var back_tween = create_tween()
	back_tween.set_parallel(true)
	back_tween.set_trans(Tween.TRANS_QUAD)
	back_tween.set_ease(Tween.EASE_OUT)
	back_tween.tween_property(back_button, "modulate:a", 1.0, 0.4)
	back_tween.tween_property(back_button, "scale", Vector2(1.0, 1.0), 0.4)

func _connect_click(node: Control, character: String):
	if node:
		node.mouse_filter = Control.MOUSE_FILTER_STOP
		node.gui_input.connect(_on_character_gui_input.bind(character))

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

func _on_character_gui_input(event: InputEvent, character: String):
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or \
	   (event is InputEventScreenTouch and event.pressed):
		if not GameState.is_emotion_character_unlocked(character, "word"):
			_show_locked_warning("This character is locked in Word Matching.")
			return
		GameState.selected_character = character
		print("📝 Word Mode: ", character.to_upper())
		
		var char_capitalized = character.capitalize()
		var scene_path = "res://scenes/Word Matching/%s/%sWordLevelSelect.tscn" % [char_capitalized, char_capitalized]
		# Special-case Sadness: scene is named SadWordLevelSelect.tscn
		if character == "sadness":
			scene_path = "res://scenes/Word Matching/Sadness/SadWordLevelSelect.tscn"
		print("Loading: ", scene_path)
		
		_change_scene_to_file(scene_path)

func _on_back_pressed():
	_change_scene_to_file("res://scenes/ModeSelect.tscn")

func _change_scene_to_file(scene_path: String) -> void:
	var transition_node: Node = get_node_or_null("/root/SceneTransition")
	if transition_node and transition_node.has_method("change_scene_to_file"):
		transition_node.call("change_scene_to_file", scene_path)
		return
	get_tree().change_scene_to_file(scene_path)

func _apply_lock_visuals() -> void:
	for key in _character_nodes.keys():
		var node: CanvasItem = _character_nodes[key] as CanvasItem
		if node == null:
			continue
		var unlocked: bool = GameState.is_emotion_character_unlocked(String(key), "word")
		node.modulate = Color(1, 1, 1, 1) if unlocked else Color(0.45, 0.45, 0.45, 0.95)
		_set_lock_icon_visible(node, not unlocked)

func _set_lock_icon_visible(container: Node, locked: bool) -> void:
	if container == null:
		return
	var lock_icon: CanvasItem = container.get_node_or_null("Lock Icon") as CanvasItem
	if lock_icon != null:
		lock_icon.visible = locked

func _show_locked_warning(message: String) -> void:
	StyledPopup.open_popup(self, "CHARACTER LOCKED", message, "OK", Color(1.0, 0.5, 0.3, 1.0))
