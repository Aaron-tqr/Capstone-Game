extends Node

# Draggable label component - handles dragging and dropping
class_name DraggableLabel
const DEBUG_LOGS: bool = false
const WRONG_ICON_TEXTURE: Texture2D = preload("res://assets/UI/Icons/Icon_Small_Blank_X.png")
const RIGHT_ICON_TEXTURE: Texture2D = preload("res://assets/UI/Icons/Icon_Small_Blank_Check.png")
const WRONG_FEEDBACK_DURATION: float = 0.45

var label: Label
var word: String = ""
var start_position := Vector2.ZERO
var start_scale := Vector2.ONE
var float_tween: Tween = null
var _is_locked: bool = false
var _right_icon: CanvasItem = null
var _wrong_icon: CanvasItem = null

func _init(p_label: Label, p_word: String):
	label = p_label
	word = p_word
	start_position = label.position
	start_scale = label.scale
	label.mouse_filter = Control.MOUSE_FILTER_STOP
	label.add_to_group("word_draggables")
	_cache_feedback_icons()
	_hide_feedback_icons()
	_setup_input()
	_create_float_animation()

func _setup_input():
	label.gui_input.connect(_on_gui_input)

func _on_gui_input(event):
	if _is_locked or _is_round_input_locked():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_select_word()
	elif event is InputEventScreenTouch and event.pressed:
		_select_word()

func _create_float_animation():
	if float_tween:
		float_tween.kill()
	float_tween = label.create_tween()
	float_tween.set_loops()
	float_tween.set_trans(Tween.TRANS_SINE)
	float_tween.set_ease(Tween.EASE_IN_OUT)
	float_tween.tween_property(label, "position:y", start_position.y - 15.0, 2.0)
	float_tween.tween_property(label, "position:y", start_position.y, 2.0)

func _select_word() -> void:
	if _is_round_input_locked():
		return
	_is_locked = true
	if float_tween:
		float_tween.kill()
	var tween = label.create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", start_scale * 1.1, 0.08)

	var drop_target: Node = _find_drop_target()
	if drop_target == null or not drop_target.has_method("receive_drop"):
		_is_locked = false
		_show_feedback(false)
		return

	if DEBUG_LOGS:
		print("Selecting word:", word, "target=", drop_target.name)
	drop_target.receive_drop(self)
	var is_correct: bool = _is_correct_for_target(drop_target)
	_show_feedback(is_correct)
	if not is_correct:
		_queue_wrong_feedback_reset()
		return
	var reset_tween := label.create_tween()
	reset_tween.set_trans(Tween.TRANS_QUAD)
	reset_tween.set_ease(Tween.EASE_OUT)
	reset_tween.tween_property(label, "scale", start_scale, 0.12)

func _find_drop_target() -> Node:
	for drop in label.get_tree().get_nodes_in_group("word_drop_targets"):
		if drop and drop.has_method("receive_drop"):
			return drop
	return null

func _is_round_input_locked() -> bool:
	return GameState != null and GameState.has_method("is_round_input_locked") and bool(GameState.call("is_round_input_locked"))

func _is_correct_for_target(drop_target: Node) -> bool:
	if drop_target == null:
		return false
	if "correct_words" in drop_target:
		return word in drop_target.correct_words
	return false

func _cache_feedback_icons() -> void:
	for child in label.get_children():
		if child is CanvasItem:
			var icon_type: String = _classify_icon(child)
			if icon_type == "right" and _right_icon == null:
				_right_icon = child as CanvasItem
			elif icon_type == "wrong" and _wrong_icon == null:
				_wrong_icon = child as CanvasItem
	if _right_icon == null:
		_right_icon = _create_icon_node("Right Icon Auto", RIGHT_ICON_TEXTURE)
	if _wrong_icon == null:
		_wrong_icon = _create_icon_node("Wrong Icon Auto", WRONG_ICON_TEXTURE)

func _create_icon_node(node_name: String, texture: Texture2D) -> CanvasItem:
	if texture == null:
		return null
	var icon := TextureRect.new()
	icon.name = node_name
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon_size: float = min(label.size.x, label.size.y) * 0.9
	if icon_size <= 0.0:
		icon_size = 84.0
	icon.position = Vector2((label.size.x - icon_size) * 0.5, (label.size.y - icon_size) * 0.5)
	icon.size = Vector2(icon_size, icon_size)
	label.add_child(icon)
	return icon

func _classify_icon(node: CanvasItem) -> String:
	var name_key := String(node.name).to_lower()
	var texture_key := _node_texture_path(node).to_lower()
	var key := name_key + " " + texture_key
	if key.find("check") != -1 or key.find("right") != -1:
		return "right"
	if key.find("wrong") != -1 or key.find("_x") != -1 or key.find("blank_x") != -1:
		return "wrong"
	return ""

func _node_texture_path(node: CanvasItem) -> String:
	if node is TextureRect and (node as TextureRect).texture != null:
		return String((node as TextureRect).texture.resource_path)
	if node is TextureButton and (node as TextureButton).texture_normal != null:
		return String((node as TextureButton).texture_normal.resource_path)
	if node is Sprite2D and (node as Sprite2D).texture != null:
		return String((node as Sprite2D).texture.resource_path)
	return ""

func _hide_feedback_icons() -> void:
	if _right_icon != null:
		_right_icon.visible = false
	if _wrong_icon != null:
		_wrong_icon.visible = false

func _show_feedback(is_correct: bool) -> void:
	_hide_feedback_icons()
	if is_correct and _right_icon != null:
		_right_icon.visible = true
	elif not is_correct and _wrong_icon != null:
		_wrong_icon.visible = true

func _queue_wrong_feedback_reset() -> void:
	var tw: Tween = label.create_tween()
	tw.tween_interval(WRONG_FEEDBACK_DURATION)
	tw.finished.connect(_on_wrong_feedback_finished, CONNECT_ONE_SHOT)

func _on_wrong_feedback_finished() -> void:
	if label == null or not is_instance_valid(label):
		return
	_hide_feedback_icons()
	_is_locked = false
	var reset_tween := label.create_tween()
	reset_tween.set_trans(Tween.TRANS_QUAD)
	reset_tween.set_ease(Tween.EASE_OUT)
	reset_tween.tween_property(label, "scale", start_scale, 0.12)
	_create_float_animation()


func process():
	pass
