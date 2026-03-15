extends Control

func _ready():
	print("📝 Word Level Select for: ", GameState.selected_character)
	
	# Load level 1 by default (you can expand this later)
	_load_level(1)

func _load_level(level: int):
	GameState.current_level = level
	var character_sel = GameState.selected_character.capitalize()
	var scene_path = "res://scenes/Word Matching/%s/Word%s%d.tscn" % [character_sel, character_sel, level]
	print("📝 Loading word scene: ", scene_path)
	get_tree().change_scene_to_file(scene_path)
