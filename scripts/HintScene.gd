extends Control

signal close_requested

const PAGE_SIZE: int = 6
const UNLOCK_CONFIRM_SCENE: PackedScene = preload("res://scenes/unlock_confirmation.tscn")
const UNLOCK_WORD_COST: int = 1
const UNLOCK_EMOTION_COST: int = 2

const EMOTION_HINT_ENTRIES := [
	{"word": "Joyful", "definition": "This is a very big, excited happy feeling. You feel joyful when you get a giant hug or a favorite treat."},
	{"word": "Grumpy", "definition": "This is a small, cross feeling when you don't want to smile. You might feel grumpy when you have to stop playing and take a nap."},
	{"word": "Angry", "definition": "This is a mad feeling you get when something feels unfair. You feel angry when a toy you are using is taken away."},
	{"word": "Distaste", "definition": "This is a yucky feeling you get when you see something you don't like. You might show distaste when you see a vegetable you think tastes icky."},
	{"word": "Misery", "definition": "This is a very deep, heavy sadness. You feel misery when you are hurt or having a really, really bad day."},
	{"word": "Fuming", "definition": "This is being so mad that you feel hot like a little teakettle. You are fuming when you have to wait a very long time for something you want."},
	{"word": "Rage", "definition": "This is a giant, exploding mad feeling that is bigger than being angry. You feel rage when you want to stomp your feet and growl."},
	{"word": "Grief", "definition": "This is a very sad heart-feeling when you lose something special. You feel grief when a favorite balloon pops or a pet goes away."},
	{"word": "Outrage", "definition": "This is being super mad because you see something that is totally wrong. You feel outrage when you see someone being mean to a friend."},
]

const WORD_DEFINITIONS := {
	"cheerful": "This is a bright and sunny happy feeling. You feel cheerful when you wake up and see the sun shining.",
	"delighted": "This is a very big, sparkly happy feeling. You feel delighted when you get a surprise present.",
	"excited": "This is a bouncy feeling when you can't wait for something. You feel excited when it is almost time for a party.",
	"glad": "This is a nice, warm happy feeling. You feel glad when a friend comes over to play.",
	"glee": "This is a silly, giggly kind of happy. You feel glee when you are playing a fun game of tag.",
	"happy": "This is a good feeling that makes you want to smile. You feel happy when you are doing something you love.",
	"jolly": "This is a big, laughing happy feeling. You feel jolly when you are telling funny jokes with your family.",
	"joy": "This is a very big, excited happy feeling. You feel joyful when you get a giant hug or a favorite treat.",
	"joyful": "This is a very big, excited happy feeling. You feel joyful when you get a giant hug or a favorite treat.",
	"jubilant": "This is a hooray feeling when you want to celebrate. You feel jubilant when you finally finish a big puzzle.",
	"merry": "This is a light and dancing happy feeling. You feel merry when you are singing songs together.",
	"sunny": "This is a glowing happy feeling inside your heart. You feel sunny when everyone is being kind and sweet.",
	"blue": "This is a quiet, slow-feeling sadness. You feel blue when it is rainy and you have to stay inside.",
	"depressed": "This is a very heavy, tired sadness that lasts a long time. You feel depressed when you do not feel like playing with any of your toys.",
	"despair": "This is a no-hope feeling when you are very sad. You feel despair when you think things might not get better.",
	"down": "This is a small, droopy-shoulder sadness. You feel down when you miss out on a turn to go first.",
	"gloomy": "This is a dark, cloudy feeling in your head. You feel gloomy when everything feels a little bit gray and sad.",
	"grief": "This is a very sad heart-feeling when you lose something special. You feel grief when a favorite balloon pops or a pet goes away.",
	"heartbroken": "This is a very deep sadness that feels like your heart is hurting. You feel heartbroken when a very best friend moves away.",
	"lonely": "This is a sad feeling when you want someone to be with you. You feel lonely when there is no one to play with on the playground.",
	"melancholy": "This is a soft, thoughtful sadness. You feel melancholy when you are thinking about something you miss.",
	"misery": "This is a very deep, heavy sadness. You feel misery when you are hurt or having a really, really bad day.",
	"sad": "This is an unhappy feeling that might make you want to cry. You feel sad when you drop your ice cream on the ground.",
	"sorrow": "This is a big, heavy sadness in your heart. You feel sorrowful when someone you love is feeling very hurt.",
	"sorrowful": "This is a big, heavy sadness in your heart. You feel sorrowful when someone you love is feeling very hurt.",
	"unhappy": "This is a not-good feeling when things are not going well. You feel unhappy when you have to go inside before you are finished playing.",
	"upset": "This is a mixed-up feeling of being sad and a little bit mad. You feel upset when your block tower gets knocked over.",
	"angry": "This is a mad feeling you get when something feels unfair. You feel angry when a toy you are using is taken away.",
	"annoy": "This is a please-stop feeling when something is bothering you. You feel annoyed when a loud noise keeps waking you up.",
	"annoyed": "This is a please-stop feeling when something is bothering you. You feel annoyed when a loud noise keeps waking you up.",
	"fuming": "This is being so mad that you feel hot like a little teakettle. You are fuming when you have to wait a very long time for something you want.",
	"furious": "This is being very, very mad. You feel furious when someone breaks something that belongs to you on purpose.",
	"grumpy": "This is a small, cross feeling when you do not want to smile. You might feel grumpy when you have to stop playing and take a nap.",
	"irritated": "This is a scratchy, itchy-mad feeling. You feel irritated when your shirt tag is poking you and will not stop.",
	"mad": "This is a grumpy, cross feeling. You feel mad when you are told no and you really wanted to say yes.",
	"outrage": "This is being super mad because you see something that is totally wrong. You feel outrage when you see someone being mean to a friend.",
	"rage": "This is a giant, exploding mad feeling that is bigger than being angry. You feel rage when you want to stomp your feet and growl.",
	"wrath": "This is a very strong, powerful mad feeling. You feel wrath when you are so mad that you want to shout very loudly.",
	"afraid": "This is a shaky feeling when you think something might hurt you. You feel afraid of the dark when you cannot see what is there.",
	"anxious": "This is a what-if feeling that makes your tummy feel tight. You feel anxious when you are trying something new for the first time.",
	"fear": "This is a scared feeling you get when you are in danger. You feel fear when you hear a very loud, scary boom of thunder.",
	"fright": "This is a quick, surprised-scared feeling. You feel frightened when a little bug suddenly jumps toward you.",
	"frightened": "This is a quick, surprised-scared feeling. You feel frightened when a little bug suddenly jumps toward you.",
	"nervous": "This is a wiggly, worried feeling. You feel nervous when you have to stand up and talk in front of a group.",
	"panic": "This is a very fast, help-me scared feeling. You feel panic when you cannot find your grown-up in the store for a second.",
	"scared": "This is a frightened feeling that makes you want to hide. You feel scared when you see a big, barking dog coming near you.",
	"spooked": "This is a jumpy feeling when something surprises you. You feel spooked when a door slams shut all by itself.",
	"terrified": "This is the biggest scared feeling you can have. You feel terrified when you see something that looks very, very dangerous.",
	"terror": "This is the biggest scared feeling you can have. You feel terrified when you see something that looks very, very dangerous.",
	"worried": "This is a busy-thinking feeling about something bad happening. You feel worried when you think you might have lost your favorite teddy bear.",
	"disgust": "This is a no-thank-you feeling for something gross. You feel disgusted when you see a pile of sticky, smelly trash.",
	"disgusted": "This is a no-thank-you feeling for something gross. You feel disgusted when you see a pile of sticky, smelly trash.",
	"distaste": "This is a yucky feeling you get when you see something you do not like. You might show distaste when you see a vegetable you think tastes icky.",
	"eww": "This is a yuck feeling that makes you go bleah. You say eww when you accidentally step in something wet and squishy.",
	"gross": "This is a yuck feeling that makes you go bleah. You say eww when you accidentally step in something wet and squishy.",
	"grossed": "This is a yuck feeling that makes you go bleah. You say eww when you accidentally step in something wet and squishy.",
	"icky": "This is a feeling that something is dirty or bad to touch. You feel yucky when your hands get covered in sticky mud.",
	"yucky": "This is a feeling that something is dirty or bad to touch. You feel yucky when your hands get covered in sticky mud.",
	"nasty": "This is a very bad, gross feeling. You feel nasty when you smell milk that has been sitting out too long.",
	"nausea": "This is a tummy-ache feeling when something makes you feel like you might throw up. You feel nausea when you smell something really, really stinky.",
	"sickened": "This is a tummy-ache feeling when something makes you feel like you might throw up. You feel nausea when you smell something really, really stinky.",
}

@onready var book_panel: TextureRect = $TextureRect
@onready var level_background: TextureRect = $Background
@onready var level_dim: ColorRect = $BackgroundDim
@onready var coin_counter: Label = get_node_or_null("CoinsContainer/CoinCounter") as Label
var next_bg: CanvasItem = null
var previous_bg: CanvasItem = null
var next_button: Button = null
var previous_button: Button = null
var exit_button: BaseButton = null
var page_slots: Array[Control] = []

var _entries: Array[Dictionary] = []
var _page_index: int = 0
var _word_color: Color = Color(1, 1, 1, 1)
var _slot_word_positions: Array[Vector2] = []
var _slot_cue_positions: Array[Vector2] = []
var _is_animating: bool = false
var _ready_to_close: bool = false
var _unlock_dialog: Control = null
var _pending_unlock_key: String = ""
var _pending_unlock_slot_index: int = -1
var _locks_enabled: bool = false
var _notice_label: Label = null
var _hint_mode: String = ""
var _pending_entry_is_emotion: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if AudioManager != null:
		AudioManager.play_sfx("hint_open")
	if level_dim != null:
		level_dim.color = Color(0, 0, 0, 0.52)
	_resolve_navigation_nodes()
	_resolve_exit_button()
	_collect_page_slots()
	_capture_base_positions()
	_connect_buttons()
	_connect_lock_buttons()
	_ensure_notice_label()
	_update_coin_counter()
	if _entries.is_empty():
		_entries = _default_entries_for_mode()
	_refresh_page(true)
	_play_open_animation()
	_locks_enabled = true
	_ready_to_close = true

func configure(entries: Array[Dictionary], word_color: Color, use_emotion_defaults: bool = false) -> void:
	_entries = entries.duplicate(true)
	_word_color = word_color
	_hint_mode = "emotion" if use_emotion_defaults else "word"
	if _entries.is_empty() and use_emotion_defaults:
		_entries = EMOTION_HINT_ENTRIES.duplicate(true)
	if is_node_ready():
		_page_index = 0
		_refresh_page(true)

func set_emotion_entries(entries: Array[Dictionary], word_color: Color) -> void:
	_entries = entries.duplicate(true)
	_word_color = word_color
	_hint_mode = "emotion"
	if is_node_ready():
		_page_index = 0
		_refresh_page(true)

func set_hint_mode(mode_value: String) -> void:
	_hint_mode = mode_value.strip_edges().to_lower()

func set_background_texture(tex: Texture2D) -> void:
	if level_background != null:
		level_background.texture = tex

func _collect_page_slots() -> void:
	page_slots.clear()
	if book_panel == null:
		return
	# Prefer explicit slot names first so content always maps to fixed UI positions.
	var preferred_slot_names: Array[String] = ["Word1", "Word2", "Word3", "Word4", "Word5", "Word6"]
	var discovered: Array[Control] = []
	for slot_name in preferred_slot_names:
		var preferred: Control = book_panel.get_node_or_null(slot_name) as Control
		if preferred != null:
			discovered.append(preferred)

	# Fallback for non-sequential legacy slot names in older scene revisions.
	if discovered.size() < PAGE_SIZE:
		var extras: Array[Control] = []
		for child in book_panel.get_children():
			if child is Label and (String(child.name).begins_with("Word") or String(child.name).begins_with("Emoticon")) and not discovered.has(child):
				extras.append(child)
		extras.sort_custom(func(a: Control, b: Control) -> bool:
			return _word_slot_index(String(a.name)) < _word_slot_index(String(b.name))
		)
		for extra in extras:
			if discovered.size() >= PAGE_SIZE:
				break
			discovered.append(extra)

	for slot in discovered:
		if page_slots.size() >= PAGE_SIZE:
			break
		page_slots.append(slot)

func _word_slot_index(name_text: String) -> int:
	var digits: String = ""
	for i in range(name_text.length()):
		var ch: String = name_text.substr(i, 1)
		if ch >= "0" and ch <= "9":
			digits += ch
	if digits.is_empty():
		return 999
	return int(digits)

func _emotion_visual_for_slot(slot: Control) -> TextureRect:
	if slot == null:
		return null
	var direct: TextureRect = slot.get_node_or_null("Emoticon") as TextureRect
	if direct != null:
		return direct
	for child in slot.get_children():
		if child is TextureRect and String(child.name).to_lower().find("emoticon") != -1:
			return child as TextureRect
	return null

func _cue_node_for_slot(slot: Control) -> Label:
	if slot == null:
		return null
	var direct: Label = slot.get_node_or_null("CueLabel") as Label
	if direct != null:
		return direct
	direct = slot.get_node_or_null("Definition") as Label
	if direct != null:
		return direct
	for child in slot.get_children():
		if child is Label and (String(child.name).begins_with("CueLabel") or String(child.name).begins_with("Definition")):
			return child as Label
	return null

func _lock_button_for_slot(slot: Control) -> BaseButton:
	if slot == null:
		return null
	var direct: BaseButton = slot.get_node_or_null("LockButton") as BaseButton
	if direct != null:
		return direct
	for child in slot.get_children():
		if child is BaseButton and String(child.name).begins_with("Lock"):
			return child as BaseButton
	return null

func _capture_base_positions() -> void:
	_slot_word_positions.clear()
	_slot_cue_positions.clear()
	for slot in page_slots:
		var word_label: Label = slot as Label
		var cue_label: Label = _cue_node_for_slot(slot)
		_slot_word_positions.append(word_label.position)
		_slot_cue_positions.append(cue_label.position if cue_label != null else Vector2.ZERO)

func _connect_buttons() -> void:
	if next_button and not next_button.pressed.is_connected(_on_next_pressed):
		next_button.pressed.connect(_on_next_pressed)
	if previous_button and not previous_button.pressed.is_connected(_on_previous_pressed):
		previous_button.pressed.connect(_on_previous_pressed)
	if exit_button and not exit_button.pressed.is_connected(_on_exit_pressed):
		exit_button.pressed.connect(_on_exit_pressed)

func _connect_lock_buttons() -> void:
	for i in range(page_slots.size()):
		var slot: Control = page_slots[i]
		var lock_button: BaseButton = _lock_button_for_slot(slot)
		if lock_button == null:
			continue
		var callable: Callable = Callable(self, "_on_lock_pressed").bind(i)
		if not lock_button.pressed.is_connected(callable):
			lock_button.pressed.connect(callable)

func _resolve_navigation_nodes() -> void:
	next_bg = _find_first_canvas_item_by_paths([
		"BackBg",
		"NextBg",
		"nextbg",
		"NextBG",
		"NextBackground"
	])
	previous_bg = _find_first_canvas_item_by_paths([
		"BackBg2",
		"Previous",
		"PreviousBg",
		"previousbg",
		"PreviousBG",
		"PreviousBackground"
	])

	next_button = _find_first_button_by_paths([
		"BackBg/Back",
		"NextBg/Back",
		"nextbg/Back",
		"BackBg/Next",
		"NextBg/Next",
		"nextbg/Next",
		"Next",
		"NextButton",
		"next"
	])
	previous_button = _find_first_button_by_paths([
		"BackBg2/Back",
		"Previous/Previous",
		"Previous/Back",
		"PreviousBg/Back",
		"previousbg/Back",
		"BackBg2/Previous",
		"PreviousBg/Previous",
		"previousbg/Previous",
		"Previous",
		"PreviousButton",
		"previous"
	])

func _resolve_exit_button() -> void:
	exit_button = _find_first_base_button_by_paths([
		"Exit",
		"ExitButton",
		"Close",
		"CloseButton",
		"TextureRect/Exit",
		"TextureRect/ExitButton",
		"TextureRect/Close",
		"TextureRect/CloseButton"
	])

func _find_first_canvas_item_by_paths(paths: Array[String]) -> CanvasItem:
	for node_path in paths:
		var candidate: CanvasItem = get_node_or_null(node_path) as CanvasItem
		if candidate != null:
			return candidate
	return null

func _find_first_button_by_paths(paths: Array[String]) -> Button:
	for node_path in paths:
		var candidate: Button = get_node_or_null(node_path) as Button
		if candidate != null:
			return candidate
	return null

func _find_first_base_button_by_paths(paths: Array[String]) -> BaseButton:
	for node_path in paths:
		var candidate: BaseButton = get_node_or_null(node_path) as BaseButton
		if candidate != null:
			return candidate
	return null

func _default_entries_for_mode() -> Array[Dictionary]:
	if GameState.current_mode == "word":
		var empty_entries: Array[Dictionary] = []
		return empty_entries
	var emotion_entries: Array[Dictionary] = []
	for entry in EMOTION_HINT_ENTRIES:
		emotion_entries.append(entry)
	return emotion_entries

func set_word_entries(words: Array[String], word_color: Color) -> void:
	_entries.clear()
	_word_color = word_color
	_hint_mode = "word"
	for word in words:
		var clean_word: String = word.strip_edges()
		if clean_word.is_empty():
			continue
		_entries.append({"word": clean_word, "definition": _definition_for_word(clean_word)})
	if is_node_ready():
		_page_index = 0
		_refresh_page(true)

func _definition_for_word(word: String) -> String:
	var key: String = _normalize_word_key(word)
	if WORD_DEFINITIONS.has(key):
		return String(WORD_DEFINITIONS[key])
	return "This word helps describe a feeling or state."

func _normalize_word_key(word: String) -> String:
	var lowered: String = word.strip_edges().to_lower()
	var cleaned: String = ""
	for i in range(lowered.length()):
		var ch: String = lowered.substr(i, 1)
		var is_letter: bool = ch >= "a" and ch <= "z"
		if is_letter:
			cleaned += ch
	return cleaned

func _page_count() -> int:
	if _entries.is_empty():
		return 1
	return int(ceili(float(_entries.size()) / float(PAGE_SIZE)))

func _current_page_entries() -> Array[Dictionary]:
	var start_index: int = _page_index * PAGE_SIZE
	var end_index: int = mini(start_index + PAGE_SIZE, _entries.size())
	var page: Array[Dictionary] = []
	if start_index >= _entries.size():
		return page
	for i in range(start_index, end_index):
		page.append(_entries[i])
	return page

func _refresh_page(initial: bool = false) -> void:
	if page_slots.is_empty():
		return
	var page_entries: Array[Dictionary] = _current_page_entries()
	for i in range(page_slots.size()):
		var slot: Control = page_slots[i]
		var word_label: Label = slot as Label
		var cue_label: Label = _cue_node_for_slot(slot)
		var lock_button: BaseButton = _lock_button_for_slot(slot)
		var emotion_visual: TextureRect = _emotion_visual_for_slot(slot)
		var has_entry: bool = i < page_entries.size()
		word_label.visible = has_entry
		if cue_label != null:
			cue_label.visible = false
		if emotion_visual != null:
			emotion_visual.visible = false
		if lock_button != null:
			lock_button.visible = false
		if not has_entry:
			continue
		var entry: Dictionary = page_entries[i]
		var word_text: String = String(entry.get("word", ""))
		var definition_text: String = String(entry.get("definition", ""))
		var key: String = String(entry.get("key", _normalize_word_key(word_text))).strip_edges().to_lower()
		var is_unlocked: bool = GameState.is_hint_word_unlocked(key)
		word_label.text = word_text.to_upper() if _resolved_mode() == "word" else word_text
		word_label.add_theme_color_override("font_color", _word_color)
		if emotion_visual != null:
			var tex: Texture2D = entry.get("texture") as Texture2D
			if tex != null:
				emotion_visual.texture = tex
			emotion_visual.visible = is_unlocked
		if cue_label != null:
			cue_label.text = definition_text
			cue_label.visible = is_unlocked and definition_text != ""
		if lock_button != null:
			lock_button.visible = not is_unlocked

	_update_nav_buttons()
	_update_coin_counter()
	if not initial:
		_pulse_visible_entries()

func _update_coin_counter() -> void:
	if coin_counter != null:
		coin_counter.text = str(GameState.coins)

func _ensure_notice_label() -> void:
	if _notice_label != null:
		return
	_notice_label = Label.new()
	_notice_label.name = "NoticeLabel"
	_notice_label.anchor_left = 0.2
	_notice_label.anchor_top = 0.88
	_notice_label.anchor_right = 0.8
	_notice_label.anchor_bottom = 0.95
	_notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notice_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_notice_label.modulate.a = 0.0
	_notice_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.25, 1.0))
	_notice_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_notice_label.add_theme_constant_override("outline_size", 6)
	_notice_label.add_theme_font_override("font", load("res://assets/fonts/Fredoka/static/Fredoka_Condensed-Bold.ttf") as FontFile)
	_notice_label.add_theme_font_size_override("font_size", 26)
	add_child(_notice_label)

func _show_notice(message: String) -> void:
	_ensure_notice_label()
	if _notice_label == null:
		return
	_notice_label.text = message
	_notice_label.modulate.a = 1.0
	var tween: Tween = create_tween().bind_node(_notice_label)
	tween.tween_interval(1.4)
	tween.tween_property(_notice_label, "modulate:a", 0.0, 0.2)

func _on_lock_pressed(slot_index: int) -> void:
	if not _locks_enabled:
		return
	if _unlock_dialog != null:
		return
	var page_entries: Array[Dictionary] = _current_page_entries()
	if slot_index < 0 or slot_index >= page_entries.size():
		return
	var entry: Dictionary = page_entries[slot_index]
	var word_text: String = String(entry.get("word", "")).strip_edges()
	var key: String = String(entry.get("key", _normalize_word_key(word_text))).strip_edges().to_lower()
	var is_emotion_entry: bool = _entry_is_emotion(entry)
	if key.is_empty() or GameState.is_hint_word_unlocked(key):
		return
	_pending_unlock_key = key
	_pending_unlock_slot_index = slot_index
	_pending_entry_is_emotion = is_emotion_entry
	_show_unlock_confirmation(word_text)

func _show_unlock_confirmation(word_text: String) -> void:
	if _unlock_dialog != null:
		return
	var popup: Control = UNLOCK_CONFIRM_SCENE.instantiate() as Control
	popup.process_mode = Node.PROCESS_MODE_ALWAYS
	var unlock_cost: int = _unlock_cost_for_mode()
	var unlock_message: String = "USING A HINT?"
	if GameState.current_mode == "word":
		unlock_message = "UNLOCK %s DEFINITION?" % word_text.to_upper()
	elif GameState.current_mode == "emotion":
		unlock_message = "UNLOCK %s?" % word_text.to_upper()
	if popup.has_method("use_live_scene_background"):
		popup.call("use_live_scene_background", 0.55)
	elif popup.has_method("set_background_texture") and level_background != null:
		popup.call("set_background_texture", level_background.texture)
	if popup.has_method("set_message"):
		popup.call("set_message", unlock_message)
	if popup.has_method("set_cost"):
		popup.call("set_cost", unlock_cost, "coin")
	if popup.has_signal("confirmed"):
		popup.connect("confirmed", Callable(self, "_on_unlock_confirmed"))
	if popup.has_signal("cancelled"):
		popup.connect("cancelled", Callable(self, "_on_unlock_cancelled"))
	popup.add_to_group("unlock_confirmation_popups")
	add_child(popup)
	_unlock_dialog = popup

func _on_unlock_confirmed() -> void:
	if _pending_unlock_key.is_empty():
		return
	var unlock_cost: int = _unlock_cost_for_mode()
	if GameState.spend_coins(unlock_cost):
		GameState.unlock_hint_word(_pending_unlock_key)
		await _play_unlock_animation(_pending_unlock_slot_index)
		if AudioManager != null:
			AudioManager.play_sfx("correct_choice")
	else:
		_show_notice("NOT ENOUGH COINS TO PAY")
		if AudioManager != null:
			AudioManager.play_sfx("wrong_choice")
	_pending_unlock_key = ""
	_pending_unlock_slot_index = -1
	_pending_entry_is_emotion = false
	_unlock_dialog = null
	_refresh_page(true)

func _unlock_cost_for_mode() -> int:
	if _resolved_mode() == "emotion":
		return UNLOCK_EMOTION_COST
	return UNLOCK_WORD_COST

func _entry_is_emotion(entry: Dictionary) -> bool:
	if entry.has("texture"):
		var tex: Variant = entry.get("texture", null)
		if tex is Texture2D:
			return true
	var key: String = String(entry.get("key", "")).to_lower()
	if key.begins_with("emotion_"):
		return true
	return false

func _resolved_mode() -> String:
	if not _hint_mode.is_empty():
		return _hint_mode
	if GameState != null:
		return String(GameState.current_mode).to_lower()
	return ""

func _on_unlock_cancelled() -> void:
	_pending_unlock_key = ""
	_pending_unlock_slot_index = -1
	_unlock_dialog = null

func _play_unlock_animation(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= page_slots.size():
		return
	var slot: Control = page_slots[slot_index]
	if slot == null or not slot.visible:
		return
	var word_label: Label = slot as Label
	var cue_label: Label = _cue_node_for_slot(slot)
	var emotion_visual: TextureRect = _emotion_visual_for_slot(slot)
	var lock_button: BaseButton = _lock_button_for_slot(slot)
	if cue_label != null:
		cue_label.visible = true
		cue_label.modulate.a = 0.0
		cue_label.position = _slot_cue_positions[slot_index] + Vector2(0, 16)
	if emotion_visual != null:
		emotion_visual.visible = true
		emotion_visual.modulate.a = 0.0
		emotion_visual.scale = Vector2(0.92, 0.92)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	if word_label != null:
		word_label.scale = Vector2.ONE
		tween.tween_property(word_label, "scale", Vector2(1.08, 1.08), 0.14)
		tween.tween_property(word_label, "scale", Vector2.ONE, 0.12)
	if lock_button != null:
		tween.parallel().tween_property(lock_button, "modulate:a", 0.0, 0.18)
		tween.parallel().tween_property(lock_button, "scale", Vector2(0.7, 0.7), 0.18)
	if cue_label != null:
		tween.parallel().tween_property(cue_label, "modulate:a", 1.0, 0.2)
		tween.parallel().tween_property(cue_label, "position", _slot_cue_positions[slot_index], 0.2)
	if emotion_visual != null:
		tween.parallel().tween_property(emotion_visual, "modulate:a", 1.0, 0.2)
		tween.parallel().tween_property(emotion_visual, "scale", Vector2.ONE, 0.2)
	await tween.finished
	if lock_button != null:
		lock_button.visible = false
 

func _update_nav_buttons() -> void:
	var page_count: int = _page_count()
	var needs_paging: bool = page_count > 1
	if next_bg != null:
		next_bg.visible = needs_paging and _page_index < page_count - 1
	if previous_bg != null:
		previous_bg.visible = needs_paging and _page_index > 0
	if next_button != null:
		next_button.visible = needs_paging and _page_index < page_count - 1
	if previous_button != null:
		previous_button.visible = needs_paging and _page_index > 0

func _pulse_visible_entries() -> void:
	if _is_animating:
		return
	_is_animating = true
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	for i in range(page_slots.size()):
		var slot: Control = page_slots[i]
		if not slot.visible:
			continue
		var word_label: Label = slot as Label
		var cue_label: Label = _cue_node_for_slot(slot)
		word_label.scale = Vector2(0.92, 0.92)
		tween.tween_property(word_label, "scale", Vector2.ONE, 0.22)
		if cue_label != null:
			cue_label.scale = Vector2(0.94, 0.94)
			tween.parallel().tween_property(cue_label, "scale", Vector2.ONE, 0.22)
	await tween.finished
	_is_animating = false

func _play_open_animation() -> void:
	if book_panel == null:
		return
	book_panel.pivot_offset = book_panel.size * 0.5
	book_panel.scale = Vector2(0.05, 1.0)
	book_panel.rotation = deg_to_rad(-8.0)
	book_panel.modulate.a = 0.0
	var open_tween: Tween = create_tween()
	open_tween.set_parallel(true)
	open_tween.set_trans(Tween.TRANS_BACK)
	open_tween.set_ease(Tween.EASE_OUT)
	open_tween.tween_property(book_panel, "scale", Vector2.ONE, 0.42)
	open_tween.tween_property(book_panel, "rotation", 0.0, 0.42)
	open_tween.tween_property(book_panel, "modulate:a", 1.0, 0.18)

func _animate_page_turn(direction: int) -> void:
	if _is_animating:
		return
	_is_animating = true
	var out_tween: Tween = create_tween()
	out_tween.set_parallel(true)
	out_tween.set_trans(Tween.TRANS_QUAD)
	out_tween.set_ease(Tween.EASE_IN)
	for i in range(page_slots.size()):
		var slot: Control = page_slots[i]
		if not slot.visible:
			continue
		var word_label: Label = slot as Label
		var cue_label: Label = _cue_node_for_slot(slot)
		word_label.modulate.a = 1.0
		out_tween.tween_property(word_label, "modulate:a", 0.0, 0.12)
		out_tween.parallel().tween_property(word_label, "position:x", _slot_word_positions[i].x + (direction * 36.0), 0.12)
		if cue_label != null:
			cue_label.modulate.a = 1.0
			out_tween.parallel().tween_property(cue_label, "modulate:a", 0.0, 0.12)
			out_tween.parallel().tween_property(cue_label, "position:x", _slot_cue_positions[i].x + (direction * 36.0), 0.12)
	await out_tween.finished
	_page_index = clampi(_page_index + direction, 0, _page_count() - 1)
	_refresh_page(true)
	for i in range(page_slots.size()):
		var slot: Control = page_slots[i]
		var word_label: Label = slot as Label
		var cue_label: Label = _cue_node_for_slot(slot)
		word_label.position = _slot_word_positions[i] - Vector2(direction * 36.0, 0.0)
		word_label.modulate.a = 0.0
		if cue_label != null:
			cue_label.position = _slot_cue_positions[i] - Vector2(direction * 36.0, 0.0)
			cue_label.modulate.a = 0.0
	var in_tween: Tween = create_tween()
	in_tween.set_parallel(true)
	in_tween.set_trans(Tween.TRANS_BACK)
	in_tween.set_ease(Tween.EASE_OUT)
	for i in range(page_slots.size()):
		var slot: Control = page_slots[i]
		if not slot.visible:
			continue
		var word_label: Label = slot as Label
		var cue_label: Label = _cue_node_for_slot(slot)
		in_tween.tween_property(word_label, "position:x", _slot_word_positions[i].x, 0.22)
		in_tween.parallel().tween_property(word_label, "modulate:a", 1.0, 0.18)
		if cue_label != null:
			in_tween.parallel().tween_property(cue_label, "position:x", _slot_cue_positions[i].x, 0.22)
			in_tween.parallel().tween_property(cue_label, "modulate:a", 1.0, 0.18)
	await in_tween.finished
	_is_animating = false

func _on_next_pressed() -> void:
	if _page_index < _page_count() - 1:
		_animate_page_turn(1)

func _on_previous_pressed() -> void:
	if _page_index > 0:
		_animate_page_turn(-1)

func _on_exit_pressed() -> void:
	_request_close()

func _gui_input(event: InputEvent) -> void:
	if not _ready_to_close:
		return
	if _unlock_dialog != null:
		return
	if _is_tap(event):
		var local_pos: Vector2 = Vector2.ZERO
		if event is InputEventMouseButton:
			local_pos = (event as InputEventMouseButton).position
		elif event is InputEventScreenTouch:
			local_pos = (event as InputEventScreenTouch).position
		if book_panel != null and book_panel.get_global_rect().has_point(local_pos):
			return
		_request_close()
		accept_event()

func _input(event: InputEvent) -> void:
	if not _ready_to_close:
		return
	if _unlock_dialog != null:
		return
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE:
			_request_close()
			get_viewport().set_input_as_handled()
			return
	if _is_tap(event):
		var tap_pos: Vector2 = Vector2.ZERO
		if event is InputEventMouseButton:
			tap_pos = (event as InputEventMouseButton).position
		elif event is InputEventScreenTouch:
			tap_pos = (event as InputEventScreenTouch).position
		if book_panel != null and book_panel.get_global_rect().has_point(tap_pos):
			return
		_request_close()
		get_viewport().set_input_as_handled()

func _request_close() -> void:
	if not _ready_to_close:
		return
	if _unlock_dialog != null:
		return
	if AudioManager != null:
		AudioManager.play_sfx("hint_close")
	close_requested.emit()

func _is_tap(event: InputEvent) -> bool:
	return (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventScreenTouch and event.pressed)

func _play_close_animation() -> void:
	if book_panel == null:
		return
	if _is_animating:
		return
	_is_animating = true
	book_panel.pivot_offset = book_panel.size * 0.5
	var close_tween: Tween = create_tween()
	close_tween.set_parallel(true)
	close_tween.set_trans(Tween.TRANS_QUAD)
	close_tween.set_ease(Tween.EASE_IN)
	close_tween.tween_property(book_panel, "scale", Vector2(0.05, 1.0), 0.26)
	close_tween.tween_property(book_panel, "rotation", deg_to_rad(8.0), 0.26)
	close_tween.tween_property(book_panel, "modulate:a", 0.0, 0.22)
	await close_tween.finished
	_is_animating = false
