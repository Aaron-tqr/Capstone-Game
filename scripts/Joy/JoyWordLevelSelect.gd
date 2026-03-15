extends Control

@onready var button_level1 = $ButtonLevel1
@onready var button_level2 = $ButtonLevel2
@onready var button_level3 = $ButtonLevel3
@onready var button_level4 = $ButtonLevel4
@onready var button_level5 = $ButtonLevel5
@onready var back_button   = $"Back"

func _ready():
	# Animate buttons in
	var level_buttons = [button_level1, button_level2, button_level3, button_level4, button_level5]
	
	for i in range(level_buttons.size()):
		var btn = level_buttons[i]
		var level_num = i + 1
		btn.scale = Vector2(0.9, 0.9)
		btn.modulate.a = 0
		
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_BOUNCE)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(btn, "scale", Vector2(1, 1), 0.5)
		tween.tween_property(btn, "modulate:a", 1.0, 0.5)
		
		# Check if level is unlocked
		if GameState.is_level_unlocked(level_num):
			btn.disabled = false
			btn.modulate = Color.WHITE
			btn.pressed.connect(func(): _on_level_pressed(level_num))
		else:
			btn.disabled = true
			btn.modulate = Color(0.5, 0.5, 0.5)
	
	# Back button
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

func _on_level_pressed(level: int):
	GameState.current_level = level
	print("🌟 WORD LEVEL ", level, " SELECTED → Loading word scene")
	var character_name = GameState.selected_character.capitalize()
	# For Joy scenes are WordJoy1..5, for others WordSad1..5, WordAnger1..5, etc.
	var prefix = "Word%s" % character_name
	var scene_path = "res://scenes/Word Matching/%s/%s%d.tscn" % [character_name, prefix, level]
	print("Loading: ", scene_path)
	get_tree().change_scene_to_file(scene_path)

func _on_back_pressed():
	print("⬅️ Back to Word Character Select")
	get_tree().change_scene_to_file("res://scenes/WordCharacterSelect.tscn")
