extends Control

func _ready():
	var bg4 = get_node_or_null("bg4")
	if bg4:
		_create_heartbeat_loop(bg4)

	# Animate character entries
	var fear = get_node_or_null("Fear")
	var disgust = get_node_or_null("Disgust")
	var sadness = get_node_or_null("Sadness")
	var joy = get_node_or_null("Joy")
	var anger = get_node_or_null("Anger")
	
	# Bounce in animation for each character with delay
	if fear:
		await get_tree().create_timer(0.1).timeout
		create_tween().bind_node(fear).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT).tween_property(fear, "scale", Vector2(1, 1), 0.6)
	
	if disgust:
		await get_tree().create_timer(0.2).timeout
		create_tween().bind_node(disgust).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT).tween_property(disgust, "scale", Vector2(1, 1), 0.6)
	
	if sadness:
		await get_tree().create_timer(0.3).timeout
		create_tween().bind_node(sadness).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT).tween_property(sadness, "scale", Vector2(1, 1), 0.6)
	
	if joy:
		await get_tree().create_timer(0.4).timeout
		create_tween().bind_node(joy).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT).tween_property(joy, "scale", Vector2(1, 1), 0.6)
	
	if anger:
		await get_tree().create_timer(0.5).timeout
		create_tween().bind_node(anger).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT).tween_property(anger, "scale", Vector2(1, 1), 0.6)
	
	# Start float bob animation for characters
	if fear:
		_create_float_bob(fear, 2.0, 15.0)
	if disgust:
		_create_float_bob(disgust, 2.2, 15.0)
	if sadness:
		_create_float_bob(sadness, 2.4, 15.0)
	if joy:
		_create_float_bob(joy, 2.6, 15.0)
	if anger:
		_create_float_bob(anger, 2.8, 15.0)
	
	var start_button = get_node_or_null("StartButton")
	if start_button == null:
		start_button = get_node_or_null("VBoxContainer/StartButton")
	if start_button == null:
		start_button = get_node_or_null("bg2/StartButton")
	if start_button == null:
		print("ERROR: Start button not found.")
		return
	start_button.pressed.connect(_on_start_pressed)
	
	var exit_button = get_node_or_null("ExitButton")
	if exit_button == null:
		exit_button = get_node_or_null("bg3/ExitButton")
	if exit_button:
		exit_button.pressed.connect(_on_exit_pressed)

	var settings_button = get_node_or_null("bg5/StartButton")
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)

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

func _create_heartbeat_loop(node: Control) -> void:
	if not is_instance_valid(node):
		return
	node.pivot_offset = node.size * 0.5
	node.scale = Vector2.ONE
	var beat_tween = create_tween().bind_node(node)
	beat_tween.set_loops()
	beat_tween.set_trans(Tween.TRANS_SINE)
	beat_tween.set_ease(Tween.EASE_OUT)
	# Double pulse, then short rest.
	beat_tween.tween_property(node, "scale", Vector2(1.06, 1.06), 0.22)
	beat_tween.tween_property(node, "scale", Vector2.ONE, 0.22)
	beat_tween.tween_property(node, "scale", Vector2(1.11, 1.11), 0.26)
	beat_tween.tween_property(node, "scale", Vector2.ONE, 0.34)
	beat_tween.tween_interval(0.9)

func _on_start_pressed():
	print("🚀 Start Game → ModeSelect!")
	_change_scene_to_file("res://scenes/ModeSelect.tscn")

func _on_exit_pressed():
	get_tree().quit()

func _on_settings_pressed():
	if AudioManager != null:
		AudioManager.duck_music_temporarily()
	if "settings_return_scene" in GameState:
		GameState.settings_return_scene = "res://scenes/MainMenu.tscn"
	_change_scene_to_file("res://scenes/Settings.tscn")

func _change_scene_to_file(scene_path: String) -> void:
	var transition_node: Node = get_node_or_null("/root/SceneTransition")
	if transition_node and transition_node.has_method("change_scene_to_file"):
		transition_node.call("change_scene_to_file", scene_path)
		return
	get_tree().change_scene_to_file(scene_path)
