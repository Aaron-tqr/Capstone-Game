extends TextureRect
class_name DropTargetWord

@export var correct_words: PackedStringArray = []
signal word_dropped(is_correct: bool)
const DEBUG_LOGS: bool = false

var last_dropped_word = null

func _ready():
	add_to_group("word_drop_targets")

func is_inside_drop_area(point: Vector2) -> bool:
	var rect = get_global_rect()
	var inside = rect.has_point(point)
	if DEBUG_LOGS:
		print("DropTargetWord.is_inside_drop_area: point=", point, "rect=", rect, "inside=", inside)
	return inside

func receive_drop(word_button):
	if GameState != null and GameState.has_method("is_round_input_locked") and bool(GameState.call("is_round_input_locked")):
		return
	var word = ""
	if word_button:
		word = word_button.word
	var correct: bool = (word in correct_words)
	last_dropped_word = word_button
	if DEBUG_LOGS:
		print("Drop target received: '", word, "' | Correct words: ", correct_words, " | Is correct: ", correct)
	if AudioManager != null:
		AudioManager.play_sfx("correct_choice" if correct else "wrong_choice")
	emit_signal("word_dropped", correct)
	if correct:
		modulate = Color.GREEN
	else:
		modulate = Color.RED
