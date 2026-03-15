extends Control

@onready var joy_char = $JoyCharacter
@onready var sadness_char = $SadCharacter
@onready var anger_char = $AngerCharacter
@onready var disgust_char = $DisgustCharacter
@onready var fear_char = $FearCharacter

func _ready():
	# Animate in characters
	var characters = [joy_char, sadness_char, anger_char, disgust_char, fear_char]
	
	for character in characters:
		if character:
			character.scale = Vector2(0.8, 0.8)
			character.modulate.a = 0
			
			var tween = create_tween()
			tween.set_trans(Tween.TRANS_BOUNCE)
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_property(character, "scale", Vector2(1, 1), 0.5)
			tween.tween_property(character, "modulate:a", 1.0, 0.5)
			
			# Float bob animation for each character
			_create_float_bob(character, 2.0, 15.0)
	
	_connect_click(joy_char, "joy")
	_connect_click(sadness_char, "sadness")
	_connect_click(anger_char, "anger")
	_connect_click(disgust_char, "disgust")
	_connect_click(fear_char, "fear")

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

func _connect_click(node: Control, character: String):
	if node:
		node.mouse_filter = Control.MOUSE_FILTER_STOP
		node.gui_input.connect(func(event):
			if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or \
			   (event is InputEventScreenTouch and event.pressed):
				# Play click animation
				var tween = create_tween()
				tween.set_trans(Tween.TRANS_BOUNCE)
				tween.set_ease(Tween.EASE_OUT)
				tween.tween_property(node, "scale", Vector2(1.2, 1.2), 0.2)
				await get_tree().create_timer(0.2).timeout
				
				# Capture tree reference before scene change
				var tree = get_tree()
				GameState.selected_character = character
				print("🎮 Selected: ", character.to_upper(), " → LevelSelect!")
				
				var sel = character.to_lower()
				var mapping = {
					"joy": {"folder": "Joy", "file": "JoyLevelSelect.tscn"},
					"sadness": {"folder": "Sadness", "file": "SadLevelSelect.tscn"},
					"anger": {"folder": "Anger", "file": "AngerLevelSelect.tscn"},
					"disgust": {"folder": "Disgust", "file": "DisgustLevelSelect.tscn"},
					"fear": {"folder": "Fear", "file": "FearLevelSelect.tscn"},
				}
				var info = mapping.get(sel, {"folder": sel.capitalize(), "file": sel.capitalize() + "LevelSelect.tscn"})
				var scene_path = "res://scenes/Emotion Matching/%s/%s" % [info["folder"], info["file"]]
				
				await tree.process_frame
				tree.change_scene_to_file(scene_path)
		)

func _on_character_selected(character: String):
	# This method is no longer used; logic moved to lambda
	pass
