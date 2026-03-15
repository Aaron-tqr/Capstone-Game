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
	# Handle emotion drop first
	if item and "emotion_name" in item:
		var emotion_name = item.emotion_name
		var correct_emotion: bool = (emotion_name == accepts_emotion)
		last_dropped_emotion = item
		emit_signal("emotion_dropped", correct_emotion)
		modulate = Color.GREEN if correct_emotion else Color.RED
		return

	# Handle word drop
	if item and "word" in item:
		var word = item.word
		var correct_word: bool = (word in correct_words)
		last_dropped_word = item
		emit_signal("word_dropped", correct_word)
		modulate = Color.GREEN if correct_word else Color.RED
		return

	# Unsupported drop
	last_dropped_emotion = null
	last_dropped_word = null
	emit_signal("word_dropped", false)
	modulate = Color.RED
