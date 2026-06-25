extends Control

const ACT_SELECT_SCENE: String = "res://scenes/Story/StoryActSelect.tscn"

@onready var retry_button: Button = $RetryBg/RetryButton
@onready var quit_button: Button = $QuitBg/QuitButton

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if retry_button != null and not retry_button.pressed.is_connected(_on_retry_pressed):
		retry_button.pressed.connect(_on_retry_pressed)
	if quit_button != null and not quit_button.pressed.is_connected(_on_quit_pressed):
		quit_button.pressed.connect(_on_quit_pressed)

func _on_retry_pressed() -> void:
	var retry_scene: String = GameState.story_retry_scene_path
	if retry_scene.is_empty() or not ResourceLoader.exists(retry_scene):
		retry_scene = ACT_SELECT_SCENE
	_change_scene_to_file(retry_scene)

func _on_quit_pressed() -> void:
	_change_scene_to_file(ACT_SELECT_SCENE)

func _change_scene_to_file(scene_path: String) -> void:
	var transition_node: Node = get_node_or_null("/root/SceneTransition")
	if transition_node and transition_node.has_method("change_scene_to_file"):
		transition_node.call("change_scene_to_file", scene_path)
		return
	get_tree().change_scene_to_file(scene_path)
