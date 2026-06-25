extends Control

const FRAME_FOLDER: String = "res://assets/story/act2"
const ACT_SELECT_SCENE: String = "res://scenes/Story/StoryActSelect.tscn"
const STORY_END_SCENE: String = "res://scenes/Story/StoryEndScene.tscn"
const STORY_FAIL_SCENE: String = "res://scenes/Story/StoryFailScene.tscn"
const STORY_VOICE_MANAGER = preload("res://scripts/StoryVoiceOverManager.gd")
const INTRO_MAIN_TITLE: String = "Jimm and the 5 Emotions"
const INTRO_ACT2_TITLE: String = "ACT 2: THE LOST TOY"
const INTRO_START_BLUR: String = "act2 start blur.png"

const EMOTION_TEXTURES: Dictionary = {
	"Joy": "res://assets/characters/Joy1.png",
	"Anger": "res://assets/characters/Anger1.png",
	"Fear": "res://assets/characters/Fear1.png",
	"Sadness": "res://assets/characters/Sadness1.png",
	"Disgust": "res://assets/characters/Disgust1.png",
}

const SPEAKER_PORTRAITS: Dictionary = {
	"Jimm": "res://assets/story/act1/CharacterFace/jimm.png",
	"Mom": "res://assets/story/act1/CharacterFace/mom.png",
	"Friend": "res://assets/story/act2/CharacterFace/Friend.png",
	"Cousin": "res://assets/story/act1/CharacterFace/cousin.png",
}

const JIMM_FACE_BY_EMOTION: Dictionary = {
	"Sadness": "res://assets/story/act2/JimmFace/JimmFace1.png",
	"Disgust": "res://assets/story/act2/JimmFace/JimmFace2.png",
	"Joy": "res://assets/story/act2/JimmFace/JimmFace3.png",
	"Anger": "res://assets/story/act2/JimmFace/JimmFace3.png",
}

var _beats: Array[Dictionary] = [
	{
		"frame": 1,
		"speaker": "",
		"text": "The next morning was beautiful. Jimm went to the park to see if his toy boat could sail.",
		"plain_story": true,
	},
	{
		"frame": 1,
		"speaker": "Jimm",
		"text": "The water looks so blue today! Are you ready to sail, little boat?",
		"plain_story": false,
	},
	{
		"frame": 2,
		"speaker": "",
		"text": "He found a perfect spot and carefully leaned down toward the moving water.",
		"plain_story": true,
	},
	{
		"frame": 2,
		"speaker": "Jimm",
		"text": "Stay close to the edge so I can reach you!",
		"plain_story": false,
	},
	{
		"frame": 3,
		"speaker": "",
		"text": "With a gentle tap, the boat touched the stream. It was finally sailing!",
		"plain_story": true,
	},
	{
		"frame": 3,
		"speaker": "Jimm",
		"text": "Look at you go! You're a real explorer now!",
		"plain_story": false,
	},
	{
		"frame": 4,
		"speaker": "",
		"text": "But the stream was moving faster than Jimm expected. The boat began to drift away.",
		"plain_story": true,
	},
	{
		"frame": 4,
		"speaker": "Jimm",
		"text": "Wait! Come back! You're going too far!",
		"plain_story": false,
	},
	{
		"frame": 5,
		"speaker": "",
		"text": "Jimm reached out as far as he could, but the water was too quick.",
		"plain_story": true,
	},
	{
		"frame": 5,
		"speaker": "Jimm",
		"text": "Oh no! I can't reach it anymore! Stop, little boat!",
		"plain_story": false,
	},
	{
		"frame": 6,
		"is_question": true,
		"correct_emotion": "Sadness",
		"question": "Jimm lost his favorite toy. What is he feeling?",
		"feedback": {
			"Sadness": "That's right. Jimm feels Sadness because he lost his favorite boat.",
			"Joy": "Not this time. Jimm is not smiling; he is hurt and disappointed.",
			"Anger": "He is upset, but this moment shows more sadness than anger.",
			"Disgust": "There is nothing yucky here yet. Jimm is sad about losing his toy.",
			"Fear": "He is worried, but the strongest feeling here is sadness."
		},
		"dim": 0.34,
	},
	{
		"frame": 7,
		"speaker": "",
		"text": "Jimm didn't want to give up. He ran along the bank, trying to keep up with the red boat.",
		"plain_story": true,
	},
	{
		"frame": 7,
		"speaker": "Jimm",
		"text": "I have to catch it! Maybe there's a spot where it will stop!",
		"plain_story": false,
	},
	{
		"frame": 8,
		"speaker": "",
		"text": "Jimm was looking at the water so closely that he didn't see what was right in front of him.",
		"plain_story": true,
	},
	{
		"frame": 8,
		"speaker": "Jimm",
		"text": "Just a little bit faster and... whoa!",
		"plain_story": false,
	},
	{
		"frame": 9,
		"speaker": "Jimm",
		"text": "Ew! This mud is green and it smells like old socks! It's so slimy!",
		"plain_story": false,
	},
	{
		"frame": 9,
		"is_question": true,
		"correct_emotion": "Disgust",
		"question": "Jimm thinks the mud is icky. Which feeling is this?",
		"feedback": {
			"Disgust": "Correct! Jimm feels Disgust because the mud looks and smells gross.",
			"Joy": "Nope, this moment is not happy. Jimm is saying 'ew'.",
			"Sadness": "He is not crying here. He is reacting to something gross.",
			"Anger": "He is frustrated, but the clear feeling is disgust.",
			"Fear": "He is not scared of danger. He is grossed out by the mud."
		},
		"dim": 0.34,
	},
	{
		"frame": 10,
		"speaker": "",
		"text": "Just then, Jimm's friend Carl walked by. He saw that Jimm was having a very messy day.",
		"plain_story": true,
	},
	{
		"frame": 10,
		"speaker": "Friend",
		"text": "Hi Jimm! I saw your boat float away. I'm sorry you're having a bad time.",
		"plain_story": false,
	},
	{
		"frame": 11,
		"speaker": "Friend",
		"text": "I have an extra balloon from the party. Do you want to hold it?",
		"plain_story": false,
	},
	{
		"frame": 11,
		"speaker": "Jimm",
		"text": "A balloon? For me? It's the same color as my boat!",
		"plain_story": false,
	},
	{
		"frame": 12,
		"speaker": "",
		"text": "Holding the bright balloon made the muddy shoe and the lost boat feel far away.",
		"plain_story": true,
	},
	{
		"frame": 12,
		"is_question": true,
		"correct_emotion": "Joy",
		"question": "Jimm feels better now. What emotion is he showing?",
		"feedback": {
			"Joy": "Exactly! Jimm is smiling again and feeling Joy.",
			"Sadness": "Not anymore. The balloon and Carl's kindness helped him feel better.",
			"Anger": "He is calm and cheerful now, not angry.",
			"Disgust": "The gross mud is no longer his focus. He feels happy.",
			"Fear": "He is not afraid now. He looks relieved and joyful."
		},
		"dim": 0.34,
	},
	{
		"frame": 13,
		"speaker": "",
		"text": "Jimm learned that even when we lose things we love, a good friend can help us feel better. A lost toy can be replaced, but a good friend is a treasure!",
		"plain_story": true,
	},
	{
		"frame": 13,
		"speaker": "Jimm",
		"text": "Thanks for the balloon, Carl! Let's go home and play with my robot!",
		"plain_story": false,
	},
	{
		"frame_path": "act2 end blur.png",
		"speaker": "",
		"text": "Even after a hard day, Jimm found hope, friendship, and Joy again.",
		"plain_story": true,
	},
]

var _beat_index: int = -1
var _question_active: bool = false
var _question_pending: bool = false
var _intro_done: bool = false
var _waiting_intro_tap: bool = false
var _active_frame: int = -1
var _emotions_revealed: bool = false
var _emotion_idle_tweens: Array[Tween] = []
var _choice_float_tweens: Array[Tween] = []
var _choice_button_base_positions: Dictionary = {}
var _emotion_show_idle_float: bool = true
var _intro_glitter_triggered: bool = false

var _active_question_correct: String = ""
var _active_question_feedback: Dictionary = {}
var _question_index: int = 0

@onready var background_fallback: ColorRect = $BackgroundFallback
@onready var background_texture: TextureRect = $BackgroundTexture
@onready var story_dim_overlay: ColorRect = $StoryDimOverlay
@onready var top_title: Label = $TopTitle
@onready var tap_hint: Label = $TapHint
@onready var emotion_showcase: Control = get_node_or_null("EmotionShowcase") as Control
@onready var jimm_face: TextureRect = $UI/JimmFace
@onready var intro_layer: CanvasLayer = $IntroLayer
@onready var intro_root: Control = $IntroLayer/IntroRoot
@onready var intro_blur: ColorRect = $IntroLayer/IntroRoot/IntroBlur
@onready var intro_title: Label = $IntroLayer/IntroRoot/IntroTitle
@onready var intro_subtitle: Label = $IntroLayer/IntroRoot/IntroSubtitle
@onready var glitter_container: Control = $IntroLayer/IntroRoot/GlitterContainer
@onready var pause_button: TextureButton = get_node_or_null("UI/PauseButton") as TextureButton
@onready var next_bg: TextureRect = get_node_or_null("UI/NextBg") as TextureRect
@onready var previous_bg: TextureRect = get_node_or_null("UI/PreviousBg") as TextureRect
@onready var previous_button: Button = get_node_or_null("UI/PreviousBg/PreviousButton") as Button

var pause_scene: PackedScene = null
var pause_instance: Node = null
var _pause_visibility_state: Dictionary = {}

var dialogue_panel: Panel = null
var portrait_slot: TextureRect = null
var speaker_label: Label = null
var dialogue_label: Label = null
var next_button: Button = null
var question_label: Label = null
var result_label: Label = null
var choice_buttons: Array[BaseButton] = []
var done_bg: CanvasItem = null
var done_button: Button = null
var question_hud: Control = null
var question_hearts_container: HBoxContainer = null
var question_coins_container: TextureRect = null
var question_coin_label: Label = null
var story_lives: int = 3

var success_label: Label = null
var finish_bg: CanvasItem = null
var finish_button: BaseButton = null
var celebration_layer: Control = null

func _ready() -> void:
	if get_tree() != null:
		get_tree().paused = false
	set_process_input(true)
	set_process_unhandled_input(true)
	_resolve_or_build_dialogue_ui()
	_ensure_finish_ui()
	_setup_pause_button()

	intro_root.gui_input.connect(_on_intro_gui_input)
	intro_blur.gui_input.connect(_on_intro_gui_input)
	intro_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if next_button != null:
		next_button.pressed.connect(_on_next_pressed)
	if previous_button != null and not previous_button.pressed.is_connected(_on_previous_pressed):
		previous_button.pressed.connect(_on_previous_pressed)
	_connect_emotion_button("UI/JoyButton", "Joy")
	_connect_emotion_button("UI/AngerButton", "Anger")
	_connect_emotion_button("UI/FearButton", "Fear")
	_connect_emotion_button("UI/SadnessButton", "Sadness")
	_connect_emotion_button("UI/DisgustButton", "Disgust")

	question_label = get_node_or_null("UI/QuestionLabel") as Label
	result_label = get_node_or_null("UI/ResultLabel") as Label
	choice_buttons = _get_choice_buttons()
	_cache_choice_button_positions()
	done_bg = get_node_or_null("UI/DoneBg") as CanvasItem
	done_button = get_node_or_null("UI/DoneButton") as Button
	if done_button == null:
		done_button = get_node_or_null("UI/DoneBg/DoneButton") as Button
	if done_button != null:
		if not done_button.pressed.is_connected(_on_done_pressed):
			done_button.pressed.connect(_on_done_pressed)
	_set_done_visible(false)
	_set_question_ui_visible(false)
	_ensure_question_hud()

	if dialogue_panel != null:
		dialogue_panel.visible = false
	top_title.visible = false
	tap_hint.visible = false
	_set_emotion_icons_visible(false)
	if portrait_slot != null:
		portrait_slot.visible = false
	if jimm_face != null:
		jimm_face.visible = false
	story_dim_overlay.color = Color(0, 0, 0, 0.08)
	var scene_path: String = String(get_tree().current_scene.scene_file_path)
	var skip_intro_once: bool = GameState.consume_story_skip_intro_once(scene_path)
	var resume_beat_index: int = _consume_retry_beat_index_or_zero()

	_load_emotion_portraits()
	if not skip_intro_once:
		await _play_tap_card(INTRO_START_BLUR, INTRO_ACT2_TITLE, "TAP ANYWHERE TO CONTINUE", false)
		_active_frame = -1
	elif intro_layer != null:
		intro_layer.visible = false

	_intro_done = true
	if dialogue_panel != null:
		dialogue_panel.visible = true
	top_title.visible = true
	tap_hint.visible = true
	tap_hint.text = "CLICK NEXT TO CONTINUE"
	_update_story_navigation_buttons()
	story_lives = 3
	_beat_index = resume_beat_index
	_question_index = _count_questions_before_index(_beat_index - 1)
	await _show_current_beat()

func _count_questions_before_index(target_index: int) -> int:
	if target_index < 0:
		return 0
	var capped: int = mini(target_index, _beats.size() - 1)
	var count: int = 0
	for i in range(capped + 1):
		if bool(_beats[i].get("is_question", false)):
			count += 1
	return count

func _resolve_voice_speaker_key(beat: Dictionary) -> String:
	if bool(beat.get("plain_story", false)):
		return "Narration"
	var speaker: String = String(beat.get("speaker", "")).strip_edges()
	if speaker.is_empty() or speaker.to_lower() == "narrator":
		return "Narration"
	if speaker.to_lower() == "mother":
		return "Mom"
	return speaker

func _count_story_lines_for_speaker_before_index(target_index: int, speaker_key: String) -> int:
	if target_index < 0:
		return 0
	var capped: int = mini(target_index, _beats.size() - 1)
	var count: int = 0
	for i in range(capped + 1):
		var beat: Dictionary = _beats[i]
		if bool(beat.get("is_question", false)) and not bool(beat.get("question_delayed", false)):
			continue
		if String(beat.get("text", "")).strip_edges().is_empty():
			continue
		if _resolve_voice_speaker_key(beat) == speaker_key:
			count += 1
	return count

func _resolve_or_build_dialogue_ui() -> void:
	dialogue_panel = get_node_or_null("UI/DialoguePanel") as Panel
	if dialogue_panel == null:
		dialogue_panel = Panel.new()
		dialogue_panel.name = "DialoguePanel"
		var ui_layer: Node = get_node_or_null("UI")
		if ui_layer != null:
			ui_layer.add_child(dialogue_panel)
			dialogue_panel.anchor_left = 0.04
			dialogue_panel.anchor_top = 0.78
			dialogue_panel.anchor_right = 0.96
			dialogue_panel.anchor_bottom = 0.96

	portrait_slot = dialogue_panel.get_node_or_null("PortraitSlot") as TextureRect
	speaker_label = dialogue_panel.get_node_or_null("SpeakerLabel") as Label
	dialogue_label = dialogue_panel.get_node_or_null("DialogueLabel") as Label
	next_button = get_node_or_null("UI/NextBg/NextButton") as Button

func _ensure_finish_ui() -> void:
	var ui_layer: Node = get_node_or_null("UI")
	if ui_layer == null:
		return

	celebration_layer = Control.new()
	celebration_layer.name = "CelebrationLayer"
	celebration_layer.anchor_right = 1.0
	celebration_layer.anchor_bottom = 1.0
	celebration_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(celebration_layer)

	success_label = Label.new()
	success_label.name = "SuccessLabel"
	success_label.text = "SUCCESS!"
	success_label.anchor_left = 0.3
	success_label.anchor_top = 0.3
	success_label.anchor_right = 0.7
	success_label.anchor_bottom = 0.42
	success_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	success_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	success_label.modulate.a = 0.0
	success_label.add_theme_font_size_override("font_size", 56)
	success_label.add_theme_color_override("font_color", Color(0.97, 0.95, 0.25, 1.0))
	success_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	success_label.add_theme_constant_override("outline_size", 8)
	ui_layer.add_child(success_label)

	finish_bg = get_node_or_null("FinishBG") as CanvasItem
	if finish_bg == null:
		finish_bg = get_node_or_null("UI/FinishBG") as CanvasItem

	finish_button = get_node_or_null("FinishBG/FinishAct") as BaseButton
	if finish_button == null:
		finish_button = get_node_or_null("UI/FinishBG/FinishAct") as BaseButton
	if finish_button == null:
		finish_button = get_node_or_null("FinishAct") as BaseButton
	if finish_button == null:
		finish_button = get_node_or_null("UI/FinishAct") as BaseButton
	if finish_button == null:
		finish_button = get_node_or_null("FinishActButton") as BaseButton
	if finish_button == null:
		finish_button = get_node_or_null("UI/FinishActButton") as BaseButton

	if finish_button != null and not finish_button.pressed.is_connected(_on_finish_pressed):
		finish_button.pressed.connect(_on_finish_pressed)
	_set_finish_visible(false)

func _on_finish_pressed() -> void:
	await _finish_act()

func _set_finish_visible(visible: bool) -> void:
	if finish_bg != null:
		finish_bg.visible = visible
	if finish_button != null:
		finish_button.visible = visible

func _load_emotion_portraits() -> void:
	var map: Dictionary = {
		"JoyIcon": EMOTION_TEXTURES["Joy"],
		"AngerIcon": EMOTION_TEXTURES["Anger"],
		"FearIcon": EMOTION_TEXTURES["Fear"],
		"SadnessIcon": EMOTION_TEXTURES["Sadness"],
		"DisgustIcon": EMOTION_TEXTURES["Disgust"],
	}
	for node_name in map.keys():
		var icon_rect: TextureRect = _get_emotion_icon_by_name(node_name)
		if icon_rect == null:
			continue
		var p: String = String(map[node_name])
		if ResourceLoader.exists(p):
			icon_rect.texture = load(p) as Texture2D

func _portrait_path_for_speaker(speaker_name: String) -> String:
	var n: String = speaker_name.strip_edges()
	if EMOTION_TEXTURES.has(n):
		return String(EMOTION_TEXTURES[n])
	if SPEAKER_PORTRAITS.has(n):
		return String(SPEAKER_PORTRAITS[n])
	return ""

func _set_jimm_face_for_emotion(emotion_name: String) -> void:
	if jimm_face == null:
		return
	if JIMM_FACE_BY_EMOTION.has(emotion_name):
		var path: String = String(JIMM_FACE_BY_EMOTION[emotion_name])
		if ResourceLoader.exists(path):
			jimm_face.texture = load(path) as Texture2D
			return

func _apply_speaker_visual(speaker: String, plain: bool) -> void:
	if portrait_slot == null or speaker_label == null:
		return
	portrait_slot.visible = false
	portrait_slot.texture = null
	speaker_label.visible = true
	if jimm_face != null:
		jimm_face.visible = false
		jimm_face.texture = null
	if plain or speaker.strip_edges().is_empty() or speaker.strip_edges().to_lower() == "narrator":
		speaker_label.text = "Narration"
		return
	var n: String = speaker.strip_edges()
	speaker_label.text = n
	var path: String = _portrait_path_for_speaker(n)
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	portrait_slot.texture = load(path) as Texture2D
	portrait_slot.visible = true

func _preload_first_frame() -> void:
	var ok: bool = _try_set_background_frame(1)
	background_fallback.visible = not ok
	if ok:
		background_texture.visible = true
		background_texture.modulate = Color(1, 1, 1, 1)
		_active_frame = 1

func _play_tap_card(filename: String, title_text: String = "", subtitle_text: String = "TAP ANYWHERE TO CONTINUE", hide_emotions: bool = true) -> void:
	_intro_glitter_triggered = false
	if dialogue_panel != null:
		dialogue_panel.visible = false
	if pause_button != null:
		pause_button.visible = false
	top_title.visible = false
	tap_hint.visible = false
	if hide_emotions:
		_set_emotion_icons_visible(false)
	_set_question_ui_visible(false)
	if jimm_face != null:
		jimm_face.visible = false
	if intro_layer != null:
		intro_layer.visible = true
		glitter_container.visible = false
		intro_blur.visible = false
	if intro_root != null:
		intro_root.mouse_filter = Control.MOUSE_FILTER_STOP
	if intro_blur != null:
		intro_blur.mouse_filter = Control.MOUSE_FILTER_STOP
	if top_title != null:
		top_title.text = title_text
		top_title.visible = false
	if tap_hint != null:
		tap_hint.visible = false
		tap_hint.text = subtitle_text
	if intro_title != null:
		intro_title.text = title_text
		intro_title.visible = true
	if intro_subtitle != null:
		intro_subtitle.text = subtitle_text
		intro_subtitle.visible = true
	if intro_title != null:
		intro_title.modulate = Color(1, 1, 1, 1)
	if intro_subtitle != null:
		intro_subtitle.modulate = Color(1, 1, 1, 1)
	await _transition_to_frame_path("%s/%s" % [FRAME_FOLDER, filename])
	story_dim_overlay.color = Color(0, 0, 0, 0.0)
	_waiting_intro_tap = true
	await _wait_for_intro_tap()
	if _intro_glitter_triggered:
		await get_tree().create_timer(0.45).timeout
	if intro_layer != null:
		intro_blur.visible = false
		intro_layer.visible = false
	if top_title != null:
		top_title.visible = false
	if tap_hint != null:
		tap_hint.visible = false
	if hide_emotions:
		_set_emotion_icons_visible(false)
	if pause_button != null and pause_instance == null:
		pause_button.visible = true

func _wait_for_intro_tap() -> void:
	while _waiting_intro_tap:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_select"):
			_play_intro_glitter()
			_waiting_intro_tap = false
			break
		await get_tree().process_frame

func _input(event: InputEvent) -> void:
	if not _waiting_intro_tap:
		return
	if _is_tap(event):
		_play_intro_glitter()
		_waiting_intro_tap = false
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		_play_intro_glitter()
		_waiting_intro_tap = false
		get_viewport().set_input_as_handled()

func _on_intro_gui_input(event: InputEvent) -> void:
	if not _waiting_intro_tap:
		return
	if _is_tap(event):
		_play_intro_glitter()
		_waiting_intro_tap = false
		intro_root.accept_event()

func _play_intro_glitter() -> void:
	if _intro_glitter_triggered or glitter_container == null:
		return
	_intro_glitter_triggered = true
	glitter_container.visible = true
	for i in range(40):
		var spark: ColorRect = ColorRect.new()
		spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spark.color = Color.from_hsv(0.12 + randf_range(-0.03, 0.03), 0.35, 1.0, 1.0)
		spark.size = Vector2(randf_range(10.0, 22.0), randf_range(10.0, 22.0))
		spark.position = Vector2(randf_range(120.0, get_viewport_rect().size.x - 120.0), randf_range(40.0, get_viewport_rect().size.y * 0.62))
		spark.rotation = randf_range(0.0, TAU)
		spark.scale = Vector2(0.35, 0.35)
		spark.modulate.a = 0.0
		glitter_container.add_child(spark)
		var tw: Tween = create_tween()
		tw.set_parallel(true)
		tw.set_trans(Tween.TRANS_QUAD)
		tw.set_ease(Tween.EASE_OUT)
		tw.tween_property(spark, "modulate:a", 1.0, 0.08)
		tw.tween_property(spark, "position:y", spark.position.y - randf_range(55.0, 120.0), 0.5)
		tw.tween_property(spark, "scale", Vector2(1.0, 1.0), 0.16)
		tw.finished.connect(func() -> void:
			if is_instance_valid(spark):
				spark.queue_free()
		)

func _unhandled_input(event: InputEvent) -> void:
	if _waiting_intro_tap and _is_tap(event):
		_play_intro_glitter()
		_waiting_intro_tap = false
		return
	if _question_active:
		return
	if not _intro_done:
		return
	if _is_tap(event):
		_advance_story()

func _is_tap(event: InputEvent) -> bool:
	return (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventScreenTouch and event.pressed)

func _on_next_pressed() -> void:
	get_viewport().set_input_as_handled()
	_advance_story()

func _on_previous_pressed() -> void:
	get_viewport().set_input_as_handled()
	if _question_active or _waiting_intro_tap:
		return
	if _beat_index <= 0:
		return
	_beat_index -= 1
	await _show_current_beat()

func _advance_story() -> void:
	if _question_active:
		return
	if _question_pending:
		# Show the question now
		_question_pending = false
		await _enter_question_state(_beats[_beat_index])
		return
	_beat_index += 1
	if _beat_index >= _beats.size():
		await _finish_act()
		return
	await _show_current_beat()

func _show_current_beat() -> void:
	if _beat_index < 0 or _beat_index >= _beats.size():
		return
	var beat: Dictionary = _beats[_beat_index]
	_question_active = false
	_question_pending = false
	_emotion_show_idle_float = bool(beat.get("emotion_float", false))
	_set_question_ui_visible(false)
	_update_story_navigation_buttons()

	if beat.has("tap_card"):
		await _play_tap_card(
			String(beat["tap_card"]),
			String(beat.get("tap_title", "")),
			String(beat.get("tap_subtitle", "TAP ANYWHERE TO CONTINUE"))
		)
		await _advance_story()
		return

	if bool(beat.get("is_question", false)):
		if bool(beat.get("question_delayed", false)):
			# Show the dialogue first, then set pending for next click
			_question_pending = true
			_question_active = false
		else:
			await _enter_question_state(beat)
			return

	await _set_frame_from_beat(beat)
	_apply_dim_from_beat(beat)
	_save_story_continue_progress_for_current_beat()

	var show_emotions: bool = _should_show_emotions_for_beat_index(_beat_index)
	if show_emotions:
		var was_visible: bool = _are_emotion_icons_visible()
		_set_emotion_icons_visible(true)
		if not was_visible:
			await _animate_emotions_pop_in()
		else:
			_start_emotion_idle_float(_get_emotion_icon_controls())
	else:
		_set_emotion_icons_visible(false)
		_emotion_show_idle_float = false

	if bool(beat.get("blur_reveal", false)):
		await _play_story_blur_reveal()

	_set_question_ui_visible(false)
	if jimm_face != null:
		jimm_face.visible = false

	if dialogue_panel != null:
		dialogue_panel.visible = true
	top_title.visible = true
	tap_hint.visible = true

	var plain: bool = bool(beat.get("plain_story", false))
	var speaker: String = String(beat.get("speaker", ""))
	var line_text: String = String(beat.get("text", ""))
	if dialogue_label != null:
		dialogue_label.text = line_text
	_apply_speaker_visual(speaker, plain)
	var speaker_key: String = _resolve_voice_speaker_key(beat)
	var speaker_line_index: int = _count_story_lines_for_speaker_before_index(_beat_index, speaker_key)
	STORY_VOICE_MANAGER.play_story_line(2, speaker, line_text, plain, speaker_line_index)
	if next_button != null:
		next_button.text = "Next"
	_update_story_navigation_buttons()
	_emotions_revealed = show_emotions

func _enter_question_state(beat: Dictionary) -> void:
	_question_active = true
	_emotion_show_idle_float = false
	_question_index = _count_questions_before_index(_beat_index)
	_active_question_correct = String(beat.get("correct_emotion", ""))
	_active_question_feedback = Dictionary(beat.get("feedback", {}))

	await _set_frame_from_beat(beat)
	story_dim_overlay.color = Color(0, 0, 0, float(beat.get("dim", 0.34)))
	_save_story_continue_progress_for_current_beat()
	_set_emotion_icons_visible(_should_show_emotions_for_beat_index(_beat_index))
	_stop_emotion_idle_tweens()

	if dialogue_panel != null:
		dialogue_panel.visible = false
	top_title.visible = false
	tap_hint.visible = false
	_set_question_ui_visible(true)
	story_lives = 3
	_update_story_hearts_ui()
	if question_label != null:
		question_label.text = String(beat.get("question", "What is Jimm feeling right now?"))
	if result_label != null:
		result_label.text = "Pick the correct emotion."
		result_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	STORY_VOICE_MANAGER.play_story_question(2, String(beat.get("question", "")), _question_index)

	_set_jimm_face_for_emotion(_active_question_correct)
	if jimm_face != null:
		jimm_face.visible = true
		jimm_face.modulate = Color(1, 1, 1, 1)
	await _animate_question_pop_in()
	_start_choice_idle_float()

func _on_emotion_selected(emotion_name: String) -> void:
	if not _question_active:
		return
	if result_label == null:
		return
	_stop_choice_float_tweens()
	STORY_VOICE_MANAGER.play_emotion_question_feedback(2, emotion_name, _question_index)
	if _active_question_feedback.has(emotion_name):
		result_label.text = String(_active_question_feedback[emotion_name])
		result_label.add_theme_color_override("font_color", _emotion_feedback_color(emotion_name))
	if emotion_name == _active_question_correct:
		if AudioManager != null:
			AudioManager.play_sfx("correct_choice")
		_question_active = false
		await _animate_correct_choice(emotion_name)
		_set_done_visible(true)
		if done_button != null:
			done_button.grab_focus()
		return
	if AudioManager != null:
		AudioManager.play_sfx("wrong_choice")
	_lose_story_life()

func _emotion_feedback_color(emotion_name: String) -> Color:
	match emotion_name.strip_edges().to_lower():
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

func _animate_correct_choice(correct_emotion: String) -> void:
	_stop_choice_float_tweens()
	for button in choice_buttons:
		if button == null:
			continue
		var button_name: String = String(button.name)
		if button_name.begins_with(correct_emotion):
			button.z_index = 10
			var pop_tw: Tween = create_tween()
			pop_tw.set_parallel(true)
			pop_tw.set_trans(Tween.TRANS_BACK)
			pop_tw.set_ease(Tween.EASE_OUT)
			pop_tw.tween_property(button, "scale", Vector2(1.15, 1.15), 0.18)
			pop_tw.tween_property(button, "position:y", button.position.y - 14.0, 0.18)
		else:
			var out_tw: Tween = create_tween()
			out_tw.set_parallel(true)
			out_tw.set_trans(Tween.TRANS_QUAD)
			out_tw.set_ease(Tween.EASE_IN)
			out_tw.tween_property(button, "modulate:a", 0.0, 0.18)
			out_tw.tween_property(button, "scale", Vector2(0.7, 0.7), 0.18)
			out_tw.finished.connect(func() -> void:
				if is_instance_valid(button):
					button.visible = false
			)
	await get_tree().create_timer(0.2).timeout

func _on_done_pressed() -> void:
	_set_done_visible(false)
	if jimm_face != null:
		jimm_face.visible = false
	_set_emotion_icons_visible(false)
	_set_question_ui_visible(false)
	story_dim_overlay.color = Color(0, 0, 0, 0.08)
	await get_tree().create_timer(0.15).timeout
	await _advance_story()

func _set_done_visible(visible: bool) -> void:
	if done_bg != null:
		done_bg.visible = visible
	if done_button != null:
		done_button.visible = visible

func _ensure_question_hud() -> void:
	var ui_layer: Node = get_node_or_null("UI")
	if ui_layer == null:
		return
	if question_hud != null:
		return

	question_hud = Control.new()
	question_hud.name = "QuestionHud"
	question_hud.visible = false
	question_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ui_layer is CanvasLayer:
		(ui_layer as CanvasLayer).add_child(question_hud)
	else:
		add_child(question_hud)

	question_hearts_container = HBoxContainer.new()
	question_hearts_container.name = "Hearts"
	question_hearts_container.position = Vector2(24, 18)
	question_hearts_container.add_theme_constant_override("separation", 8)
	question_hud.add_child(question_hearts_container)

	var heart_icon: Texture2D = load("res://assets/UI/Icons/Icon_Large_HeartFull.png") as Texture2D
	for i in range(3):
		var heart: TextureRect = TextureRect.new()
		heart.texture = heart_icon
		heart.custom_minimum_size = Vector2(34, 34)
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		question_hearts_container.add_child(heart)

	question_coins_container = null
	question_coin_label = null

func _set_question_hud_visible(visible: bool) -> void:
	if question_hud != null:
		question_hud.visible = visible
	if visible:
		_update_story_hearts_ui()

func _consume_retry_beat_index_or_zero() -> int:
	var scene_path: String = String(get_tree().current_scene.scene_file_path)
	var retry_index: int = GameState.consume_story_retry_beat_index(scene_path)
	if retry_index < 0:
		return 0
	return clampi(retry_index, 0, _beats.size() - 1)

func _save_story_continue_progress_for_current_beat() -> void:
	if _beat_index < 0 or _beat_index >= _beats.size():
		return
	var scene_path: String = String(get_tree().current_scene.scene_file_path)
	if scene_path.is_empty():
		return
	var frame_path: String = _resolve_frame_path_for_beat(_beats[_beat_index])
	GameState.set_story_continue_progress(scene_path, _beat_index, frame_path)

func _resolve_frame_path_for_beat(beat: Dictionary) -> String:
	if beat.has("frame_path"):
		return "%s/%s" % [FRAME_FOLDER, String(beat.get("frame_path", ""))]
	var fnum: int = int(beat.get("frame", 1))
	return "%s/frame_%02d.png" % [FRAME_FOLDER, fnum]

func _update_story_hearts_ui() -> void:
	if question_hearts_container == null:
		return
	for i in range(question_hearts_container.get_child_count()):
		var heart: TextureRect = question_hearts_container.get_child(i) as TextureRect
		if heart == null:
			continue
		heart.modulate.a = 1.0 if i < story_lives else 0.2

func _lose_story_life() -> void:
	story_lives = maxi(0, story_lives - 1)
	_update_story_hearts_ui()
	if story_lives > 0:
		return
	var retry_index: int = _beat_index
	if _beat_index >= 0 and _beat_index < _beats.size():
		var beat: Dictionary = _beats[_beat_index]
		if not bool(beat.get("question_delayed", false)):
			retry_index = maxi(0, _beat_index - 1)
	GameState.set_story_retry_context(String(get_tree().current_scene.scene_file_path), retry_index)
	_change_scene_to_file(STORY_FAIL_SCENE)

func _play_story_coin_gain_animation() -> void:
	if question_coin_label == null:
		return
	question_coin_label.text = str(GameState.coins)
	if question_coins_container != null:
		var box_tween: Tween = create_tween().bind_node(question_coins_container)
		box_tween.set_trans(Tween.TRANS_BACK)
		box_tween.set_ease(Tween.EASE_OUT)
		box_tween.tween_property(question_coins_container, "scale", Vector2(1.08, 1.08), 0.1)
		box_tween.tween_property(question_coins_container, "scale", Vector2.ONE, 0.12)
		var gain_label: Label = Label.new()
		gain_label.text = "+1"
		gain_label.position = question_coins_container.position + Vector2(36, -18)
		gain_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.35, 1.0))
		gain_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		gain_label.add_theme_constant_override("outline_size", 4)
		gain_label.add_theme_font_size_override("font_size", 24)
		question_hud.add_child(gain_label)
		var gain_tween: Tween = create_tween().bind_node(gain_label)
		gain_tween.set_parallel(true)
		gain_tween.set_trans(Tween.TRANS_QUAD)
		gain_tween.set_ease(Tween.EASE_OUT)
		gain_tween.tween_property(gain_label, "position:y", gain_label.position.y - 26.0, 0.35)
		gain_tween.tween_property(gain_label, "modulate:a", 0.0, 0.35)
		gain_tween.finished.connect(func() -> void:
			if is_instance_valid(gain_label):
				gain_label.queue_free()
		)
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(question_coin_label, "scale", Vector2(1.22, 1.22), 0.12)
	tw.tween_property(question_coin_label, "modulate", Color(1.0, 1.0, 0.45, 1.0), 0.12)
	tw.tween_property(question_coin_label, "scale", Vector2.ONE, 0.14)
	tw.tween_property(question_coin_label, "modulate", Color(1, 1, 1, 1), 0.14)

func _finish_act() -> void:
	if _question_active:
		return
	GameState.clear_story_continue_progress(String(get_tree().current_scene.scene_file_path))
	ResultData.coins_earned = 3
	GameState.add_coins(ResultData.coins_earned)
	GameState.current_story_act = 2
	GameState.unlock_story_act(3)
	_change_scene_to_file(STORY_END_SCENE)

func _play_party_popper() -> void:
	if celebration_layer == null:
		return
	var center_x: float = get_viewport_rect().size.x * 0.5
	var origin_y: float = get_viewport_rect().size.y * 0.34
	for i in range(40):
		var p: ColorRect = ColorRect.new()
		p.color = Color.from_hsv(randf(), 0.85, 1.0, 1.0)
		p.custom_minimum_size = Vector2(7, 14)
		p.size = Vector2(7, 14)
		p.position = Vector2(center_x, origin_y)
		celebration_layer.add_child(p)
		var target: Vector2 = Vector2(
			center_x + randf_range(-430.0, 430.0),
			origin_y + randf_range(120.0, 330.0)
		)
		var t: Tween = create_tween()
		t.set_parallel(true)
		t.set_trans(Tween.TRANS_CUBIC)
		t.set_ease(Tween.EASE_OUT)
		t.tween_property(p, "position", target, 0.9)
		t.tween_property(p, "rotation", randf_range(-2.6, 2.6), 0.9)
		t.tween_property(p, "modulate:a", 0.0, 0.9)
		t.finished.connect(func() -> void:
			if is_instance_valid(p):
				p.queue_free()
		)
	await get_tree().create_timer(0.95).timeout

func _set_frame_from_beat(beat: Dictionary) -> void:
	if beat.has("frame_path"):
		await _transition_to_frame_path("%s/%s" % [FRAME_FOLDER, String(beat.get("frame_path", ""))])
		return
	var fnum: int = int(beat.get("frame", 1))
	if _active_frame == fnum:
		return
	await _transition_to_frame(fnum)

func _transition_to_frame(frame_number: int) -> void:
	var frame_path: String = "%s/frame_%02d.png" % [FRAME_FOLDER, frame_number]
	await _transition_to_frame_path(frame_path)
	_active_frame = frame_number

func _transition_to_frame_path(path: String) -> void:
	if not ResourceLoader.exists(path):
		push_warning("StoryAct1Level1: missing frame: %s" % path)
		return
	var tex: Texture2D = load(path) as Texture2D
	if tex == null:
		return

	if background_texture.texture == null:
		background_texture.texture = tex
		background_texture.visible = true
		background_texture.modulate = Color(1, 1, 1, 1)
		background_fallback.visible = false
		return
	background_texture.texture = tex
	background_texture.scale = Vector2(1.0, 1.0)
	background_texture.position = Vector2.ZERO
	background_texture.modulate = Color(1, 1, 1, 1)
	background_texture.visible = true
	background_fallback.visible = false

func _apply_dim_from_beat(beat: Dictionary) -> void:
	if beat.has("dim"):
		var a: float = float(beat.get("dim", 0.2))
		story_dim_overlay.color = Color(0, 0, 0, clampf(a, 0.0, 0.85))
	else:
		story_dim_overlay.color = Color(0, 0, 0, 0.08)

func _get_emotion_icon_controls() -> Array[Control]:
	var icons: Array[Control] = []
	for node_name in ["JoyIcon", "SadnessIcon", "AngerIcon", "DisgustIcon", "FearIcon"]:
		var c: Control = _get_emotion_icon_by_name(node_name)
		if c != null:
			icons.append(c)
	return icons

func _get_emotion_icon_by_name(node_name: String) -> Control:
	if emotion_showcase != null:
		var c: Control = emotion_showcase.get_node_or_null(node_name) as Control
		if c == null:
			c = emotion_showcase.get_node_or_null("EmotionRow/%s" % node_name) as Control
		if c != null:
			return c
	return get_node_or_null(node_name) as Control

func _are_emotion_icons_visible() -> bool:
	for icon in _get_emotion_icon_controls():
		if icon != null and icon.visible:
			return true
	return false

func _set_emotion_icons_visible(visible: bool) -> void:
	for icon in _get_emotion_icon_controls():
		if icon != null:
			icon.visible = visible
	if not visible:
		_stop_emotion_idle_tweens()

func _should_show_emotions_for_beat_index(beat_index: int) -> bool:
	if beat_index < 0 or beat_index >= _beats.size():
		return false
	return bool(_beats[beat_index].get("show_emotions", false))

func _stop_emotion_idle_tweens() -> void:
	for tw in _emotion_idle_tweens:
		if tw != null:
			tw.kill()
	_emotion_idle_tweens.clear()

func _start_emotion_idle_float(icons: Array[Control]) -> void:
	_stop_emotion_idle_tweens()
	if not _emotion_show_idle_float:
		return
	for i in range(icons.size()):
		var icon: Control = icons[i]
		if icon == null:
			continue
		var base_pos: Vector2 = icon.position
		var rise: float = 7.0 + float(i % 3)
		var idle_tw: Tween = create_tween()
		idle_tw.set_loops()
		idle_tw.set_trans(Tween.TRANS_SINE)
		idle_tw.set_ease(Tween.EASE_IN_OUT)
		idle_tw.tween_interval(0.08 * i)
		idle_tw.tween_property(icon, "position:y", base_pos.y - rise, 0.7)
		idle_tw.tween_property(icon, "position:y", base_pos.y + rise * 0.45, 0.7)
		_emotion_idle_tweens.append(idle_tw)

func _animate_emotions_pop_in() -> void:
	var icons: Array[Control] = _get_emotion_icon_controls()
	if icons.is_empty():
		return
	_stop_emotion_idle_tweens()
	var delay: float = 0.0
	for i in range(icons.size()):
		var c: Control = icons[i]
		var target_pos: Vector2 = c.position
		c.scale = Vector2(0.2, 0.2)
		c.modulate.a = 0.0
		c.position = target_pos + Vector2(0.0, -120.0)
		c.pivot_offset = c.size * 0.5
		var pop_tw: Tween = create_tween()
		pop_tw.set_trans(Tween.TRANS_BACK)
		pop_tw.set_ease(Tween.EASE_OUT)
		pop_tw.tween_interval(delay)
		pop_tw.tween_property(c, "position", target_pos, 0.46)
		pop_tw.parallel().tween_property(c, "scale", Vector2(1.0, 1.0), 0.46)
		pop_tw.parallel().tween_property(c, "modulate:a", 1.0, 0.34)
		delay += 0.08
	await get_tree().create_timer(0.2 + delay).timeout
	_start_emotion_idle_float(icons)

func _play_story_blur_reveal() -> void:
	intro_layer.visible = true
	intro_title.visible = false
	intro_subtitle.visible = false
	glitter_container.visible = false
	intro_blur.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro_blur.color = Color(0.12, 0.14, 0.22, 0.58)
	intro_blur.color.a = 0.78
	var tw: Tween = create_tween()
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(intro_blur, "color:a", 0.0, 0.7)
	await tw.finished
	intro_layer.visible = false

func _connect_emotion_button(node_path: String, emotion_name: String) -> void:
	var button_node: BaseButton = get_node_or_null(node_path) as BaseButton
	if button_node == null:
		return
	button_node.pressed.connect(func() -> void:
		_on_emotion_selected(emotion_name)
	)

func _get_choice_buttons() -> Array[BaseButton]:
	var out: Array[BaseButton] = []
	for p in ["UI/JoyButton", "UI/AngerButton", "UI/FearButton", "UI/SadnessButton", "UI/DisgustButton"]:
		var b: BaseButton = get_node_or_null(p) as BaseButton
		if b != null:
			out.append(b)
	return out

func _cache_choice_button_positions() -> void:
	_choice_button_base_positions.clear()
	for b in choice_buttons:
		if b != null:
			_choice_button_base_positions[String(b.get_path())] = b.position

func _stop_choice_float_tweens() -> void:
	for tw in _choice_float_tweens:
		if tw != null:
			tw.kill()
	_choice_float_tweens.clear()

func _restore_choice_buttons_state() -> void:
	for b in choice_buttons:
		if b == null:
			continue
		var key: String = String(b.get_path())
		if _choice_button_base_positions.has(key):
			b.position = _choice_button_base_positions[key]
		else:
			_choice_button_base_positions[key] = b.position
		b.scale = Vector2.ONE
		b.modulate = Color(1, 1, 1, 1)
		b.z_index = 0

func _start_choice_idle_float() -> void:
	_stop_choice_float_tweens()
	for i in range(choice_buttons.size()):
		var b: BaseButton = choice_buttons[i]
		if b == null or not b.visible:
			continue
		var key: String = String(b.get_path())
		var base_pos: Vector2 = b.position
		if _choice_button_base_positions.has(key):
			base_pos = _choice_button_base_positions[key]
		else:
			_choice_button_base_positions[key] = base_pos
		b.position = base_pos
		var rise: float = 6.0 + float(i % 2)
		var idle_tw: Tween = create_tween()
		idle_tw.set_loops()
		idle_tw.set_trans(Tween.TRANS_SINE)
		idle_tw.set_ease(Tween.EASE_IN_OUT)
		idle_tw.tween_interval(0.05 * i)
		idle_tw.tween_property(b, "position:y", base_pos.y - rise, 0.62)
		idle_tw.tween_property(b, "position:y", base_pos.y + rise * 0.35, 0.62)
		_choice_float_tweens.append(idle_tw)

func _set_question_ui_visible(visible: bool) -> void:
	if visible:
		_restore_choice_buttons_state()
		_stop_choice_float_tweens()
	else:
		_stop_choice_float_tweens()
	if question_label != null:
		question_label.visible = visible
	if result_label != null:
		result_label.visible = visible
	for b in choice_buttons:
		if b != null:
			b.visible = visible
	_set_question_hud_visible(visible)
	if not visible:
		_set_done_visible(false)
	_update_story_navigation_buttons()

func _update_story_navigation_buttons() -> void:
	var allow_story_nav: bool = _intro_done and not _question_active and not _waiting_intro_tap
	var show_prev: bool = allow_story_nav and _beat_index > 0
	var show_next: bool = allow_story_nav and _beat_index >= 0 and _beat_index < _beats.size()
	
	var is_showing_dialogue: bool = (dialogue_panel == null) or (dialogue_panel != null and dialogue_panel.visible)
	show_next = show_next and is_showing_dialogue
	show_prev = show_prev and is_showing_dialogue
	
	# Show finish button instead of next button on the last scene
	var has_finish_ui: bool = (finish_bg != null) or (finish_button != null)
	var show_finish: bool = allow_story_nav and _beat_index == _beats.size() - 1 and is_showing_dialogue and has_finish_ui
	if show_finish:
		show_prev = false
	
	if next_bg != null:
		next_bg.visible = show_next and not show_finish
	if next_button != null:
		next_button.visible = show_next and not show_finish
	if previous_bg != null:
		previous_bg.visible = show_prev
	if previous_button != null:
		previous_button.visible = show_prev
	_set_finish_visible(show_finish)

func _animate_question_pop_in() -> void:
	var nodes: Array[CanvasItem] = []
	if question_label != null:
		nodes.append(question_label)
	if result_label != null:
		nodes.append(result_label)
	if jimm_face != null:
		nodes.append(jimm_face)
	for button in choice_buttons:
		if button != null:
			nodes.append(button)
	if done_button != null and done_button.visible:
		nodes.append(done_button)
	if nodes.is_empty():
		return
	_play_question_sparkle_burst()
	for node in nodes:
		node.scale = Vector2(0.0, 0.0)
		node.modulate.a = 0.0
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_OUT)
	for node in nodes:
		tw.tween_property(node, "scale", Vector2.ONE, 0.32)
		tw.parallel().tween_property(node, "modulate:a", 1.0, 0.22)
	await tw.finished

func _play_question_sparkle_burst() -> void:
	if question_label == null:
		return
	var q_rect := question_label.get_global_rect()
	for i in range(12):
		var spark := ColorRect.new()
		spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spark.color = Color(1.0, 0.95, 0.65, 1.0)
		spark.size = Vector2(randf_range(6.0, 12.0), randf_range(6.0, 12.0))
		spark.position = Vector2(
			randf_range(q_rect.position.x - 40.0, q_rect.end.x + 40.0),
			randf_range(q_rect.position.y - 28.0, q_rect.end.y + 28.0)
		)
		add_child(spark)
		var tw := create_tween()
		tw.set_parallel(true)
		tw.set_trans(Tween.TRANS_BACK)
		tw.set_ease(Tween.EASE_OUT)
		spark.scale = Vector2(0.0, 0.0)
		spark.modulate.a = 0.0
		tw.tween_property(spark, "scale", Vector2.ONE, 0.18)
		tw.parallel().tween_property(spark, "modulate:a", 1.0, 0.10)
		tw.tween_interval(0.08)
		tw.tween_property(spark, "scale", Vector2(0.0, 0.0), 0.20)
		tw.parallel().tween_property(spark, "modulate:a", 0.0, 0.18)
		tw.finished.connect(func() -> void:
			if is_instance_valid(spark):
				spark.queue_free()
		)
func _change_scene_to_file(scene_path: String) -> void:
	var transition_node: Node = get_node_or_null("/root/SceneTransition")
	if transition_node and transition_node.has_method("change_scene_to_file"):
		transition_node.call("change_scene_to_file", scene_path)
		return
	get_tree().change_scene_to_file(scene_path)

func _setup_pause_button() -> void:
	if pause_button == null:
		return
	pause_scene = load("res://scenes/Story/StoryPauseScene.tscn")
	if not pause_button.pressed.is_connected(_on_pause_pressed):
		pause_button.pressed.connect(_on_pause_pressed)

func _on_pause_pressed() -> void:
	if pause_instance != null:
		_restore_story_ui_after_pause()
		pause_instance.queue_free()
		pause_instance = null
		if pause_button != null:
			pause_button.visible = true
		get_tree().paused = false
		return
	if pause_scene == null:
		return
	_cache_story_ui_for_pause()
	pause_instance = pause_scene.instantiate()
	add_child(pause_instance)
	if pause_instance != null and pause_instance.has_method("set_pause_background"):
		pause_instance.call("set_pause_background", background_texture.texture)
	if pause_button != null:
		pause_button.visible = false
	if AudioManager != null:
		AudioManager.stop_voice()
	get_tree().paused = true

func _cache_story_ui_for_pause() -> void:
	_pause_visibility_state.clear()
	for node in _get_pause_hide_targets():
		if node != null:
			_pause_visibility_state[node] = node.visible
			node.visible = false

func _restore_story_ui_after_pause() -> void:
	for node in _pause_visibility_state.keys():
		if is_instance_valid(node):
			node.visible = bool(_pause_visibility_state[node])
	_pause_visibility_state.clear()

func _on_story_pause_resumed() -> void:
	_restore_story_ui_after_pause()
	pause_instance = null
	if pause_button != null:
		pause_button.visible = true

func _get_pause_hide_targets() -> Array[CanvasItem]:
	var targets: Array[CanvasItem] = []
	if dialogue_panel != null:
		targets.append(dialogue_panel)
	if question_label != null:
		targets.append(question_label)
	if result_label != null:
		targets.append(result_label)
	if next_bg != null:
		targets.append(next_bg)
	if next_button != null:
		targets.append(next_button)
	if previous_bg != null:
		targets.append(previous_bg)
	if previous_button != null:
		targets.append(previous_button)
	if pause_button != null:
		targets.append(pause_button)
	if finish_bg != null:
		targets.append(finish_bg)
	if finish_button != null:
		targets.append(finish_button)
	for button in choice_buttons:
		if button != null:
			targets.append(button)
	if done_button != null:
		targets.append(done_button)
	if top_title != null:
		targets.append(top_title)
	if tap_hint != null:
		targets.append(tap_hint)
	for icon in _get_emotion_icon_controls():
		if icon != null:
			targets.append(icon)
	if jimm_face != null:
		targets.append(jimm_face)
	return targets

func _try_set_background_frame(frame_number: int) -> bool:
	var frame_path: String = "%s/frame_%02d.png" % [FRAME_FOLDER, frame_number]
	return _try_set_background_path(frame_path)

func _try_set_background_path(path: String) -> bool:
	if not ResourceLoader.exists(path):
		push_warning("StoryAct1Level1: missing frame: %s" % path)
		return false
	var resource: Resource = load(path)
	if resource is Texture2D:
		background_texture.texture = resource as Texture2D
		background_texture.visible = true
		background_fallback.visible = false
		return true
	return false
