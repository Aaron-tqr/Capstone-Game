# res://scripts/LevelData.gd
# Level configuration data
extends Node

# Define levels with number of matching faces needed to win
var levels = {
	1: {"required_matches": 3, "character": "joy"},
	2: {"required_matches": 3, "character": "joy"},
	3: {"required_matches": 4, "character": "joy"},
	4: {"required_matches": 4, "character": "joy"},
	5: {"required_matches": 5, "character": "joy"}
}

func get_required_matches(level: int) -> int:
	if level in levels:
		return levels[level]["required_matches"]
	return 3

func get_level_character(level: int) -> String:
	if level in levels:
		return levels[level]["character"]
	return "joy"
