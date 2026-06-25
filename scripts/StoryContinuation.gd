extends Control

const FALLBACK_ACT1_SCENE: String = "res://scenes/Story/Act1Level1StoryMobile.tscn"

@onready var background: TextureRect = get_node_or_null("Background") as TextureRect
@onready var question_label: Label = get_node_or_null("Question") as Label
@onready var yes_button: BaseButton = get_node_or_null("YesBg/YesButton") as BaseButton
@onready var no_button: BaseButton = get_node_or_null("YesBg2/YesButton") as BaseButton

var _target_scene_path: String = ""
var _saved_beat_index: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP

	_target_scene_path = GameState.consume_pending_story_continue_scene().strip_edges()
	if _target_scene_path.is_empty():
		_target_scene_path = _resolve_scene_from_current_act()

	var saved: Dictionary = GameState.get_story_continue_progress(_target_scene_path)
	_saved_beat_index = int(saved.get("beat_index", -1))
	var frame_path: String = String(saved.get("frame_path", "")).strip_edges()

	if question_label != null:
		question_label.text = "Continue from where you left off?"

	_apply_background_texture(frame_path)

	if yes_button != null and not yes_button.pressed.is_connected(_on_yes_pressed):
		yes_button.pressed.connect(_on_yes_pressed)
	if no_button != null and not no_button.pressed.is_connected(_on_no_pressed):
		no_button.pressed.connect(_on_no_pressed)

func _resolve_scene_from_current_act() -> String:
	var act_number: int = maxi(1, int(GameState.current_story_act))
	var path: String = "res://scenes/Story/Act%dLevel1StoryMobile.tscn" % act_number
	if ResourceLoader.exists(path):
		return path
	return FALLBACK_ACT1_SCENE

func _apply_background_texture(frame_path: String) -> void:
	if background == null:
		return
	if frame_path.is_empty() or not ResourceLoader.exists(frame_path):
		return
	var tex: Texture2D = load(frame_path) as Texture2D
	if tex == null:
		return
	background.texture = tex
	background.visible = true

func _on_yes_pressed() -> void:
	if _saved_beat_index >= 0:
		GameState.set_story_retry_context(_target_scene_path, _saved_beat_index)
		GameState.set_story_skip_intro_once(_target_scene_path)
	_change_scene_to_file(_target_scene_path)

func _on_no_pressed() -> void:
	GameState.clear_story_retry_context(_target_scene_path)
	GameState.clear_story_continue_progress(_target_scene_path)
	_change_scene_to_file(_target_scene_path)

func _change_scene_to_file(scene_path: String) -> void:
	var transition_node: Node = get_node_or_null("/root/SceneTransition")
	if transition_node and transition_node.has_method("change_scene_to_file"):
		transition_node.call("change_scene_to_file", scene_path)
		return
	get_tree().change_scene_to_file(scene_path)
