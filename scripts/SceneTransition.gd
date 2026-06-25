extends CanvasLayer

var _overlay_root: Control
var _left_panel: ColorRect
var _right_panel: ColorRect
var _center_line: ColorRect
var _sweep_panel: ColorRect
var _zoom_panel: ColorRect
var _is_transitioning: bool = false

const CLOSE_DURATION: float = 0.26
const OPEN_DURATION: float = 0.24
const HOLD_DURATION: float = 0.05
const TRANSITION_COLOR: Color = Color(0, 0, 0, 1)
const CENTER_LINE_COLOR: Color = Color(1.0, 0.76, 0.35, 0.9)

const STYLE_SHUTTER: int = 0
const STYLE_SWEEP: int = 1
const STYLE_ZOOM: int = 2

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_overlay_if_needed()
	_set_shutter_state(false)

func change_scene_to_file(scene_path: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_create_overlay_if_needed()
	var style: int = _pick_style(scene_path)
	_overlay_root.mouse_filter = Control.MOUSE_FILTER_STOP
	await _animate_transition(style, true)
	await get_tree().create_timer(HOLD_DURATION).timeout
	var tree: SceneTree = get_tree()
	tree.paused = false
	var result: int = tree.change_scene_to_file(scene_path)
	if result != OK:
		push_error("SceneTransition failed loading: %s (error %d)" % [scene_path, result])
	await tree.process_frame
	await _animate_transition(style, false)
	_overlay_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_is_transitioning = false

func change_scene_to_packed(scene: PackedScene) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_create_overlay_if_needed()
	var style: int = STYLE_SWEEP
	_overlay_root.mouse_filter = Control.MOUSE_FILTER_STOP
	await _animate_transition(style, true)
	await get_tree().create_timer(HOLD_DURATION).timeout
	var tree: SceneTree = get_tree()
	tree.paused = false
	var result: int = tree.change_scene_to_packed(scene)
	if result != OK:
		push_error("SceneTransition failed loading packed scene (error %d)" % result)
	await tree.process_frame
	await _animate_transition(style, false)
	_overlay_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_is_transitioning = false

func _pick_style(target_scene_path: String) -> int:
	var normalized: String = target_scene_path.replace("\\", "/")
	# Keep current shutter transition for starting story levels.
	if normalized.find("/scenes/Story/Act") != -1 and normalized.find("StoryMobile.tscn") != -1:
		return STYLE_SHUTTER
	# Unique sweep from menu flows and story act select.
	if normalized.find("CharacterSelect.tscn") != -1 or normalized.find("/scenes/Story/StoryActSelect.tscn") != -1:
		return STYLE_SWEEP
	# Distinct zoom transition for emotion/word level select scenes.
	if normalized.find("LevelSelect.tscn") != -1 and (normalized.find("/scenes/Emotion Matching/") != -1 or normalized.find("/scenes/Word Matching/") != -1):
		return STYLE_ZOOM
	return STYLE_SWEEP

func _animate_transition(style: int, closing: bool) -> void:
	match style:
		STYLE_SHUTTER:
			_set_all_panels_visible()
			_layout_shutter()
			await _animate_shutter(closing, CLOSE_DURATION if closing else OPEN_DURATION)
		STYLE_ZOOM:
			_layout_zoom_panel()
			await _animate_zoom(closing, CLOSE_DURATION if closing else OPEN_DURATION)
		_:
			_layout_sweep_panel()
			await _animate_sweep(closing, CLOSE_DURATION if closing else OPEN_DURATION)

func _animate_shutter(close_shutter: bool, duration: float) -> void:
	if _overlay_root == null or _left_panel == null or _right_panel == null or _center_line == null:
		return
	var size: Vector2 = get_viewport().get_visible_rect().size
	var half_width: float = size.x * 0.5
	var left_closed_x: float = 0.0
	var right_closed_x: float = half_width
	var left_open_x: float = -half_width - 4.0
	var right_open_x: float = size.x + 4.0
	var target_left_x: float = left_closed_x if close_shutter else left_open_x
	var target_right_x: float = right_closed_x if close_shutter else right_open_x
	var target_line_alpha: float = 1.0 if close_shutter else 0.0

	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_parallel(true)
	tween.tween_property(_left_panel, "position:x", target_left_x, duration)
	tween.tween_property(_right_panel, "position:x", target_right_x, duration)
	tween.tween_property(_center_line, "modulate:a", target_line_alpha, duration * 0.8)
	await tween.finished

func _create_overlay_if_needed() -> void:
	if is_instance_valid(_overlay_root):
		return
	_overlay_root = Control.new()
	_overlay_root.name = "TransitionOverlay"
	_overlay_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_root.anchor_right = 1.0
	_overlay_root.anchor_bottom = 1.0
	add_child(_overlay_root)

	_left_panel = ColorRect.new()
	_left_panel.name = "LeftCurtain"
	_left_panel.color = TRANSITION_COLOR
	_left_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_root.add_child(_left_panel)

	_right_panel = ColorRect.new()
	_right_panel.name = "RightCurtain"
	_right_panel.color = TRANSITION_COLOR
	_right_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_root.add_child(_right_panel)

	_center_line = ColorRect.new()
	_center_line.name = "CenterLine"
	_center_line.color = CENTER_LINE_COLOR
	_center_line.modulate.a = 0.0
	_center_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_root.add_child(_center_line)

	_sweep_panel = ColorRect.new()
	_sweep_panel.name = "SweepPanel"
	_sweep_panel.color = TRANSITION_COLOR
	_sweep_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sweep_panel.visible = false
	_overlay_root.add_child(_sweep_panel)

	_zoom_panel = ColorRect.new()
	_zoom_panel.name = "ZoomPanel"
	_zoom_panel.color = TRANSITION_COLOR
	_zoom_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_zoom_panel.visible = false
	_overlay_root.add_child(_zoom_panel)

	_layout_shutter()

func _layout_shutter() -> void:
	if _overlay_root == null or _left_panel == null or _right_panel == null or _center_line == null:
		return
	var size: Vector2 = get_viewport().get_visible_rect().size
	var half_width: float = size.x * 0.5 + 4.0
	if _sweep_panel != null:
		_sweep_panel.size = size
	if _zoom_panel != null:
		_zoom_panel.size = size
	_left_panel.position = Vector2(_left_panel.position.x, 0.0)
	_left_panel.size = Vector2(half_width, size.y)
	_right_panel.position = Vector2(_right_panel.position.x, 0.0)
	_right_panel.size = Vector2(half_width, size.y)
	_center_line.position = Vector2(size.x * 0.5 - 2.0, 0.0)
	_center_line.size = Vector2(4.0, size.y)

func _set_shutter_state(closed: bool) -> void:
	if _overlay_root == null or _left_panel == null or _right_panel == null:
		return
	_layout_shutter()
	var size: Vector2 = get_viewport().get_visible_rect().size
	var half_width: float = size.x * 0.5
	if closed:
		_left_panel.position.x = 0.0
		_right_panel.position.x = half_width
		if _center_line != null:
			_center_line.modulate.a = 1.0
	else:
		_left_panel.position.x = -half_width - 4.0
		_right_panel.position.x = size.x + 4.0
		if _center_line != null:
			_center_line.modulate.a = 0.0

func _layout_sweep_panel() -> void:
	if _sweep_panel == null:
		return
	_layout_shutter()
	_sweep_panel.visible = true
	_sweep_panel.position = Vector2(-_sweep_panel.size.x - 4.0, 0.0)
	_left_panel.visible = false
	_right_panel.visible = false
	_center_line.visible = false
	if _zoom_panel != null:
		_zoom_panel.visible = false

func _animate_sweep(closing: bool, duration: float) -> void:
	if _sweep_panel == null:
		return
	if closing:
		_sweep_panel.position.x = -_sweep_panel.size.x - 4.0
	else:
		_sweep_panel.position.x = 0.0
	var target_x: float = 0.0 if closing else (_sweep_panel.size.x + 4.0)
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_sweep_panel, "position:x", target_x, duration)
	await tween.finished
	if not closing:
		_sweep_panel.visible = false

func _layout_zoom_panel() -> void:
	if _zoom_panel == null:
		return
	_layout_shutter()
	_zoom_panel.visible = true
	_zoom_panel.pivot_offset = _zoom_panel.size * 0.5
	_zoom_panel.position = Vector2.ZERO
	_zoom_panel.scale = Vector2(0.01, 0.01)
	_zoom_panel.modulate.a = 0.0
	_left_panel.visible = false
	_right_panel.visible = false
	_center_line.visible = false
	if _sweep_panel != null:
		_sweep_panel.visible = false

func _animate_zoom(closing: bool, duration: float) -> void:
	if _zoom_panel == null:
		return
	if closing:
		_zoom_panel.scale = Vector2(0.01, 0.01)
		_zoom_panel.modulate.a = 0.0
	else:
		_zoom_panel.scale = Vector2.ONE
		_zoom_panel.modulate.a = 1.0
	var target_scale: Vector2 = Vector2.ONE if closing else Vector2(2.3, 2.3)
	var target_alpha: float = 1.0 if closing else 0.0
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(_zoom_panel, "scale", target_scale, duration)
	tween.tween_property(_zoom_panel, "modulate:a", target_alpha, duration)
	await tween.finished
	if not closing:
		_zoom_panel.visible = false

func _set_all_panels_visible() -> void:
	if _left_panel != null:
		_left_panel.visible = true
	if _right_panel != null:
		_right_panel.visible = true
	if _center_line != null:
		_center_line.visible = true
