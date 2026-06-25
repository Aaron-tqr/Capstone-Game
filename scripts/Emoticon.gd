extends TextureButton

const WRONG_ICON_TEXTURE: Texture2D = preload("res://assets/UI/Icons/Icon_Small_Blank_X.png")
const RIGHT_ICON_TEXTURE: Texture2D = preload("res://assets/UI/Icons/Icon_Small_Blank_Check.png")
const WRONG_FEEDBACK_DURATION: float = 0.45
const SITUATION_SCENE_PATH: String = "res://scenes/Situation Scene.tscn"

@export var emotion_name: String = ""
var start_position := Vector2.ZERO
var start_scale := Vector2.ONE
var float_tween: Tween = null
var _is_locked: bool = false
var _right_icon: CanvasItem = null
var _wrong_icon: CanvasItem = null

func _ready():
	add_to_group("emoticons")
	start_position = position
	start_scale = scale
	mouse_filter = MOUSE_FILTER_STOP
	_cache_feedback_icons()
	_hide_feedback_icons()
	
	# Start idle animation.
	_animate_emotion()

func _gui_input(event):
	if _is_locked or _is_round_input_locked():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_select_emoticon()
	elif event is InputEventScreenTouch and event.pressed:
		_select_emoticon()

func _select_emoticon() -> void:
	if _is_round_input_locked():
		return
	_is_locked = true
	if float_tween:
		float_tween.kill()
	create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).tween_property(self, "scale", start_scale * 1.1, 0.08)
	var drop_target: Node = _find_drop_target()
	if drop_target == null or not drop_target.has_method("receive_drop"):
		_is_locked = false
		_show_feedback(false)
		return
	if _should_use_situation_scene():
		var confirmed: bool = await _show_situation_confirmation()
		if not confirmed:
			_cancel_selection()
			return
	drop_target.receive_drop(self)
	var is_correct: bool = _is_correct_for_target(drop_target)
	_show_feedback(is_correct)
	if not is_correct:
		_queue_wrong_feedback_reset()
		return
	create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).tween_property(self, "scale", start_scale, 0.12)

func _animate_emotion():
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

func _find_drop_target() -> Node:
	for drop in get_tree().get_nodes_in_group("drop_targets"):
		if drop and drop.has_method("receive_drop"):
			return drop
	return null

func _is_round_input_locked() -> bool:
	return GameState != null and GameState.has_method("is_round_input_locked") and bool(GameState.call("is_round_input_locked"))

func _should_use_situation_scene() -> bool:
	if GameState == null:
		return false
	if String(GameState.current_mode).to_lower() != "emotion":
		return false
	if not ResourceLoader.exists(SITUATION_SCENE_PATH):
		return false
	var tree: SceneTree = get_tree()
	if tree == null or tree.current_scene == null:
		return false
	var scene_path: String = String(tree.current_scene.scene_file_path)
	return scene_path.begins_with("res://scenes/Emotion Matching/")

func _show_situation_confirmation() -> bool:
	var packed: PackedScene = load(SITUATION_SCENE_PATH) as PackedScene
	if packed == null:
		return true
	var popup: Node = packed.instantiate()
	if popup == null:
		return true
	# Determine occurrence index among matching emoticons that are correct for the current drop target
	var occurrence: int = -1
	var drop_target: Node = _find_drop_target()
	if drop_target != null:
		var same_emoticons := []
		var tree: SceneTree = get_tree()
		if tree != null and tree.current_scene != null:
			for node in tree.get_nodes_in_group("emoticons"):
				if node == null:
					continue
				if String(node.get("emotion_name")).strip_edges().to_lower() != _normalize_emotion_key(String(emotion_name)):
					continue
				# Ensure the emoticon is correct for the drop target (uses the same method on the Emoticon script)
				if node.has_method("_is_correct_for_target") and node.call("_is_correct_for_target", drop_target):
					same_emoticons.append(node)
		# Sort deterministically by name then position to ensure stable ordering
		same_emoticons.sort_custom(Callable(self, "_compare_emoticon_nodes"))
		# Find occurrence index (1-based)
		for i in range(same_emoticons.size()):
			if same_emoticons[i] == self:
				occurrence = i + 1
				break
	if popup.has_method("configure"):
		popup.call("configure", _normalize_emotion_key(String(emotion_name)), int(GameState.current_level), occurrence)
	var tree: SceneTree = get_tree()
	if tree != null and tree.current_scene != null:
		tree.current_scene.add_child(popup)
	else:
		add_child(popup)
	if popup.has_signal("decision_made"):
		var result: Variant = await popup.decision_made
		return bool(result)
	return true

func _cancel_selection() -> void:
	_hide_feedback_icons()
	_is_locked = false
	var tw: Tween = create_tween()
	tw.set_trans(Tween.TRANS_QUAD)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", start_scale, 0.12)
	_animate_emotion()

func _is_correct_for_target(drop_target: Node) -> bool:
	if drop_target == null:
		return false
	var accepted: String = ""
	if "accepts_emotion" in drop_target:
		accepted = String(drop_target.accepts_emotion)
	return _normalize_emotion_key(String(emotion_name)) == _normalize_emotion_key(accepted)

func _normalize_emotion_key(raw_key: String) -> String:
	var key: String = raw_key.strip_edges().to_lower()
	match key:
		"angry":
			return "anger"
		"scared", "fer":
			return "fear"
		"sad":
			return "sadness"
		_:
			return key

func _compare_emoticon_nodes(a, b) -> int:
	var na := String(a.name)
	var nb := String(b.name)
	if na != nb:
		return na.naturalnocasecmp_to(nb)
	var pa := Vector2(0, 0)
	var pb := Vector2(0, 0)
	# Prefer Node2D global_position when available
	if a is Node2D:
		pa = (a as Node2D).global_position
	elif a.has_method("get_global_position"):
		pa = a.call("get_global_position")
	if b is Node2D:
		pb = (b as Node2D).global_position
	elif b.has_method("get_global_position"):
		pb = b.call("get_global_position")
	if is_equal_approx(pa.x, pb.x):
		return int(pa.y - pb.y)
	return int(pa.x - pb.x)

func _cache_feedback_icons() -> void:
	for child in get_children():
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
	var icon_size: float = min(size.x, size.y) * 0.45
	if icon_size <= 0.0:
		icon_size = 96.0
	icon.position = Vector2((size.x - icon_size) * 0.5, (size.y - icon_size) * 0.5)
	icon.size = Vector2(icon_size, icon_size)
	add_child(icon)
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
	var tw: Tween = create_tween()
	tw.tween_interval(WRONG_FEEDBACK_DURATION)
	tw.finished.connect(_on_wrong_feedback_finished, CONNECT_ONE_SHOT)

func _on_wrong_feedback_finished() -> void:
	if not is_inside_tree():
		return
	_hide_feedback_icons()
	_is_locked = false
	var tw: Tween = create_tween()
	tw.set_trans(Tween.TRANS_QUAD)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", start_scale, 0.12)
	_animate_emotion()
