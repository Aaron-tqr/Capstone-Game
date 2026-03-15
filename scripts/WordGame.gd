extends Control


@onready var drop_target = $Character/DropTargetWord
@onready var hearts = [$UI/HeartsContainer/Heart1, $UI/HeartsContainer/Heart2, $UI/HeartsContainer/Heart3]
@onready var pause_button = $UI/PauseButton
@onready var level_label = $UI/LevelLabel
@onready var word_container = $WordContainer
@onready var character_sprite = $Character  # added to generic scene

var lives = 3
var pause_instance: Node = null
var matching_words = []
var dragged_words = []
var draggable_labels = []

# master word bank per emotion; each entry is a pool of possible words
var word_bank = {
	"joy": ["happy","glad","jolly","cheerful","excited","angry","sad","scared"],
	"sadness": ["sad","depressed","mournful","blue","tearful","happy","angry","scared"],
	"anger": ["furious","mad","irate","irritated","rage","happy","calm","sad"],
	"fear": ["scared","terrified","afraid","nervous","brave","calm","relaxed","angry"],
	"disgust": ["gross","nasty","repulsive","pleasant","nice","clean","happy","sad"]
}

# how many correct words per level (index 0 = level1, …)
var correct_count_by_level = [1,2,3,4,5]

func _ready():
	# determine which character/level we're on
	var char_sel = GameState.selected_character.to_lower() if "selected_character" in GameState else "joy"
	var lvl = GameState.current_level if "current_level" in GameState else 1

	# character sprite setup
	if character_sprite:
		var tex_path = "res://assets/characters/%s%d.png" % [char_sel.capitalize(), lvl]
		if ResourceLoader.exists(tex_path):
			character_sprite.texture = load(tex_path)
		else:
			print("Warning: character texture not found: ", tex_path)

	# pick words for this round
	var pool = word_bank.get(char_sel, word_bank["joy"]).duplicate()
	pool.shuffle()
	var words = []
	for i in range(5):
		words.append(pool[i])

	var correct_count = correct_count_by_level[(lvl - 1) % correct_count_by_level.size()]
	var correct = words.slice(0, correct_count)

	# Clear any existing labels
	for c in word_container.get_children():
		c.queue_free()

	# create draggable labels and mark correct ones
	for i in range(words.size()):
		var w = words[i]
		var lbl = Label.new()
		lbl.text = w.capitalize()
		lbl.name = "Word_%s" % w
		# style copying could be added here (font, size)
		word_container.add_child(lbl)
		var draggable = DraggableLabel.new(lbl, w)
		draggable_labels.append(draggable)
		if w in correct:
			matching_words.append(draggable)

	# Setup drop target with correct list
	if not drop_target:
		push_error("WordGame: drop_target not found")
		return
	drop_target.correct_words = correct
	if not drop_target.has_signal("word_dropped"):
		push_error("WordGame: drop_target does not have word_dropped signal (script=%s)" % drop_target.get_script())
		return
	drop_target.word_dropped.connect(_on_word_dropped)
	pause_button.pressed.connect(_on_pause_pressed)
	level_label.text = "LEVEL %d" % lvl
	print("📝 WordGame READY! char=", char_sel, " level=", lvl, " words=", words, " correct=", correct)
	
	# animate character floating
	if character_sprite:
		_create_float_bob(character_sprite, 2.5, 10.0)

func _on_word_dropped(is_correct: bool):
	if is_correct:
		var dropped_word = drop_target.last_dropped_word
		if dropped_word and dropped_word in matching_words:
			_hide_word(dropped_word)
			dragged_words.append(dropped_word)
			if dragged_words.size() >= matching_words.size():
				go_to_result(true)
	else:
		lose_life()

func _hide_word(word_button):
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(word_button, "modulate:a", 0.0, 0.3)
	tween.tween_property(word_button, "scale", Vector2(0.5, 0.5), 0.3)
	await tween.finished
	word_button.visible = false

func lose_life():
	lives -= 1
	var heart_index = 2 - lives
	if heart_index >= 0 and heart_index < 3:
		hearts[heart_index].modulate = Color.BLACK
	if lives <= 0:
		go_to_result(false)

func go_to_result(win: bool):
	ResultData.is_win = win
	ResultData.hearts_remaining = lives
	var tree = get_tree()
	if tree:
		tree.change_scene_to_file("res://scenes/ResultScene.tscn")

func _on_pause_pressed():
	if pause_instance:
		pause_instance.queue_free()
		pause_instance = null
	else:
		pause_instance = preload("res://scenes/PauseScene.tscn").instantiate()
		add_child(pause_instance)

func _create_float_bob(node: Node, duration: float, amplitude: float) -> void:
	if not is_instance_valid(node):
		return
	var original_y = node.position.y
	var tween = create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "position:y", original_y + amplitude, duration / 2.0)
	tween.tween_property(node, "position:y", original_y - amplitude, duration / 2.0)
