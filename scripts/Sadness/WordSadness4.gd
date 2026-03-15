extends Control

@onready var drop_target = null
@onready var hearts = [$UI/HeartsContainer/Heart1, $UI/HeartsContainer/Heart2, $UI/HeartsContainer/Heart3]
@onready var pause_button = $UI/PauseButton
@onready var level_label = $UI/LevelLabel
@onready var sad_char = $SadnessChar

var lives = 3
var pause_instance: Node = null
var matching_words = []
var dragged_words = []
var draggable_labels = []

# Correct words for sad level 3
var correct_words = ["blue", "gloomy", "down", "lonely"]

func _ready():
	print("WordSadness4.gd _ready running with node: ", name, " script: ", get_script().resource_path)
	GameState.current_mode = "word"
	# Animate in sad character
	if sad_char:
		sad_char.modulate.a = 0
		create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).tween_property(sad_char, "modulate:a", 1.0, 0.6)
		# Float bob animation
		_create_float_bob(sad_char, 2.5, 10.0)
	
	# Resolve drop target node
	drop_target = _find_drop_target()
	print("WordSadness4 drop_target chosen:", drop_target)
	if drop_target and drop_target.get_script():
		print("drop_target script path:", drop_target.get_script().resource_path)
	if drop_target and (not drop_target.has_method("receive_drop") or not drop_target.has_signal("word_dropped")):
		print("WordSadness4: drop_target missing API; forcing DropTargetWord script")
		drop_target.set_script(preload("res://scripts/DropTargetWord.gd"))
		drop_target.add_to_group("word_drop_targets")

	# Find all word labels and attach dragging component (search recursively)
	print("🔍 Looking for word labels in scene...")
	_collect_word_labels(self, "LEVEL 4")
	
	# Setup drop target
	if not drop_target:
		push_error("WordSadness4: drop_target not found")
		return
	if not drop_target.has_method("receive_drop") or not drop_target.has_signal("word_dropped"):
		drop_target.set_script(preload("res://scripts/DropTargetWord.gd"))
		drop_target.add_to_group("word_drop_targets")
	drop_target.set("correct_words", correct_words)

	if not drop_target.has_signal("word_dropped"):
		push_error("WordSadness4: drop_target does not have word_dropped signal (found: %s)" % drop_target.get_script())
		return
	drop_target.word_dropped.connect(_on_word_dropped)
	pause_button.pressed.connect(_on_pause_pressed)
	level_label.text = "LEVEL %d" % GameState.current_level
	print("📝 WordSadness4 READY! Draggable labels: ", draggable_labels.size(), " | Matching words: ", matching_words.size())

func _find_drop_target():
	var names = ["DropTargetWord", "DropTargetCharacter"]
	for name in names:
		var candidate = get_node_or_null(name)
		if candidate:
			return candidate
		candidate = find_child(name, true, false)
		if candidate:
			return candidate
	for child in get_children():
		if child.name in names:
			return child
	for node in get_tree().get_nodes_in_group("word_drop_targets"):
		if node:
			return node
	return null

func _collect_word_labels(node: Node, level_text: String):
	for child in node.get_children():
		if child is Label and child.text != level_text:
			var word = child.text.to_lower()
			print("  ✓ Found word label: ", child.name, " text=", child.text)
			var draggable = DraggableLabel.new(child, word)
			draggable_labels.append(draggable)
			
			if word in correct_words:
				matching_words.append(draggable)
				print("    ✓ Marked as matching word!")
		_collect_word_labels(child, level_text)

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

func _process(_delta):
	# Update draggable labels
	for draggable in draggable_labels:
		draggable.process()

func _on_word_dropped(is_correct: bool):
	if is_correct:
		var dropped_word = drop_target.last_dropped_word
		if dropped_word and dropped_word in matching_words and dropped_word not in dragged_words:
			_hide_word(dropped_word)
			dragged_words.append(dropped_word)
			print("Correct word matched! ", dragged_words.size(), "/", matching_words.size())
			
			if dragged_words.size() >= matching_words.size():
				go_to_result(true)
		else:
			print("Word already used or not in matching list!")
	else:
		lose_life()

func _hide_word(word_label):
	var label_node = word_label.label
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(label_node, "modulate:a", 0.0, 0.3)
	tween.tween_property(label_node, "scale", Vector2(0.5, 0.5), 0.3)
	await tween.finished
	label_node.visible = false

func lose_life():
	lives -= 1
	print("LIVES: ", lives)
	var heart_index = 2 - lives
	if heart_index >= 0 and heart_index < 3:
		create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).tween_property(hearts[heart_index], "modulate:a", 0.3, 0.4)
		create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_IN).tween_property(hearts[heart_index], "scale", Vector2(0.5, 0.5), 0.4)
	if lives <= 0:
		go_to_result(false)

func go_to_result(win: bool):
	ResultData.is_win = win
	ResultData.hearts_remaining = lives
	get_tree().change_scene_to_file("res://scenes/ResultScene.tscn")

func _on_pause_pressed():
	if pause_instance:
		pause_instance.queue_free()
		pause_instance = null
	else:
		pause_instance = preload("res://scenes/PauseScene.tscn").instantiate()
		add_child(pause_instance)
