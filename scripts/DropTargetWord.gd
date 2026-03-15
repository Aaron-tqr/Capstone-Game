extends TextureRect
class_name DropTargetWord

@export var correct_words: PackedStringArray = []
signal word_dropped(is_correct: bool)

var last_dropped_word = null

func _ready():
	add_to_group("word_drop_targets")

func is_inside_drop_area(point: Vector2) -> bool:
	var rect = get_global_rect()
	var inside = rect.has_point(point)
	print("DropTargetWord.is_inside_drop_area: point=", point, "rect=", rect, "inside=", inside)
	return inside

func receive_drop(word_button):
	var word = ""
	if word_button:
		word = word_button.word
	var correct: bool = (word in correct_words)
	last_dropped_word = word_button
	print("Drop target received: '", word, "' | Correct words: ", correct_words, " | Is correct: ", correct)
	emit_signal("word_dropped", correct)
	if correct:
		modulate = Color.GREEN
	else:
		modulate = Color.RED
