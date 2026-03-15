# res://scripts/GameState.gd
extends Node

var selected_character : String = ""
var current_level : int = 1
var current_mode : String = "emotion"  # "emotion" or "word"
var unlocked_levels : Array = [1]  # Start with level 1 unlocked

func unlock_level(level: int):
	if level not in unlocked_levels:
		unlocked_levels.append(level)
		unlocked_levels.sort()
		print("Level ", level, " unlocked!")

func is_level_unlocked(level: int) -> bool:
	return level in unlocked_levels
