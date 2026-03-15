extends TextureButton

@export var emotion_name: String = ""
var dragging := false
var drag_offset := Vector2.ZERO
var start_position := Vector2.ZERO
var start_scale := Vector2.ONE
var float_tween: Tween = null

func _ready():
	add_to_group("emoticons")
	start_position = position
	start_scale = scale
	mouse_filter = MOUSE_FILTER_PASS  # Allow input
	
	# Start emotion animation (gentle rotation + scale pulse)
	_animate_emotion()

func _gui_input(event):
	# Start drag (TOUCH/MOUSE - PERFECT OFFSET)
	if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
		dragging = true
		drag_offset = get_global_mouse_position() - global_position
		# Kill any ongoing animation
		if float_tween:
			float_tween.kill()
		# Add scale animation on drag start
		create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).tween_property(self, "scale", start_scale * 1.3, 0.1)
	
	# End drag (TOUCH/MOUSE)
	elif (event is InputEventScreenTouch or event is InputEventMouseButton) and not event.pressed:
		_end_drag()

func _process(_delta):
	if dragging:
		# Follow cursor/finger PERFECTLY
		global_position = get_global_mouse_position() - drag_offset

func _end_drag():
	if dragging:
		dragging = false
		_try_drop()
		# Animate back to start position
		var tween = create_tween()
		tween.set_parallel(true)
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "position", start_position, 0.3)
		tween.tween_property(self, "scale", start_scale, 0.3)
		# Resume emotion animation after drag
		await get_tree().create_timer(0.3).timeout
		_animate_emotion()

func _try_drop():
	for drop in get_tree().get_nodes_in_group("drop_targets"):
		if drop.is_inside_drop_area(global_position):
			drop.receive_drop(self)  # Pass the emoticon object itself, not just the name
			return

func _animate_emotion():
	"""Gentle rotation and scale pulse animation for emotions"""
	# Kill previous tween if exists
	if float_tween:
		float_tween.kill()
	
	float_tween = create_tween()
	float_tween.set_loops()
	float_tween.set_trans(Tween.TRANS_SINE)
	float_tween.set_ease(Tween.EASE_IN_OUT)
	
	# Gentle float bob animation (similar to character)
	# move up then back to start position repeatedly
	float_tween.tween_property(self, "position:y", start_position.y - 10.0, 1.5)
	float_tween.tween_property(self, "position:y", start_position.y, 1.5)
