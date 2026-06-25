extends Label

@export var word: String = ""
var start_position := Vector2.ZERO
var start_scale := Vector2.ONE
var _is_locked: bool = false
var _float_tween: Tween = null

func _ready():
	start_position = position
	start_scale = scale
	mouse_filter = MOUSE_FILTER_STOP
	add_to_group("word_draggables")
	_create_float_animation()

func _create_float_animation():
	if _float_tween:
		_float_tween.kill()
	_float_tween = create_tween()
	_float_tween.set_loops()
	_float_tween.set_trans(Tween.TRANS_SINE)
	_float_tween.set_ease(Tween.EASE_IN_OUT)
	_float_tween.tween_property(self, "position:y", start_position.y - 15.0, 2.0)
	_float_tween.tween_property(self, "position:y", start_position.y, 2.0)

func _gui_input(event):
	if _is_locked:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_select_word()
	elif event is InputEventScreenTouch and event.pressed:
		_select_word()

func _select_word() -> void:
	_is_locked = true
	if _float_tween:
		_float_tween.kill()
	create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).tween_property(self, "scale", start_scale * 1.1, 0.08)
	for drop in get_tree().get_nodes_in_group("word_drop_targets"):
		if drop and drop.has_method("receive_drop"):
			drop.receive_drop(self)
			return
