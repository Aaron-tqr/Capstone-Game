extends Control

signal decision_made(is_yes: bool)

const SCENARIOS_BASE_PATH: String = "res://assets/Revised Assets/Scenarios"
const EMOTION_FOLDER_MAP := {
	"joy": {"folder": "Joy", "prefix": "Joy"},
	"sadness": {"folder": "Sad", "prefix": "Sad"},
	"anger": {"folder": "Angry", "prefix": "Angry"},
	"disgust": {"folder": "Disgust", "prefix": "Disgust"},
	"fear": {"folder": "Fear", "prefix": "Fear"},
}

@onready var situation_image: TextureRect = get_node_or_null("Situation Image") as TextureRect
@onready var yes_button: BaseButton = get_node_or_null("YesButton") as BaseButton
@onready var no_button: BaseButton = get_node_or_null("NoButton") as BaseButton

var _emotion_key: String = "joy"
var _level: int = 1
var _level_label_ref: Node = null
var _occurrence: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if yes_button != null and not yes_button.pressed.is_connected(_on_yes_pressed):
		yes_button.pressed.connect(_on_yes_pressed)
	if no_button != null and not no_button.pressed.is_connected(_on_no_pressed):
		no_button.pressed.connect(_on_no_pressed)
	_hide_game_level_label()
	_apply_situation_texture()

func configure(emotion_name: String, level: int, occurrence: int = -1) -> void:
	_emotion_key = _normalize_emotion_key(emotion_name)
	_level = maxi(1, level)
	_occurrence = int(occurrence)
	if is_inside_tree():
		_apply_situation_texture()

func _on_yes_pressed() -> void:
	_restore_game_level_label()
	emit_signal("decision_made", true)
	queue_free()

func _on_no_pressed() -> void:
	_restore_game_level_label()
	emit_signal("decision_made", false)
	queue_free()

func _hide_game_level_label() -> void:
	var tree: SceneTree = get_tree()
	if tree == null or tree.current_scene == null:
		return
	var level_label: Node = tree.current_scene.get_node_or_null("UI/LevelLabel")
	if level_label != null:
		_level_label_ref = level_label
		if level_label is CanvasItem:
			(level_label as CanvasItem).visible = false

func _restore_game_level_label() -> void:
	if _level_label_ref != null and is_instance_valid(_level_label_ref):
		if _level_label_ref is CanvasItem:
			(_level_label_ref as CanvasItem).visible = true
	_level_label_ref = null

func _apply_situation_texture() -> void:
	if situation_image == null:
		return
	var scenario_path: String = _get_scenario_path(_emotion_key, _level, _occurrence)
	if scenario_path.is_empty() or not ResourceLoader.exists(scenario_path):
		print("⚠️ SituationScene: Scenario not found for emotion='%s' level=%d occurrence=%d, path='%s'" % [_emotion_key, _level, _occurrence, scenario_path])
		return
	var tex: Texture2D = load(scenario_path) as Texture2D
	if tex != null:
		print("✅ SituationScene: Loaded scenario for emotion='%s' level=%d occurrence=%d: %s" % [_emotion_key, _level, _occurrence, scenario_path])
		situation_image.texture = tex
	else:
		print("⚠️ SituationScene: Failed to load texture from path: %s" % scenario_path)

func _get_scenario_path(emotion_key: String, level: int, occurrence: int = -1) -> String:
	var info: Dictionary = EMOTION_FOLDER_MAP.get(emotion_key, {})
	if info.is_empty():
		return ""
	var folder_path: String = "%s/%s" % [SCENARIOS_BASE_PATH, String(info.get("folder", ""))]
	var prefix: String = String(info.get("prefix", ""))
	var files: Array[String] = _collect_scenario_files(folder_path, prefix)
	if files.is_empty():
		return ""
	var index: int = 0
	if GameState != null and GameState.has_method("get_next_situation_scenario_index"):
		index = int(GameState.call("get_next_situation_scenario_index", emotion_key, files.size()))
	else:
		if occurrence != null and int(occurrence) > 0:
			# Use occurrence (1-based) to pick distinct scenario among same-emotion emoticons
			index = posmod(int(occurrence) - 1, files.size())
		else:
			index = posmod(level - 1, files.size())
	return "%s/%s" % [folder_path, files[index]]

func _collect_scenario_files(folder_path: String, prefix: String) -> Array[String]:
	var output: Array[String] = []
	var dir: DirAccess = DirAccess.open(folder_path)
	if dir == null:
		return output
	for file_name in dir.get_files():
		if file_name.get_extension().to_lower() != "png":
			continue
		var base_name: String = file_name.get_basename()
		if not base_name.to_lower().begins_with(prefix.to_lower() + " "):
			continue
		output.append(file_name)
	output.sort_custom(_compare_scenario_files)
	return output

func _compare_scenario_files(a: String, b: String) -> bool:
	var num_a: int = _extract_trailing_number(a)
	var num_b: int = _extract_trailing_number(b)
	if num_a == num_b:
		return a.naturalnocasecmp_to(b) < 0
	return num_a < num_b

func _extract_trailing_number(file_name: String) -> int:
	var base_name: String = file_name.get_basename()
	var parts: PackedStringArray = base_name.split(" ", false)
	if parts.is_empty():
		return 0
	var tail: String = parts[parts.size() - 1]
	if tail.is_valid_int():
		return int(tail)
	return 0

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
