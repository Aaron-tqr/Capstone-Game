extends Control

signal confirmed
signal cancelled
signal decision_made(is_confirmed: bool)

@onready var background: TextureRect = get_node_or_null("Background") as TextureRect
@onready var message_label: Label = _resolve_message_label()
@onready var cost_label: Label = _resolve_cost_label()
@onready var cost_counter_label: Label = _resolve_cost_counter_label()
@onready var dim_overlay: ColorRect = _resolve_dim_overlay()
@onready var yes_button: BaseButton = get_node_or_null("YesBg/YesButton") as BaseButton
@onready var no_button: BaseButton = get_node_or_null("YesBg2/YesButton") as BaseButton

var _pending_message_text: String = ""
var _pending_cost: int = -1
var _pending_item_name: String = "coin"
var _decision_sent: bool = false

func _ready() -> void:
	_ensure_refs()
	if not _pending_message_text.is_empty() and message_label != null:
		message_label.text = _pending_message_text
	if _pending_cost >= 0:
		set_cost(_pending_cost, _pending_item_name)
	elif GameState != null and String(GameState.current_mode) == "emotion":
		set_cost(2, "coin")
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	if yes_button != null and not yes_button.pressed.is_connected(_on_yes_pressed):
		yes_button.pressed.connect(_on_yes_pressed)
	if no_button != null and not no_button.pressed.is_connected(_on_no_pressed):
		no_button.pressed.connect(_on_no_pressed)

func set_background_texture(tex: Texture2D) -> void:
	_ensure_refs()
	if background != null:
		background.visible = true
		background.texture = tex
	if dim_overlay != null:
		dim_overlay.visible = false

func use_live_scene_background(alpha: float = 0.55) -> void:
	_ensure_refs()
	if background != null:
		background.texture = null
		background.visible = false
	if dim_overlay != null:
		dim_overlay.visible = true
		dim_overlay.color = Color(0, 0, 0, clampf(alpha, 0.0, 1.0))

func set_message(text_value: String) -> void:
	_pending_message_text = text_value
	_ensure_refs()
	if message_label != null:
		message_label.text = text_value

func set_cost(cost: int, item_name: String = "coin") -> void:
	var effective_cost: int = cost
	if GameState != null and String(GameState.current_mode) == "emotion":
		effective_cost = 2
	_pending_cost = effective_cost
	_pending_item_name = item_name
	_ensure_refs()
	if cost_counter_label != null:
		cost_counter_label.text = str(effective_cost)
	if cost_label != null:
		if cost_counter_label != null:
			cost_label.text = "COST:"
			return
		var suffix: String = item_name
		if effective_cost != 1 and not suffix.ends_with("s"):
			suffix += "s"
		cost_label.text = "COST: %d %s" % [effective_cost, suffix.to_upper()]
		return
	if message_label != null:
		var fallback_suffix: String = item_name
		if effective_cost != 1 and not fallback_suffix.ends_with("s"):
			fallback_suffix += "s"
		if message_label.text.find("COST:") == -1:
			message_label.text = "%s\nCOST: %d %s" % [message_label.text, effective_cost, fallback_suffix.to_upper()]

func _ensure_refs() -> void:
	if background == null:
		background = get_node_or_null("Background") as TextureRect
	if message_label == null:
		message_label = _resolve_message_label()
	if cost_label == null:
		cost_label = _resolve_cost_label()
	if cost_counter_label == null:
		cost_counter_label = _resolve_cost_counter_label()
	if dim_overlay == null:
		dim_overlay = _resolve_dim_overlay()
	if yes_button == null:
		yes_button = get_node_or_null("YesBg/YesButton") as BaseButton
	if no_button == null:
		no_button = get_node_or_null("YesBg2/YesButton") as BaseButton

func _resolve_cost_label() -> Label:
	var candidate_paths: Array[String] = [
		"Cost",
		"CostLabel",
		"CoinCost",
		"CoinCostLabel",
		"Price",
		"PriceLabel",
		"TextureRect/Cost",
		"TextureRect/CostLabel",
		"TextureRect/CoinCost",
		"TextureRect/CoinCostLabel"
	]
	for node_path in candidate_paths:
		var node: Label = get_node_or_null(node_path) as Label
		if node != null:
			return node
	for child in get_children():
		if child is Label and String(child.name).to_lower().find("cost") != -1:
			return child as Label
	return null

func _resolve_message_label() -> Label:
	var candidate_paths: Array[String] = [
		"Question",
		"Definition",
		"Message",
		"MessageLabel",
		"TextureRect/Question",
		"TextureRect/Definition"
	]
	for node_path in candidate_paths:
		var node: Label = get_node_or_null(node_path) as Label
		if node != null:
			return node
	for child in get_children():
		if child is Label and String(child.name).to_lower().find("question") != -1:
			return child as Label
	return null

func _resolve_cost_counter_label() -> Label:
	var candidate_paths: Array[String] = [
		"Cost/CoinCounter",
		"CoinCounter",
		"TextureRect/Cost/CoinCounter",
		"TextureRect/CoinCounter"
	]
	for node_path in candidate_paths:
		var node: Label = get_node_or_null(node_path) as Label
		if node != null:
			return node
	if cost_label != null:
		for child in cost_label.get_children():
			if child is Label and String(child.name).to_lower().find("counter") != -1:
				return child as Label
	return null

func _resolve_dim_overlay() -> ColorRect:
	var existing: ColorRect = get_node_or_null("DimOverlay") as ColorRect
	if existing != null:
		return existing
	var overlay := ColorRect.new()
	overlay.name = "DimOverlay"
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.color = Color(0, 0, 0, 0.55)
	overlay.visible = false
	add_child(overlay)
	move_child(overlay, 0)
	return overlay

func _on_yes_pressed() -> void:
	if _decision_sent:
		return
	_decision_sent = true
	print("[UnlockConfirmation] YES pressed")
	confirmed.emit()
	decision_made.emit(true)
	queue_free()

func _on_no_pressed() -> void:
	if _decision_sent:
		return
	_decision_sent = true
	print("[UnlockConfirmation] NO pressed")
	cancelled.emit()
	decision_made.emit(false)
	queue_free()
