extends Control

const StyledPopup = preload("res://scripts/StyledPopup.gd")

const ACT_SCENES := {
	1: "res://scenes/Story/Act1LevelSelect.tscn",
	2: "res://scenes/Story/Act2LevelSelect.tscn",
	3: "res://scenes/Story/Act3LevelSelect.tscn",
}

@onready var button_act1: BaseButton = $ButtonLevel1
@onready var button_act2: BaseButton = $ButtonLevel2
@onready var button_act3: BaseButton = $ButtonLevel3
@onready var button_back: BaseButton = $Back

func _ready() -> void:
	_update_act_button(button_act1, 1)
	_update_act_button(button_act2, 2)
	_update_act_button(button_act3, 3)
	_connect_if_needed(button_act1, func(): _open_act(1))
	_connect_if_needed(button_act2, func(): _open_act(2))
	_connect_if_needed(button_act3, func(): _open_act(3))
	_connect_if_needed(button_back, _on_back_pressed)

func _open_act(act_number: int) -> void:
	if not GameState.is_story_act_unlocked(act_number):
		_show_locked_warning("Finish the previous act to unlock this act.")
		return
	GameState.current_story_act = act_number
	var scene_path: String = String(ACT_SCENES.get(act_number, ""))
	if scene_path.is_empty():
		push_warning("Missing Story scene mapping for act: %d" % act_number)
		return
	_change_scene_to_file(scene_path)

func _update_act_button(button: BaseButton, act_number: int) -> void:
	if button == null:
		return
	var unlocked: bool = GameState.is_story_act_unlocked(act_number)
	button.disabled = false
	button.modulate = Color(1, 1, 1, 1) if unlocked else Color(0.42, 0.42, 0.42, 0.82)
	button.tooltip_text = "Act %d" % act_number if unlocked else "Clear the previous act to unlock this one"
	_set_lock_icon_visible(button, not unlocked)

func _on_back_pressed() -> void:
	_change_scene_to_file("res://scenes/ModeSelect.tscn")

func _connect_if_needed(button: BaseButton, callback: Callable) -> void:
	if button and not button.pressed.is_connected(callback):
		button.pressed.connect(callback)

func _change_scene_to_file(scene_path: String) -> void:
	var transition_node: Node = get_node_or_null("/root/SceneTransition")
	if transition_node and transition_node.has_method("change_scene_to_file"):
		transition_node.call("change_scene_to_file", scene_path)
		return
	get_tree().change_scene_to_file(scene_path)

func _show_locked_warning(message: String) -> void:
	StyledPopup.open_popup(self, "ACT LOCKED", message, "OK", Color(1.0, 0.5, 0.28, 1.0))

func _set_lock_icon_visible(container: Node, locked: bool) -> void:
	if container == null:
		return
	var lock_icon: CanvasItem = container.get_node_or_null("Lock Icon") as CanvasItem
	if lock_icon != null:
		lock_icon.visible = locked
