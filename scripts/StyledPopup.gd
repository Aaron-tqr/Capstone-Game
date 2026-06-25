extends Control
class_name StyledPopup

signal confirmed

const PANEL_TEXTURE_PATH: String = "res://assets/UI/BoxesBanners/Box_Orange_Rounded.png"
const BUTTON_TEXTURE_PATH: String = "res://assets/UI/ButtonsText/SVG/PremadeButtons_YesOrange.svg"
const TITLE_FONT_PATH: String = "res://assets/fonts/Molen Friend Demo.otf"
const BODY_FONT_PATH: String = "res://assets/fonts/Fredoka/static/Fredoka_Condensed-SemiBold.ttf"

var _panel: TextureRect = null
var _title_label: Label = null
var _message_label: Label = null
var _ok_button_bg: TextureRect = null
var _ok_button: Button = null
var _pending_title_text: String = ""
var _pending_message_text: String = ""
var _pending_ok_text: String = "OK"
var _pending_accent: Color = Color(1.0, 0.58, 0.18, 1.0)

static func open_popup(parent: Node, title_text: String, message_text: String, ok_text: String = "OK", accent: Color = Color(1.0, 0.58, 0.18, 1.0)) -> StyledPopup:
	var popup: StyledPopup = StyledPopup.new()
	popup.set_content(title_text, message_text, ok_text, accent)
	if parent != null:
		parent.add_child(popup)
	popup.call_deferred("_play_intro_animation")
	return popup

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_apply_content()
	_layout_popup()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_popup()

func _layout_popup() -> void:
	size = get_viewport_rect().size
	var dim: ColorRect = get_node_or_null("Dim") as ColorRect
	if dim != null:
		dim.size = size
	if _panel != null:
		_panel.position = (size - _panel.size) / 2.0

func set_content(title_text: String, message_text: String, ok_text: String = "OK", accent: Color = Color(1.0, 0.58, 0.18, 1.0)) -> void:
	_pending_title_text = title_text
	_pending_message_text = message_text
	_pending_ok_text = ok_text
	_pending_accent = accent
	_apply_content()

func _apply_content() -> void:
	if _title_label != null:
		_title_label.text = _pending_title_text
		_fit_title_label()
	if _message_label != null:
		_message_label.text = _pending_message_text
	if _ok_button != null:
		_ok_button.text = _pending_ok_text
		_ok_button.add_theme_color_override("font_color", _pending_accent)

func _fit_title_label() -> void:
	if _title_label == null:
		return
	_title_label.clip_text = true
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var title_length: int = _pending_title_text.length()
	var title_size: int = 48
	if title_length > 22:
		title_size = 40
	if title_length > 28:
		title_size = 34
	_title_label.add_theme_font_size_override("font_size", title_size)

func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.anchor_right = 1.0
	dim.anchor_bottom = 1.0
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.color = Color(0, 0, 0, 0.52)
	add_child(dim)

	_panel = TextureRect.new()
	_panel.name = "Panel"
	_panel.custom_minimum_size = Vector2(600, 310)
	_panel.size = Vector2(600, 310)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	if ResourceLoader.exists(PANEL_TEXTURE_PATH):
		_panel.texture = load(PANEL_TEXTURE_PATH) as Texture2D
	add_child(_panel)

	_title_label = Label.new()
	_title_label.name = "Title"
	_title_label.anchor_left = 0.10
	_title_label.anchor_top = 0.08
	_title_label.anchor_right = 0.90
	_title_label.anchor_bottom = 0.32
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.clip_text = true
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4, 1.0))
	_title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_title_label.add_theme_constant_override("outline_size", 7)
	_title_label.add_theme_font_size_override("font_size", 48)
	if ResourceLoader.exists(TITLE_FONT_PATH):
		_title_label.add_theme_font_override("font", load(TITLE_FONT_PATH) as FontFile)
	_panel.add_child(_title_label)

	_message_label = Label.new()
	_message_label.name = "Message"
	_message_label.anchor_left = 0.08
	_message_label.anchor_top = 0.32
	_message_label.anchor_right = 0.92
	_message_label.anchor_bottom = 0.70
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_message_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_message_label.add_theme_constant_override("outline_size", 4)
	_message_label.add_theme_font_size_override("font_size", 29)
	if ResourceLoader.exists(BODY_FONT_PATH):
		_message_label.add_theme_font_override("font", load(BODY_FONT_PATH) as FontFile)
	_panel.add_child(_message_label)

	_ok_button_bg = TextureRect.new()
	_ok_button_bg.name = "OkButtonBg"
	_ok_button_bg.anchor_left = 0.5
	_ok_button_bg.anchor_top = 0.73
	_ok_button_bg.anchor_right = 0.5
	_ok_button_bg.anchor_bottom = 0.73
	_ok_button_bg.offset_left = -68
	_ok_button_bg.offset_top = 0
	_ok_button_bg.offset_right = 68
	_ok_button_bg.offset_bottom = 54
	_ok_button_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	if ResourceLoader.exists(BUTTON_TEXTURE_PATH):
		_ok_button_bg.texture = load(BUTTON_TEXTURE_PATH) as Texture2D
	_panel.add_child(_ok_button_bg)

	_ok_button = Button.new()
	_ok_button.name = "OkButton"
	_ok_button.anchor_right = 1.0
	_ok_button.anchor_bottom = 1.0
	_ok_button.flat = true
	_ok_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_ok_button.add_theme_color_override("font_color", Color(1.0, 0.63, 0.28, 1.0))
	_ok_button.add_theme_color_override("font_hover_color", Color(1.0, 0.80, 0.45, 1.0))
	_ok_button.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_ok_button.add_theme_constant_override("outline_size", 7)
	_ok_button.add_theme_font_size_override("font_size", 24)
	if ResourceLoader.exists(TITLE_FONT_PATH):
		_ok_button.add_theme_font_override("font", load(TITLE_FONT_PATH) as FontFile)
	_ok_button_bg.add_child(_ok_button)

	if not _ok_button.pressed.is_connected(_on_ok_pressed):
		_ok_button.pressed.connect(_on_ok_pressed)

func _play_intro_animation() -> void:
	if _panel == null:
		return
	_panel.scale = Vector2(0.82, 0.82)
	_panel.modulate.a = 0.0
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.22)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.2)

func _on_ok_pressed() -> void:
	confirmed.emit()
	queue_free()
