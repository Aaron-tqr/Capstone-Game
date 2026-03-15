extends Label

@export var word: String = ""
var dragging := false
var drag_offset := Vector2.ZERO
var start_position := Vector2.ZERO
var start_scale := Vector2.ONE

func _ready():
	start_position = position
	start_scale = scale
	mouse_filter = MOUSE_FILTER_STOP
	add_to_group("word_draggables")
	_create_float_animation()

func _create_float_animation():
	var tween = create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position:y", start_position.y - 15.0, 2.0)
	tween.tween_property(self, "position:y", start_position.y, 2.0)

func _gui_input(event):
	if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
		dragging = true
		drag_offset = get_global_mouse_position() - global_position
		create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).tween_property(self, "scale", start_scale * 1.3, 0.1)
	elif (event is InputEventScreenTouch or event is InputEventMouseButton) and not event.pressed:
		_end_drag()

func _process(_delta):
	if dragging:
		global_position = get_global_mouse_position() - drag_offset

func _end_drag():
	if dragging:
		dragging = false
		_try_drop()
		var tween = create_tween()
		tween.set_parallel(true)
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "position", start_position, 0.3)
		tween.tween_property(self, "scale", start_scale, 0.3)
		_create_float_animation()

func _try_drop():
	for drop in get_tree().get_nodes_in_group("word_drop_targets"):
		if drop.is_inside_drop_area(global_position):
			drop.receive_drop(self)
			return
