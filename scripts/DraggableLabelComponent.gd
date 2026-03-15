extends Node

# Draggable label component - handles dragging and dropping
class_name DraggableLabel

var label: Label
var word: String = ""
var dragging := false
var drag_offset := Vector2.ZERO
var start_position := Vector2.ZERO
var start_scale := Vector2.ONE
var float_tween: Tween = null

func _init(p_label: Label, p_word: String):
	label = p_label
	word = p_word
	start_position = label.position
	start_scale = label.scale
	label.mouse_filter = Control.MOUSE_FILTER_STOP
	label.add_to_group("word_draggables")
	_setup_input()
	_create_float_animation()

func _setup_input():
	label.gui_input.connect(_on_gui_input)

func _on_gui_input(event):
	if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
		dragging = true
		# Cancel floating animation
		if float_tween:
			float_tween.kill()
		drag_offset = label.get_global_mouse_position() - label.global_position
		var tween = label.create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(label, "scale", start_scale * 1.3, 0.1)
	elif (event is InputEventScreenTouch or event is InputEventMouseButton) and not event.pressed:
		_end_drag()

func _create_float_animation():
	float_tween = label.create_tween()
	float_tween.set_loops()
	float_tween.set_trans(Tween.TRANS_SINE)
	float_tween.set_ease(Tween.EASE_IN_OUT)
	float_tween.tween_property(label, "position:y", start_position.y - 15.0, 2.0)
	float_tween.tween_property(label, "position:y", start_position.y, 2.0)

func _end_drag():
	if dragging:
		dragging = false
		_try_drop()
		var tween = label.create_tween()
		tween.set_parallel(true)
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(label, "position", start_position, 0.3)
		tween.tween_property(label, "scale", start_scale, 0.3)
		await tween.finished
		_create_float_animation()

func _try_drop():
	var dropped = false
	var label_rect = label.get_global_rect()
	var drop_point = label_rect.position + label_rect.size * 0.5
	for drop in label.get_tree().get_nodes_in_group("word_drop_targets"):
		var inside = drop.is_inside_drop_area(drop_point)
		print("Try drop on", drop.name, "target_global", drop.global_position, "target_size", drop.size, "drop_point", drop_point, "inside", inside)
		if inside:
			print("Dropping word: ", word, " on drop target", drop.name)
			drop.receive_drop(self)
			dropped = true
			break
	if not dropped:
		print("Drop failed for word:", word, "drop_point", drop_point)


func process():
	if dragging:
		label.global_position = label.get_global_mouse_position() - drag_offset
