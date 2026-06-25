extends RefCounted
class_name WordHintHelper

const HINT_SCENE_PATH: String = "res://scenes/HintScene.tscn"
const VOICE_OVER_MANAGER = preload("res://scripts/VoiceOverManager.gd")
const WORD_WRONG_CUES := {
	"joy": ["That word is not mine.", "I need a happy word.", "Try a word that feels bright."],
	"sadness": ["That word does not fit me.", "I need a sad word.", "Try a softer, blue feeling word."],
	"anger": ["That word is not for me.", "I need an angry word.", "Try a stronger, fiery word."],
	"disgust": ["Nope, that word is not mine.", "I need a disgust word.", "Try a word that sounds yucky."],
	"fear": ["That word is not mine.", "I need a fear word.", "Try a worried-sounding word."]
}
const WORD_CORRECT_CUES := {
	"joy": ["That's my word!", "That word fits me!", "Yes, that happy word is mine!"],
	"sadness": ["That's my word.", "That word fits my feeling.", "Yes, that sad word is mine."],
	"anger": ["That's my word!", "That word fits my mood.", "Yes, that angry word is mine!"],
	"disgust": ["That's my word.", "That word fits me.", "Yes, that yucky word is mine."],
	"fear": ["That's my word.", "That word fits my worried feeling.", "Yes, that fear word is mine."]
}

static func attach(controller: Node) -> void:
	if controller == null or not is_instance_valid(controller):
		return
	if controller.has_meta("_word_hint_helper_attached") and bool(controller.get_meta("_word_hint_helper_attached")):
		return
	controller.set_meta("_word_hint_helper_attached", true)
	watch_coin_counter(controller)
	_hide_visual_cue(controller)
	var hint_button: BaseButton = controller.get_node_or_null("UI/HintButton") as BaseButton
	if hint_button == null:
		return
	hint_button.pressed.connect(func(): _on_hint_pressed(controller))
	var drop_target: Node = controller.get("drop_target") as Node
	if drop_target != null and drop_target.has_signal("word_dropped"):
		drop_target.connect("word_dropped", func(is_correct: bool): _on_word_dropped(controller, is_correct))

static func watch_coin_counter(controller: Node) -> void:
	if controller == null or not is_instance_valid(controller):
		return
	_ensure_coin_hud(controller)
	_update_coin_counter(controller)
	if controller.has_meta("_word_coin_watch_connected") and bool(controller.get_meta("_word_coin_watch_connected")):
		return
	if GameState != null and GameState.has_signal("coins_changed"):
		var callable: Callable = Callable(WordHintHelper, "_on_game_state_coins_changed").bind(controller)
		if not GameState.coins_changed.is_connected(callable):
			GameState.coins_changed.connect(callable)
	controller.set_meta("_word_coin_watch_connected", true)

static func _on_hint_pressed(controller: Node) -> void:
	if controller == null or not is_instance_valid(controller):
		return
	if controller.has_meta("_word_hint_instance") and controller.get_meta("_word_hint_instance") != null:
		return
	var hint_resource: PackedScene = load(HINT_SCENE_PATH) as PackedScene
	if hint_resource == null:
		push_error("WordHintHelper: failed to load hint scene at %s" % HINT_SCENE_PATH)
		return
	var hint_instance: Node = hint_resource.instantiate()
	if hint_instance == null:
		return
	if hint_instance.has_method("set_word_entries"):
		hint_instance.call("set_word_entries", _build_word_entries(controller), _character_color())
	if hint_instance.has_method("set_background_texture"):
		hint_instance.call("set_background_texture", _get_background_texture(controller))
	if hint_instance.has_signal("close_requested"):
		hint_instance.close_requested.connect(func(): _on_hint_closed(controller))
	controller.set_meta("_word_hint_instance", hint_instance)
	var ui_layer: CanvasLayer = controller.get_node_or_null("UI") as CanvasLayer
	if ui_layer != null:
		ui_layer.add_child(hint_instance)
	else:
		controller.add_child(hint_instance)
	controller.get_tree().paused = true

static func _on_hint_closed(controller: Node) -> void:
	if controller == null or not is_instance_valid(controller):
		return
	var hint_instance: Variant = controller.get_meta("_word_hint_instance", null)
	if hint_instance is Node and is_instance_valid(hint_instance):
		(hint_instance as Node).queue_free()
	controller.set_meta("_word_hint_instance", null)
	controller.get_tree().paused = false

static func _build_word_entries(controller: Node) -> Array[String]:
	var entries: Array[String] = []
	if controller == null:
		return entries
	var draggable_labels: Variant = controller.get("draggable_labels")
	if draggable_labels is Array:
		for draggable in draggable_labels:
			if draggable != null and "word" in draggable:
				entries.append(String(draggable.word))
	return entries

static func _ensure_coin_hud(controller: Node) -> void:
	if controller == null:
		return
	if controller.get_node_or_null("UI/CoinsContainer/CoinCounter") != null:
		var existing_counter: Label = controller.get_node_or_null("UI/CoinsContainer/CoinCounter") as Label
		if existing_counter != null:
			existing_counter.text = str(GameState.coins)
		return
	var ui_layer: CanvasLayer = controller.get_node_or_null("UI") as CanvasLayer
	if ui_layer == null:
		return
	var coin_container := TextureRect.new()
	coin_container.name = "CoinsContainer"
	coin_container.offset_left = 245.0
	coin_container.offset_top = 19.0
	coin_container.offset_right = 338.0
	coin_container.offset_bottom = 70.0
	coin_container.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_container.texture = load("res://assets/UI/ButtonsText/ButtonText_Orange_OnOffBackground.png") as Texture2D
	var coin_icon := TextureRect.new()
	coin_icon.name = "Coin"
	coin_icon.offset_left = 12.0
	coin_icon.offset_top = 9.0
	coin_icon.offset_right = 45.0
	coin_icon.offset_bottom = 42.0
	coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_icon.texture = load("res://assets/UI/Icons/Icon_Small_Coin.png") as Texture2D
	coin_container.add_child(coin_icon)
	var coin_counter := Label.new()
	coin_counter.name = "CoinCounter"
	coin_counter.offset_left = 51.0
	coin_counter.offset_top = 4.0
	coin_counter.offset_right = 86.0
	coin_counter.offset_bottom = 40.0
	coin_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coin_counter.add_theme_constant_override("outline_size", 10)
	coin_counter.add_theme_font_override("font", load("res://assets/fonts/Fredoka/static/Fredoka_Condensed-Bold.ttf") as FontFile)
	coin_counter.add_theme_font_size_override("font_size", 30)
	coin_counter.text = str(GameState.coins)
	coin_container.add_child(coin_counter)
	ui_layer.add_child(coin_container)

static func _update_coin_counter(controller: Node) -> void:
	if controller == null:
		return
	var existing_counter: Label = controller.get_node_or_null("UI/CoinsContainer/CoinCounter") as Label
	if existing_counter != null:
		existing_counter.text = str(GameState.coins)

static func _on_game_state_coins_changed(new_amount: int, controller: Node) -> void:
	if controller == null or not is_instance_valid(controller):
		return
	var existing_counter: Label = controller.get_node_or_null("UI/CoinsContainer/CoinCounter") as Label
	if existing_counter != null:
		existing_counter.text = str(new_amount)

static func _hide_visual_cue(controller: Node) -> void:
	if controller == null:
		return
	var visual_cue: CanvasItem = controller.get_node_or_null("VisualCue") as CanvasItem
	if visual_cue != null:
		visual_cue.visible = false

static func _on_word_dropped(controller: Node, is_correct: bool) -> void:
	if controller == null or not is_instance_valid(controller):
		return
	var emotion: String = String(GameState.selected_character).to_lower()
	if emotion.is_empty():
		emotion = "joy"
	var lines: Array = WORD_CORRECT_CUES.get(emotion, WORD_CORRECT_CUES["joy"]) if is_correct else WORD_WRONG_CUES.get(emotion, WORD_WRONG_CUES["joy"])
	if lines.is_empty():
		return
	_show_visual_cue(controller, String(lines[randi() % lines.size()]))

static func _show_visual_cue(controller: Node, text: String) -> void:
	var visual_cue: CanvasItem = controller.get_node_or_null("VisualCue") as CanvasItem
	var cue_label: Label = controller.get_node_or_null("VisualCue/CueLabel") as Label
	if visual_cue == null or cue_label == null:
		return
	var next_token: int = int(controller.get_meta("_word_cue_token", 0)) + 1
	controller.set_meta("_word_cue_token", next_token)
	cue_label.text = text
	VOICE_OVER_MANAGER.play_matching_cue(String(GameState.selected_character), VOICE_OVER_MANAGER.MODE_WORD, text)
	visual_cue.visible = true
	await controller.get_tree().create_timer(4.0).timeout
	if int(controller.get_meta("_word_cue_token", 0)) == next_token and is_instance_valid(visual_cue):
		visual_cue.visible = false

static func _get_background_texture(controller: Node) -> Texture2D:
	if controller == null:
		return null
	var background: TextureRect = controller.get_node_or_null("Background") as TextureRect
	if background != null:
		return background.texture
	return null

static func _character_color() -> Color:
	if GameState == null:
		return Color(1, 1, 1, 1)
	match String(GameState.selected_character).to_lower():
		"joy":
			return Color(0.976, 0.89, 0.16, 1.0)
		"sadness":
			return Color(0.39, 0.66, 0.98, 1.0)
		"anger":
			return Color(0.97, 0.37, 0.32, 1.0)
		"disgust":
			return Color(0.33, 0.82, 0.45, 1.0)
		"fear":
			return Color(0.66, 0.42, 0.92, 1.0)
		_:
			return Color(1, 1, 1, 1)
