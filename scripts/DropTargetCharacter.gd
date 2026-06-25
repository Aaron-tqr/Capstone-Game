extends TextureRect

@export var accepts_emotion: String = ""
@export var correct_words: PackedStringArray = []
signal emotion_dropped(is_correct: bool)
signal word_dropped(is_correct: bool)

var last_dropped_emotion = null
var last_dropped_word = null

func _ready():
	add_to_group("drop_targets")
	# Also act as a word drop target so DraggableLabelComponent can find us
	add_to_group("word_drop_targets")

func is_inside_drop_area(point: Vector2) -> bool:
	var rect := get_global_rect()
	return rect.has_point(point)

func receive_drop(item):
	if GameState != null and GameState.has_method("is_round_input_locked") and bool(GameState.call("is_round_input_locked")):
		return
	# Handle emotion drop first
	if item and "emotion_name" in item:
		var emotion_name: String = _normalize_emotion_key(String(item.emotion_name))
		var accepted_emotion: String = _normalize_emotion_key(String(accepts_emotion))
		var correct_emotion: bool = (emotion_name == accepted_emotion)
		last_dropped_emotion = item
		if AudioManager != null:
			AudioManager.play_sfx("correct_choice" if correct_emotion else "wrong_choice")
		emit_signal("emotion_dropped", correct_emotion)
		modulate = Color.GREEN if correct_emotion else Color.RED
		return

	# Handle word drop
	if item and "word" in item:
		var word = item.word
		var correct_word: bool = (word in correct_words)
		last_dropped_word = item
		if AudioManager != null:
			AudioManager.play_sfx("correct_choice" if correct_word else "wrong_choice")
		emit_signal("word_dropped", correct_word)
		modulate = Color.GREEN if correct_word else Color.RED
		return

	# Unsupported drop
	last_dropped_emotion = null
	last_dropped_word = null
	if AudioManager != null:
		AudioManager.play_sfx("wrong_choice")
	emit_signal("word_dropped", false)
	modulate = Color.RED

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
