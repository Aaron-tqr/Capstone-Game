extends Control

@onready var joy_char = $JoyCharacter
@onready var sadness_char = $SadCharacter
@onready var anger_char = $AngerCharacter
@onready var disgust_char = $DisgustCharacter
@onready var fear_char = $FearCharacter
@onready var back_button = $Back

func _ready():
	_connect_click(joy_char, "joy")
	_connect_click(sadness_char, "sadness")
	_connect_click(anger_char, "anger")
	_connect_click(disgust_char, "disgust")
	_connect_click(fear_char, "fear")
	
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

func _on_character_gui_input(event: InputEvent, character: String):
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or \
	   (event is InputEventScreenTouch and event.pressed):
		GameState.selected_character = character
		print("📝 Word Mode: ", character.to_upper())
		
		var char_capitalized = character.capitalize()
		var scene_path = "res://scenes/Word Matching/%s/%sWordLevelSelect.tscn" % [char_capitalized, char_capitalized]
		# Special-case Sadness: scene is named SadWordLevelSelect.tscn
		if character == "sadness":
			scene_path = "res://scenes/Word Matching/Sadness/SadWordLevelSelect.tscn"
		print("Loading: ", scene_path)
		
		# Capture tree reference before scene change
		var tree = get_tree()
		await tree.process_frame
		tree.change_scene_to_file(scene_path)

func _on_back_pressed():
	var tree = get_tree()
	await tree.process_frame
	tree.change_scene_to_file("res://scenes/ModeSelect.tscn")
