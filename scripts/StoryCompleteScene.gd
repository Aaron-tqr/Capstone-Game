extends Control

const ACT_SELECT_SCENE: String = "res://scenes/Story/StoryActSelect.tscn"
const COMPLETE_BACKGROUND: String = "res://assets/story/act3/ending end blur.png"

@onready var background: TextureRect = $Background
@onready var banner: TextureRect = $PartyPopperR2
@onready var success_label: Label = $Label
@onready var act_label: Label = $Label2
@onready var subtitle_label: Label = $IntroSubtitle
@onready var left_popper: TextureRect = $PartyPopperL
@onready var right_popper: TextureRect = $PartyPopperR

var _celebrating: bool = false
var _accept_input: bool = false
var _confetti_layer: Control = null

func _ready() -> void:
	if AudioManager != null:
		AudioManager.play_sfx("level_clear")
	mouse_filter = Control.MOUSE_FILTER_STOP
	if background != null:
		background.texture = load(COMPLETE_BACKGROUND) as Texture2D

	if success_label != null:
		success_label.text = "SUCCESS!"

	if act_label != null:
		act_label.text = "STORY COMPLETE"
		act_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	if subtitle_label != null:
		subtitle_label.text = "TAP THE SCREEN TO CONTINUE"
	if success_label != null:
		success_label.visible = true
	if act_label != null:
		act_label.visible = true
	if subtitle_label != null:
		subtitle_label.visible = true

	_celebrating = true
	_prepare_layers()
	_prepare_banner_state()
	_play_banner_intro()
	_start_confetti_rain()
	_start_popper_stream(left_popper, true)
	_start_popper_stream(right_popper, false)

	await get_tree().create_timer(0.28).timeout
	_accept_input = true

func _prepare_layers() -> void:
	_confetti_layer = Control.new()
	_confetti_layer.name = "ConfettiLayer"
	_confetti_layer.anchor_right = 1.0
	_confetti_layer.anchor_bottom = 1.0
	_confetti_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_confetti_layer.z_index = 20
	add_child(_confetti_layer)

	if background != null:
		background.z_index = -20
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if banner != null:
		banner.z_index = 1
	if success_label != null:
		success_label.z_index = 3
	if act_label != null:
		act_label.z_index = 3
	if subtitle_label != null:
		subtitle_label.z_index = 3
	if left_popper != null:
		left_popper.z_index = 2
	if right_popper != null:
		right_popper.z_index = 2

func _prepare_banner_state() -> void:
	var nodes: Array[CanvasItem] = [banner, success_label, act_label, subtitle_label]
	for node in nodes:
		if node == null:
			continue
		node.modulate.a = 0.0
		node.scale = Vector2(0.3, 0.3)
	if banner != null:
		banner.position += Vector2(0.0, 24.0)
	if success_label != null:
		success_label.position += Vector2(0.0, 18.0)
	if act_label != null:
		act_label.position += Vector2(0.0, 16.0)
	if subtitle_label != null:
		subtitle_label.position += Vector2(0.0, 8.0)

func _play_banner_intro() -> void:
	var intro_tween: Tween = create_tween()
	intro_tween.set_trans(Tween.TRANS_BACK)
	intro_tween.set_ease(Tween.EASE_OUT)

	if banner != null:
		intro_tween.tween_property(banner, "position:y", banner.position.y - 24.0, 0.45)
		intro_tween.parallel().tween_property(banner, "scale", Vector2.ONE, 0.45)
		intro_tween.parallel().tween_property(banner, "modulate:a", 1.0, 0.25)

	intro_tween.tween_interval(0.06)

	if success_label != null:
		intro_tween.tween_property(success_label, "position:y", success_label.position.y - 18.0, 0.22)
		intro_tween.parallel().tween_property(success_label, "scale", Vector2.ONE, 0.22)
		intro_tween.parallel().tween_property(success_label, "modulate:a", 1.0, 0.18)

	intro_tween.tween_interval(0.03)

	if act_label != null:
		intro_tween.tween_property(act_label, "position:y", act_label.position.y - 16.0, 0.2)
		intro_tween.parallel().tween_property(act_label, "scale", Vector2.ONE, 0.2)
		intro_tween.parallel().tween_property(act_label, "modulate:a", 1.0, 0.16)

	intro_tween.tween_interval(0.04)

	if subtitle_label != null:
		intro_tween.tween_property(subtitle_label, "position:y", subtitle_label.position.y - 8.0, 0.2)
		intro_tween.parallel().tween_property(subtitle_label, "scale", Vector2.ONE, 0.2)
		intro_tween.parallel().tween_property(subtitle_label, "modulate:a", 1.0, 0.16)

func _start_confetti_rain() -> void:
	if _confetti_layer == null:
		return
	for i in range(28):
		var confetti: ColorRect = _create_confetti_piece()
		_confetti_layer.add_child(confetti)
		_run_confetti_piece(confetti, float(i) * 0.08)

func _create_confetti_piece() -> ColorRect:
	var confetti := ColorRect.new()
	confetti.mouse_filter = Control.MOUSE_FILTER_IGNORE
	confetti.custom_minimum_size = Vector2(randf_range(6.0, 11.0), randf_range(12.0, 20.0))
	confetti.size = confetti.custom_minimum_size
	return confetti

func _run_confetti_piece(confetti: ColorRect, initial_delay: float) -> void:
	if confetti == null:
		return
	if initial_delay > 0.0:
		await get_tree().create_timer(initial_delay).timeout
	while is_inside_tree() and _celebrating:
		var viewport_size: Vector2 = get_viewport_rect().size
		var start_x: float = randf_range(0.0, viewport_size.x)
		var start_y: float = randf_range(-180.0, -20.0)
		var fall_distance: float = randf_range(viewport_size.y + 90.0, viewport_size.y + 220.0)
		confetti.position = Vector2(start_x, start_y)
		confetti.rotation = randf_range(0.0, TAU)
		confetti.scale = Vector2(randf_range(0.45, 0.75), randf_range(0.45, 0.75))
		confetti.color = Color.from_hsv(randf(), 0.9, 1.0, 1.0)
		confetti.modulate.a = 1.0

		var drift_x: float = randf_range(-70.0, 70.0)
		var duration: float = randf_range(2.4, 4.0)
		var tween: Tween = create_tween()
		tween.set_trans(Tween.TRANS_LINEAR)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.parallel().tween_property(confetti, "position:x", start_x + drift_x, duration)
		tween.parallel().tween_property(confetti, "position:y", start_y + fall_distance, duration)
		tween.parallel().tween_property(confetti, "rotation", confetti.rotation + randf_range(-3.0, 3.0), duration)
		await tween.finished

func _start_popper_stream(popper: TextureRect, from_left: bool) -> void:
	if popper == null:
		return
	_run_popper_stream(popper, from_left)

func _run_popper_stream(popper: TextureRect, from_left: bool) -> void:
	while is_inside_tree() and _celebrating:
		for i in range(3):
			_spawn_popper_particle(popper, from_left)
		await get_tree().create_timer(0.09).timeout

func _spawn_popper_particle(popper: TextureRect, from_left: bool) -> void:
	if _confetti_layer == null or popper == null:
		return
	var popper_rect: Rect2 = popper.get_global_rect()
	var spawn_x: float = popper_rect.position.x + popper_rect.size.x * (0.72 if from_left else 0.28)
	var spawn_y: float = popper_rect.position.y + popper_rect.size.y * 0.18
	var piece := ColorRect.new()
	piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
	piece.custom_minimum_size = Vector2(randf_range(5.0, 9.0), randf_range(12.0, 18.0))
	piece.size = piece.custom_minimum_size
	piece.position = Vector2(spawn_x, spawn_y)
	piece.rotation = randf_range(-0.5, 0.5)
	piece.scale = Vector2(0.35, 0.35)
	piece.color = Color.from_hsv(randf(), 0.85, 1.0, 1.0)
	_confetti_layer.add_child(piece)

	var outward_x: float = randf_range(90.0, 220.0)
	if from_left:
		outward_x = randf_range(120.0, 260.0)
	var target: Vector2 = Vector2(spawn_x + (outward_x if from_left else -outward_x), spawn_y - randf_range(40.0, 110.0))
	var burst: Tween = create_tween()
	burst.set_parallel(true)
	burst.set_trans(Tween.TRANS_BACK)
	burst.set_ease(Tween.EASE_OUT)
	burst.tween_property(piece, "position", target, 0.7)
	burst.tween_property(piece, "scale", Vector2.ONE, 0.7)
	burst.tween_property(piece, "rotation", piece.rotation + randf_range(-1.6, 1.6), 0.7)
	burst.finished.connect(func() -> void:
		if is_instance_valid(piece):
			piece.queue_free()
	)

func _gui_input(event: InputEvent) -> void:
	if not _accept_input:
		return
	if _is_tap(event):
		_accept_input = false
		_celebrating = false
		_change_scene_to_file(ACT_SELECT_SCENE)
		accept_event()

func _unhandled_input(event: InputEvent) -> void:
	if not _accept_input:
		return
	if _is_tap(event):
		_accept_input = false
		_celebrating = false
		_change_scene_to_file(ACT_SELECT_SCENE)

func _is_tap(event: InputEvent) -> bool:
	return (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventScreenTouch and event.pressed)

func _change_scene_to_file(scene_path: String) -> void:
	var transition_node: Node = get_node_or_null("/root/SceneTransition")
	if transition_node and transition_node.has_method("change_scene_to_file"):
		transition_node.call("change_scene_to_file", scene_path)
		return
	get_tree().change_scene_to_file(scene_path)