extends Control

const CONTINUATION_SCENE: String = "res://scenes/continuation.tscn"
const STORY_ENDING_SCENE: String = "res://scenes/Story/StoryEndingMobile.tscn"
const StyledPopup = preload("res://scripts/StyledPopup.gd")

@onready var button_level1: BaseButton = _resolve_button(["ButtonLevel1", "StartBg"])
@onready var button_level2: BaseButton = _resolve_button(["ButtonLevel2"])
@onready var button_level3: BaseButton = _resolve_button(["ButtonLevel3"])
@onready var button_level4: BaseButton = _resolve_button(["ButtonLevel4"])
@onready var button_level5: BaseButton = _resolve_button(["ButtonLevel5"])
@onready var button_back: BaseButton = _resolve_button(["Back"])
@onready var finish_status_label: Label = _resolve_finish_status_label()

func _ready() -> void:
	_update_finish_status_label()
	_connect_if_needed(button_level1, func(): _on_level_pressed(1))
	_connect_if_needed(button_level2, func(): _on_level_pressed(2))
	_connect_if_needed(button_level3, func(): _on_level_pressed(3))
	_connect_if_needed(button_level4, func(): _on_level_pressed(4))
	_connect_if_needed(button_level5, func(): _on_level_pressed(5))
	_connect_if_needed(button_back, _on_back_pressed)

func _update_finish_status_label() -> void:
	if finish_status_label == null:
		return
	var act_number: int = GameState.current_story_act if GameState.current_story_act > 0 else _detect_act_number()
	var finished: bool = GameState.is_story_act_completed(act_number)
	finish_status_label.text = "Finished" if finished else "unfinished"
	if finished:
		finish_status_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	else:
		finish_status_label.add_theme_color_override("font_color", Color(0.61, 0.61, 0.61, 1))

func _on_level_pressed(level_number: int) -> void:
	var act_number: int = GameState.current_story_act if GameState.current_story_act > 0 else _detect_act_number()
	var scene_path: String = "res://scenes/Story/Act%dLevel%dStoryMobile.tscn" % [act_number, level_number]
	if ResourceLoader.exists(scene_path):
		_open_story_scene(scene_path)
		return
	if act_number == 1 and level_number == 1:
		_open_story_scene("res://scenes/Story/Act1Level1StoryMobile.tscn")
		return
	_show_coming_soon_dialog(act_number, level_number)

func _open_story_scene(scene_path: String) -> void:
	if _should_offer_story_continue(scene_path):
		return
	if _should_offer_story_ending_continue(scene_path):
		return
	_change_scene_to_file(scene_path)

func _should_offer_story_continue(scene_path: String) -> bool:
	if GameState.has_story_continue_progress(scene_path):
		GameState.set_pending_story_continue_scene(scene_path)
		_change_scene_to_file(CONTINUATION_SCENE)
		return true
	return false

func _should_offer_story_ending_continue(scene_path: String) -> bool:
	if not scene_path.contains("Act3Level1StoryMobile"):
		return false
	if not GameState.has_story_continue_progress(STORY_ENDING_SCENE):
		return false
	GameState.set_pending_story_continue_scene(STORY_ENDING_SCENE)
	_change_scene_to_file(CONTINUATION_SCENE)
	return true

func _on_back_pressed() -> void:
	_change_scene_to_file("res://scenes/Story/StoryActSelect.tscn")

func _detect_act_number() -> int:
	var scene_path: String = String(get_tree().current_scene.scene_file_path)
	if scene_path.contains("Act1"):
		return 1
	if scene_path.contains("Act2"):
		return 2
	if scene_path.contains("Act3"):
		return 3
	return 0

func _show_coming_soon_dialog(act_number: int, level_number: int) -> void:
	var message: String = ""
	if act_number > 0:
		message = "Act %d - Level %d is not added yet.\nStory content coming soon." % [act_number, level_number]
	else:
		message = "Level %d is not added yet.\nStory content coming soon." % level_number
	StyledPopup.open_popup(self, "STORY MODE", message, "OK", Color(1.0, 0.74, 0.36, 1.0))

func _connect_if_needed(button: BaseButton, callback: Callable) -> void:
	if button and not button.pressed.is_connected(callback):
		button.pressed.connect(callback)

func _resolve_button(candidates: Array[String]) -> BaseButton:
	for node_path in candidates:
		var node: Node = get_node_or_null(node_path)
		if node is BaseButton:
			return node as BaseButton
	return null

func _resolve_finish_status_label() -> Label:
	var candidates: Array[String] = [
		"ButtonLevel1/FinishorUnfinish",
		"StartBg/FinishorUnfinish",
		"StartBg/FinishOrUnfinish",
		"FinishorUnfinish",
		"FinishOrUnfinish"
	]
	for node_path in candidates:
		var label: Label = get_node_or_null(node_path) as Label
		if label != null:
			return label
	return null

func _change_scene_to_file(scene_path: String) -> void:
	var transition_node: Node = get_node_or_null("/root/SceneTransition")
	if transition_node and transition_node.has_method("change_scene_to_file"):
		transition_node.call("change_scene_to_file", scene_path)
		return
	get_tree().change_scene_to_file(scene_path)
