extends Control

const StyledPopup = preload("res://scripts/StyledPopup.gd")

@onready var joy_char = $JoyCharacter
@onready var sadness_char = $SadCharacter
@onready var anger_char = $AngerCharacter
@onready var disgust_char = $DisgustCharacter
@onready var fear_char = $FearCharacter
@onready var back_button = get_node_or_null("BackBg/Back")

var _character_nodes := {}

func _ready():
	# Animate in characters
	var characters = [joy_char, sadness_char, anger_char, disgust_char, fear_char]
	
	for character in characters:
		if character:
			character.scale = Vector2(0.8, 0.8)
			character.modulate.a = 0
			
			var tween = create_tween().bind_node(character)
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
	_character_nodes = {
		"joy": joy_char,
		"sadness": sadness_char,
		"anger": anger_char,
		"disgust": disgust_char,
		"fear": fear_char,
	}
	_apply_lock_visuals()
	await get_tree().process_frame
	_show_pending_character_unlocks()
	
	if back_button:
		back_button.mouse_filter = Control.MOUSE_FILTER_STOP
		back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	_change_scene_to_file("res://scenes/ModeSelect.tscn")

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

func _connect_click(node: Control, character: String):
	if node:
		node.mouse_filter = Control.MOUSE_FILTER_STOP
		node.gui_input.connect(func(event):
			if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or \
			   (event is InputEventScreenTouch and event.pressed):
				if not GameState.is_emotion_character_unlocked(character, "emotion"):
					_show_locked_warning("Finish Level 3 of the previous emotion to unlock this character.")
					return
				# Play click animation
				var tween = create_tween().bind_node(node)
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
				
				_change_scene_to_file(scene_path)
		)

func _on_character_selected(character: String):
	# This method is no longer used; logic moved to lambda
	pass

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
		var unlocked: bool = GameState.is_emotion_character_unlocked(String(key), "emotion")
		node.modulate = Color(1, 1, 1, 1) if unlocked else Color(0.45, 0.45, 0.45, 0.95)
		_set_lock_icon_visible(node, not unlocked)

func _set_lock_icon_visible(container: Node, locked: bool) -> void:
	if container == null:
		return
	var lock_icon: CanvasItem = container.get_node_or_null("Lock Icon") as CanvasItem
	if lock_icon != null:
		lock_icon.visible = locked

func _show_locked_warning(message: String) -> void:
	StyledPopup.open_popup(self, "CHARACTER LOCKED", message, "OK", Color(1.0, 0.46, 0.33, 1.0))

func _show_pending_character_unlocks() -> void:
	var all_events: Array[Dictionary] = GameState.consume_pending_unlock_events()
	var keep_events: Array[Dictionary] = []
	for event in all_events:
		var kind: String = String(event.get("kind", "")).to_lower()
		if kind != "character":
			keep_events.append(event)
			continue
		await _show_character_unlock_popup(event)
	for remaining in keep_events:
		GameState.pending_unlock_events.append(remaining)
	_apply_lock_visuals()

func _show_character_unlock_popup(event: Dictionary) -> void:
	var title: String = String(event.get("title", "Character Unlocked!"))
	var message: String = String(event.get("message", "New character unlocked."))
	var target_name: String = title.replace(" Unlocked!", "").to_lower()
	if _character_nodes.has(target_name):
		var node: Control = _character_nodes[target_name] as Control
		if node != null:
			var tw: Tween = create_tween()
			tw.set_parallel(true)
			tw.set_trans(Tween.TRANS_BACK)
			tw.set_ease(Tween.EASE_OUT)
			tw.tween_property(node, "scale", Vector2(1.18, 1.18), 0.22)
			tw.tween_property(node, "modulate", Color(1, 1, 1, 1), 0.2)
			tw.tween_property(node, "scale", Vector2.ONE, 0.2)
	var popup: StyledPopup = StyledPopup.open_popup(self, title.to_upper(), message, "NICE", Color(0.55, 0.92, 1.0, 1.0))
	await popup.confirmed
