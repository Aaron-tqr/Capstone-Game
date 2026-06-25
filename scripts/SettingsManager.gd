extends Control

@onready var music_slider: HSlider = $MusicSlider
@onready var sound_slider: HSlider = $SoundSlider
@onready var music_volume_label: Label = $MusicVolumeLabel
@onready var sound_volume_label: Label = $SoundVolumeLabel
@onready var save_button: TextureButton = get_node_or_null("TextureButton2")
@onready var save_button_label: Label = get_node_or_null("TextureButton2/Help2") as Label
@onready var how_to_play_root: Control = get_node_or_null("HowToPlay") as Control
@onready var help_button: BaseButton = get_node_or_null("HowToPlay/TextureButton") as BaseButton

# Audio bus names (create these in Project > Audio Bus Layout if they don't exist)
const MUSIC_BUS: String = "Music"
const SFX_BUS: String = "SFX"
const FALLBACK_BUS: String = "Master"
const SETTINGS_PATH: String = "user://settings.cfg"

# Min/max dB for audio buses
const MIN_DB: float = -40.0
const MAX_DB: float = 0.0

# Store current volumes
var _current_music_db: float = 0.0
var _current_sfx_db: float = 0.0
var _is_returning_after_save: bool = false
var _tutorial_panel: PanelContainer = null
var _tutorial_slides_by_mode: Dictionary = {}
var _tutorial_mode: String = "story"
var _tutorial_index: int = 0
var _tutorial_title_label: Label = null
var _tutorial_image: TextureRect = null
var _tutorial_desc_label: RichTextLabel = null
var _tutorial_page_label: Label = null
var _tutorial_prev_button: Button = null
var _tutorial_next_button: Button = null
var _tutorial_mode_buttons: Dictionary = {}

const STORY_SLIDES: Array[Dictionary] = [
	{
		"title": "Story Slide 1: Choose An Act",
		"text": "Open Story mode, then pick which Act to play. Each Act is a chapter of Jimm's emotional journey. Start from unlocked acts and continue as you progress.",
		"image": "res://assets/story/bgstory.png"
	},
	{
		"title": "Story Slide 2: Inside The Selected Act",
		"text": "After choosing an Act, you enter that Act's scene flow. This is where the chapter's events, choices, and story progression happen.",
		"image": "res://assets/story/act1.png"
	},
	{
		"title": "Story Slide 3: Intro Scene",
		"text": "At the start, an introduction appears. Tap or click anywhere when prompted to continue to the next part.",
		"image": "res://assets/story/act11.png"
	},
	{
		"title": "Story Slide 4: Dialogue Panel Controls",
		"text": "Read dialogue through the panel. Use Next to move forward and Previous to revisit lines. This helps players understand character emotions before gameplay tasks.",
		"image": "res://assets/story/background story level1.png"
	},
	{
		"title": "Story Slide 5: Emotion Question Gameplay",
		"text": "Some story points ask what emotion Jimm is showing. Choose the best matching emotion based on the scene and dialogue clues.",
		"image": "res://assets/background/SELECT-GAME-MODE-11-13-2025.png"
	},
	{
		"title": "Story Slide 6: Win/Fail, Lives, Coins",
		"text": "Correct actions help you succeed and continue. Mistakes reduce hearts. If hearts run out, you fail and can retry. Winning can grant progression and coin rewards.",
		"image": "res://assets/UI/Icons/Icon_Small_Coin.png"
	},
	{
		"title": "Story Slide 7: Success Scene",
		"text": "After completing the objective, a success/result scene appears. From there, continue to the next part, replay, or return to menus.",
		"image": "res://assets/story/act2/act2 end blur.png"
	},
	{
		"title": "Story Slide 8: End Of Story Tutorial",
		"text": "You are ready for Story mode. Follow dialogue, observe emotions, and answer correctly to progress through all Acts.",
		"image": "res://assets/story/act3/ending end blur.png"
	}
]

const EMOTION_SLIDES: Array[Dictionary] = [
	{
		"title": "Emotion Slide 1: Character Select",
		"text": "Choose an emotion character: Joy, Sadness, Anger, Fear, or Disgust.",
		"image": "res://assets/background/mode select.jpeg"
	},
	{
		"title": "Emotion Slide 2: Match The Correct Face",
		"text": "Drag matching emoticons to the target character. Correct drops remove matching faces and increase progress.",
		"image": "res://assets/UI/Emoji for levels/—Pngtree—3d emoji set_6841058.png"
	},
	{
		"title": "Emotion Slide 3: Hearts And Mistakes",
		"text": "Wrong drops cost hearts. If hearts reach zero, the level fails.",
		"image": "res://assets/UI/Icons/Icon_Large_HeartFull.png"
	},
	{
		"title": "Emotion Slide 4: Hint Book",
		"text": "Tap Hint to open emotion hints. Locked hints use coins and ask for confirmation before unlocking.",
		"image": "res://assets/UI/book.png"
	},
	{
		"title": "Emotion Slide 5: Level Complete",
		"text": "Match all required faces to win, then continue to the next level.",
		"image": "res://assets/story/act2/frame_08.png"
	}
]

const WORD_SLIDES: Array[Dictionary] = [
	{
		"title": "Word Slide 1: Choose Emotion Character",
		"text": "Pick the character whose feeling words you want to match.",
		"image": "res://assets/background/mode select.jpeg"
	},
	{
		"title": "Word Slide 2: Drag The Correct Words",
		"text": "Drag words into the drop target. Only words that describe the chosen emotion are correct.",
		"image": "res://assets/background/Gemini_Generated_Image_7260cn7260cn7260.png"
	},
	{
		"title": "Word Slide 3: Increasing Difficulty",
		"text": "Higher levels require more correct words and better emotion understanding.",
		"image": "res://assets/background/Gemini_Generated_Image_w2r2u8w2r2u8w2r2.png"
	},
	{
		"title": "Word Slide 4: Word Hint Definitions",
		"text": "Use the Hint button to read word meanings and reduce mistakes.",
		"image": "res://assets/UI/book.png"
	},
	{
		"title": "Word Slide 5: Win Condition",
		"text": "Find all required correct words before losing all hearts to clear the level.",
		"image": "res://assets/background/Gemini_Generated_Image_o95efo95efo95efo.png"
	}
]

func _ready() -> void:
	if music_slider != null:
		music_slider.value_changed.connect(_on_music_slider_changed)
	if sound_slider != null:
		sound_slider.value_changed.connect(_on_sound_slider_changed)
	if save_button != null:
		save_button.pressed.connect(_on_save_pressed)
	if help_button != null:
		help_button.pressed.connect(_on_help_pressed)
	_tutorial_slides_by_mode = {
		"story": STORY_SLIDES,
		"emotion": EMOTION_SLIDES,
		"word": WORD_SLIDES,
	}
	
	# Load saved volumes or use defaults
	_load_volumes()
	_update_volume_labels()

func _on_help_pressed() -> void:
	if _tutorial_panel != null and is_instance_valid(_tutorial_panel):
		_close_tutorial_panel()
		return
	_show_tutorial_panel()

func _show_tutorial_panel() -> void:
	if how_to_play_root == null:
		return

	var panel := PanelContainer.new()
	panel.name = "HowToPlayPanelTemp"
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.offset_left = -500.0
	panel.offset_top = -292.0
	panel.offset_right = 500.0
	panel.offset_bottom = 292.0
	panel.z_index = 25

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.11, 0.2, 0.95)
	panel_style.border_color = Color(0.99, 0.67, 0.2, 1.0)
	panel_style.border_width_left = 4
	panel_style.border_width_top = 4
	panel_style.border_width_right = 4
	panel_style.border_width_bottom = 4
	panel_style.corner_radius_top_left = 18
	panel_style.corner_radius_top_right = 18
	panel_style.corner_radius_bottom_left = 18
	panel_style.corner_radius_bottom_right = 18
	panel.add_theme_stylebox_override("panel", panel_style)

	var header := Label.new()
	header.text = "HOW TO PLAY SLIDES"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.offset_left = 18.0
	header.offset_top = 10.0
	header.offset_right = 860.0
	header.offset_bottom = 48.0
	header.add_theme_color_override("font_color", Color(1.0, 0.93, 0.67, 1.0))
	header.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	header.add_theme_constant_override("outline_size", 5)
	panel.add_child(header)

	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.offset_left = 920.0
	close_btn.offset_top = 8.0
	close_btn.offset_right = 978.0
	close_btn.offset_bottom = 44.0
	close_btn.pressed.connect(_close_tutorial_panel)
	panel.add_child(close_btn)

	var mode_story := Button.new()
	mode_story.text = "Story"
	mode_story.offset_left = 18.0
	mode_story.offset_top = 54.0
	mode_story.offset_right = 170.0
	mode_story.offset_bottom = 90.0
	mode_story.pressed.connect(func() -> void:
		_set_tutorial_mode("story")
	)
	panel.add_child(mode_story)

	var mode_emotion := Button.new()
	mode_emotion.text = "Emotion Matching"
	mode_emotion.offset_left = 182.0
	mode_emotion.offset_top = 54.0
	mode_emotion.offset_right = 430.0
	mode_emotion.offset_bottom = 90.0
	mode_emotion.pressed.connect(func() -> void:
		_set_tutorial_mode("emotion")
	)
	panel.add_child(mode_emotion)

	var mode_word := Button.new()
	mode_word.text = "Word Matching"
	mode_word.offset_left = 442.0
	mode_word.offset_top = 54.0
	mode_word.offset_right = 650.0
	mode_word.offset_bottom = 90.0
	mode_word.pressed.connect(func() -> void:
		_set_tutorial_mode("word")
	)
	panel.add_child(mode_word)

	_tutorial_mode_buttons = {
		"story": mode_story,
		"emotion": mode_emotion,
		"word": mode_word,
	}

	var slide_title := Label.new()
	slide_title.offset_left = 18.0
	slide_title.offset_top = 96.0
	slide_title.offset_right = 970.0
	slide_title.offset_bottom = 136.0
	slide_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slide_title.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8, 1.0))
	slide_title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	slide_title.add_theme_constant_override("outline_size", 4)
	panel.add_child(slide_title)
	_tutorial_title_label = slide_title

	var slide_image := TextureRect.new()
	slide_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	slide_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slide_image.offset_left = 42.0
	slide_image.offset_top = 142.0
	slide_image.offset_right = 958.0
	slide_image.offset_bottom = 360.0
	panel.add_child(slide_image)
	_tutorial_image = slide_image

	var slide_desc := RichTextLabel.new()
	slide_desc.bbcode_enabled = false
	slide_desc.scroll_active = true
	slide_desc.fit_content = false
	slide_desc.offset_left = 40.0
	slide_desc.offset_top = 368.0
	slide_desc.offset_right = 958.0
	slide_desc.offset_bottom = 512.0
	slide_desc.add_theme_color_override("default_color", Color(0.95, 0.98, 1.0, 1.0))
	slide_desc.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	slide_desc.add_theme_constant_override("outline_size", 2)
	panel.add_child(slide_desc)
	_tutorial_desc_label = slide_desc

	var prev_btn := Button.new()
	prev_btn.text = "PREVIOUS"
	prev_btn.offset_left = 280.0
	prev_btn.offset_top = 525.0
	prev_btn.offset_right = 430.0
	prev_btn.offset_bottom = 565.0
	prev_btn.pressed.connect(_on_tutorial_prev)
	panel.add_child(prev_btn)
	_tutorial_prev_button = prev_btn

	var page_label := Label.new()
	page_label.offset_left = 442.0
	page_label.offset_top = 528.0
	page_label.offset_right = 556.0
	page_label.offset_bottom = 563.0
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	panel.add_child(page_label)
	_tutorial_page_label = page_label

	var next_btn := Button.new()
	next_btn.text = "NEXT"
	next_btn.offset_left = 568.0
	next_btn.offset_top = 525.0
	next_btn.offset_right = 718.0
	next_btn.offset_bottom = 565.0
	next_btn.pressed.connect(_on_tutorial_next)
	panel.add_child(next_btn)
	_tutorial_next_button = next_btn

	add_child(panel)
	_tutorial_panel = panel
	_tutorial_mode = "story"
	_tutorial_index = 0
	_update_tutorial_slide()

func _close_tutorial_panel() -> void:
	if _tutorial_panel != null and is_instance_valid(_tutorial_panel):
		_tutorial_panel.queue_free()
	_tutorial_panel = null
	_tutorial_title_label = null
	_tutorial_image = null
	_tutorial_desc_label = null
	_tutorial_page_label = null
	_tutorial_prev_button = null
	_tutorial_next_button = null
	_tutorial_mode_buttons.clear()

func _slides_for_mode(mode: String) -> Array:
	return _tutorial_slides_by_mode.get(mode, []) as Array

func _set_tutorial_mode(mode: String) -> void:
	if not _tutorial_slides_by_mode.has(mode):
		return
	_tutorial_mode = mode
	_tutorial_index = 0
	_update_tutorial_slide()

func _on_tutorial_prev() -> void:
	if _tutorial_index <= 0:
		return
	_tutorial_index -= 1
	_update_tutorial_slide()

func _on_tutorial_next() -> void:
	var slides: Array = _slides_for_mode(_tutorial_mode)
	if slides.is_empty():
		return
	if _tutorial_index >= slides.size() - 1:
		_close_tutorial_panel()
		return
	_tutorial_index += 1
	_update_tutorial_slide()

func _update_tutorial_slide() -> void:
	var slides: Array = _slides_for_mode(_tutorial_mode)
	if slides.is_empty():
		return
	if _tutorial_index < 0:
		_tutorial_index = 0
	if _tutorial_index >= slides.size():
		_tutorial_index = slides.size() - 1

	var slide: Dictionary = slides[_tutorial_index] as Dictionary
	var title_text: String = String(slide.get("title", "Tutorial"))
	var body_text: String = String(slide.get("text", ""))
	var image_path: String = String(slide.get("image", ""))

	if _tutorial_title_label != null:
		_tutorial_title_label.text = title_text
	if _tutorial_desc_label != null:
		_tutorial_desc_label.text = body_text
		_tutorial_desc_label.scroll_to_line(0)
	if _tutorial_page_label != null:
		_tutorial_page_label.text = "%d / %d" % [_tutorial_index + 1, slides.size()]
	if _tutorial_prev_button != null:
		_tutorial_prev_button.disabled = (_tutorial_index == 0)
	if _tutorial_next_button != null:
		_tutorial_next_button.text = "FINISH" if _tutorial_index == slides.size() - 1 else "NEXT"

	if _tutorial_image != null:
		var slide_texture: Texture2D = null
		if not image_path.is_empty() and ResourceLoader.exists(image_path):
			slide_texture = load(image_path) as Texture2D
		_tutorial_image.texture = slide_texture

	for key in _tutorial_mode_buttons.keys():
		var mode_button := _tutorial_mode_buttons[key] as Button
		if mode_button != null:
			mode_button.disabled = String(key) == _tutorial_mode

func _on_music_slider_changed(value: float) -> void:
	var db: float = _linear_to_db(value)
	_current_music_db = db
	_apply_bus_volume(MUSIC_BUS, db, value == 0)
	_update_volume_labels()

func _on_sound_slider_changed(value: float) -> void:
	var db: float = _linear_to_db(value)
	_current_sfx_db = db
	_apply_bus_volume(SFX_BUS, db, value == 0)
	_update_volume_labels()

func _on_save_pressed() -> void:
	if _is_returning_after_save:
		return
	save_settings()
	_show_save_feedback_and_return()

func _apply_bus_volume(bus_name: String, db: float, mute: bool) -> void:
	var bus_idx: int = AudioServer.get_bus_index(bus_name)
	if bus_idx >= 0:
		AudioServer.set_bus_mute(bus_idx, mute)
		if not mute:
			AudioServer.set_bus_volume_db(bus_idx, db)
	else:
		# Fallback to Master bus if specific bus doesn't exist
		var master_idx: int = AudioServer.get_bus_index(FALLBACK_BUS)
		if master_idx >= 0:
			AudioServer.set_bus_mute(master_idx, mute)
			if not mute:
				AudioServer.set_bus_volume_db(master_idx, db)

func _update_volume_labels() -> void:
	if music_volume_label != null and music_slider != null:
		music_volume_label.text = "%d%%" % int(music_slider.value)
	if sound_volume_label != null and sound_slider != null:
		sound_volume_label.text = "%d%%" % int(sound_slider.value)

func _linear_to_db(value: float) -> float:
	# Convert from 0-100 slider to MIN_DB to MAX_DB range
	if value == 0:
		return MIN_DB
	var normalized: float = value / 100.0
	return MIN_DB + (normalized * (MAX_DB - MIN_DB))

func _db_to_linear(db: float) -> float:
	# Convert from dB back to 0-100 slider range
	if db <= MIN_DB:
		return 0.0
	var normalized: float = (db - MIN_DB) / (MAX_DB - MIN_DB)
	return clamp(normalized * 100.0, 0.0, 100.0)

func _load_volumes() -> void:
	var config: ConfigFile = ConfigFile.new()
	var has_saved_settings: bool = (config.load(SETTINGS_PATH) == OK)
	if has_saved_settings:
		if music_slider != null:
			music_slider.value = clampf(float(config.get_value("audio", "music_percent", 80.0)), 0.0, 100.0)
		if sound_slider != null:
			sound_slider.value = clampf(float(config.get_value("audio", "sfx_percent", 80.0)), 0.0, 100.0)
		_current_music_db = _linear_to_db(music_slider.value if music_slider != null else 80.0)
		_current_sfx_db = _linear_to_db(sound_slider.value if sound_slider != null else 80.0)
		_apply_bus_volume(MUSIC_BUS, _current_music_db, music_slider != null and music_slider.value == 0)
		_apply_bus_volume(SFX_BUS, _current_sfx_db, sound_slider != null and sound_slider.value == 0)
		return

	# Load saved music volume
	var music_bus_idx: int = AudioServer.get_bus_index(MUSIC_BUS)
	if music_bus_idx >= 0:
		var music_db: float = AudioServer.get_bus_volume_db(music_bus_idx)
		_current_music_db = music_db
		var music_value: float = _db_to_linear(music_db)
		if music_slider != null:
			music_slider.value = music_value
	else:
		# Use Master bus as fallback
		var master_idx: int = AudioServer.get_bus_index(FALLBACK_BUS)
		if master_idx >= 0 and music_slider != null:
			var master_db: float = AudioServer.get_bus_volume_db(master_idx)
			_current_music_db = master_db
			music_slider.value = _db_to_linear(master_db)
	
	# Load saved SFX volume
	var sfx_bus_idx: int = AudioServer.get_bus_index(SFX_BUS)
	if sfx_bus_idx >= 0:
		var sfx_db: float = AudioServer.get_bus_volume_db(sfx_bus_idx)
		_current_sfx_db = sfx_db
		var sfx_value: float = _db_to_linear(sfx_db)
		if sound_slider != null:
			sound_slider.value = sfx_value
	else:
		# Use Master bus as fallback
		var master_idx: int = AudioServer.get_bus_index(FALLBACK_BUS)
		if master_idx >= 0 and sound_slider != null:
			var master_db: float = AudioServer.get_bus_volume_db(master_idx)
			_current_sfx_db = master_db
			sound_slider.value = _db_to_linear(master_db)

func save_settings() -> void:
	# Settings are applied in real-time to audio buses and persisted for next launch.
	var config: ConfigFile = ConfigFile.new()
	config.set_value("audio", "music_percent", music_slider.value if music_slider != null else 80.0)
	config.set_value("audio", "sfx_percent", sound_slider.value if sound_slider != null else 80.0)
	config.save(SETTINGS_PATH)
	print("Settings saved - Music: %.0f%% SFX: %.0f%%" % [music_slider.value, sound_slider.value])

func _show_save_feedback_and_return() -> void:
	_is_returning_after_save = true
	if save_button_label == null:
		_return_to_previous_scene()
		return
	save_button_label.text = "SAVED!"
	var tw: Tween = create_tween()
	tw.tween_interval(0.7)
	tw.tween_callback(func() -> void:
		_return_to_previous_scene()
	)

func _return_to_previous_scene() -> void:
	var target_scene: String = "res://scenes/MainMenu.tscn"
	var overlay_close_only: bool = false
	if "settings_return_scene" in GameState:
		var stored_scene: String = String(GameState.settings_return_scene)
		if stored_scene == "__OVERLAY_STORY_PAUSE__":
			overlay_close_only = true
		elif not stored_scene.is_empty() and ResourceLoader.exists(stored_scene):
			target_scene = stored_scene
		GameState.settings_return_scene = ""
	if overlay_close_only:
		_is_returning_after_save = false
		queue_free()
		return
	if get_tree() != null:
		_change_scene_to_file(target_scene)

func _change_scene_to_file(scene_path: String) -> void:
	var transition_node: Node = get_node_or_null("/root/SceneTransition")
	if transition_node and transition_node.has_method("change_scene_to_file"):
		transition_node.call("change_scene_to_file", scene_path)
		return
	get_tree().change_scene_to_file(scene_path)
