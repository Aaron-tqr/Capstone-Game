extends Control

@onready var resume_button: Button = $PausePanel/VBoxContainer/ResumeButton
@onready var restart_button: Button = $PausePanel/VBoxContainer/RestartButton
@onready var settings_button: Button = $PausePanel/VBoxContainer/SettingsButton
@onready var exit_button: Button = $PausePanel/VBoxContainer/ExitButton

const SETTINGS_SCENE: String = "res://scenes/Settings.tscn"
const ACT_SELECT_SCENE: String = "res://scenes/Story/StoryActSelect.tscn"

var _current_story_scene: String = ""
var _settings_overlay: Control = null

func _ready() -> void:
	# Store the current story scene path so we can restart it
	_current_story_scene = get_tree().current_scene.scene_file_path
	
	# Hide the previous button and finish button from the story scene
	var story_scene = get_tree().current_scene
	if story_scene.has_node("UI/PreviousBg"):
		story_scene.get_node("UI/PreviousBg").visible = false
	if story_scene.has_node("UI/PreviousBg/PreviousButton"):
		story_scene.get_node("UI/PreviousBg/PreviousButton").visible = false
	if story_scene.has_node("UI/FinishButton"):
		story_scene.get_node("UI/FinishButton").visible = false
	
	# Connect button signals
	if resume_button != null:
		resume_button.pressed.connect(_on_resume_pressed)
	if restart_button != null:
		restart_button.pressed.connect(_on_restart_pressed)
	if settings_button != null:
		settings_button.pressed.connect(_on_settings_pressed)
	if exit_button != null:
		exit_button.pressed.connect(_on_exit_pressed)
	
	# Handle escape key to resume
	if get_tree() != null:
		get_tree().paused = true
	if AudioManager != null:
		AudioManager.stop_voice()

func _input(event: InputEvent) -> void:
	if is_instance_valid(_settings_overlay):
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_on_resume_pressed()
			get_tree().root.set_input_as_handled()

func _on_resume_pressed() -> void:
	if is_instance_valid(_settings_overlay):
		_settings_overlay.queue_free()
		_settings_overlay = null
		if "settings_return_scene" in GameState:
			GameState.settings_return_scene = ""
		return
	var story_scene: Node = get_parent()
	if story_scene != null and story_scene.has_method("_on_story_pause_resumed"):
		story_scene.call("_on_story_pause_resumed")
	if get_tree() != null:
		get_tree().paused = false
	queue_free()

func _on_restart_pressed() -> void:
	if AudioManager != null:
		AudioManager.stop_voice()
	if get_tree() != null:
		get_tree().paused = false
		get_tree().reload_current_scene()

func _on_settings_pressed() -> void:
	if is_instance_valid(_settings_overlay):
		return
	var scene: PackedScene = load(SETTINGS_SCENE) as PackedScene
	if scene == null:
		return
	_settings_overlay = scene.instantiate() as Control
	if _settings_overlay == null:
		return
	_settings_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	_settings_overlay.z_index = 100
	if "settings_return_scene" in GameState:
		GameState.settings_return_scene = "__OVERLAY_STORY_PAUSE__"
	add_child(_settings_overlay)

func _on_exit_pressed() -> void:
	if AudioManager != null:
		AudioManager.stop_voice()
	if get_tree() != null:
		get_tree().paused = false
		get_tree().change_scene_to_file(ACT_SELECT_SCENE)
