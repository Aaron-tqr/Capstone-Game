# res://scripts/GameState.gd
extends Node

signal coins_changed(new_amount: int)

const STORY_CONTINUE_SAVE_PATH: String = "user://story_continue.cfg"
const EMOTION_CHAIN: Array[String] = ["joy", "sadness", "anger", "disgust", "fear"]

var selected_character : String = ""
var current_level : int = 1
var current_mode : String = "emotion"  # "emotion" or "word"
var current_story_act : int = 1
var coins: int = 0
var settings_return_scene: String = ""
var round_input_locked: bool = false
var unlocked_hint_words := {}
var completed_story_acts := []
var situation_scenario_cursors := {}
var story_retry_scene_path: String = ""
var story_retry_beat_index: int = -1
var story_continue_data: Dictionary = {}
var pending_story_continue_scene_path: String = ""
var story_skip_intro_once_scene_path: String = ""
var modes_unlocked := {
	"story": true,
	"emotion": false,
	"word": false,
}
var pending_unlock_events: Array[Dictionary] = []

# Per-mode, per-character unlocked levels.
# Example:
# {
#   "emotion": { "joy": [1,2], "sadness": [1] },
#   "word":    { "joy": [1],   "sadness": [1,2] }
# }
var unlocked_levels := {
	"emotion": {
		"joy": [1],
		"sadness": [],
		"anger": [],
		"disgust": [],
		"fear": [],
	},
	"word": {
		"joy": [1],
		"sadness": [],
		"anger": [],
		"disgust": [],
		"fear": [],
	},
}

var unlocked_story_acts := [1]

# Store best stars achieved per (mode, character, level)
# Example: best_stars["emotion"]["joy"][1] = 3
var best_stars := {}

func _ready() -> void:
	_load_story_continue_data()
	_apply_progression_baseline()

func _apply_progression_baseline() -> void:
	# Keep only valid acts and ensure Act 1 is always available.
	var filtered_acts: Array = []
	for act in unlocked_story_acts:
		var act_num: int = int(act)
		if act_num >= 1 and act_num <= 3 and act_num not in filtered_acts:
			filtered_acts.append(act_num)
	if 1 not in filtered_acts:
		filtered_acts.append(1)
	filtered_acts.sort()
	unlocked_story_acts = filtered_acts

	# Preserve earned story progress while enforcing minimum mode availability.
	# For the release build: ensure both modes are unlocked and all levels available.
	# This makes every character and level immediately playable for QA / burning to disc.
	modes_unlocked["emotion"] = true
	modes_unlocked["word"] = true
	# Populate unlocked_levels for each mode with levels 1..5 for every emotion.
	for mode_name in ["emotion", "word"]:
		if not unlocked_levels.has(mode_name):
			unlocked_levels[mode_name] = {}
		for emotion_name in EMOTION_CHAIN:
			unlocked_levels[mode_name][emotion_name] = [1,2,3,4,5]

func _get_key(mode: String, character: String) -> Dictionary:
	var m = mode if mode in unlocked_levels else "emotion"
	var c = character.to_lower()
	if c == "":
		c = "joy"
	if c not in unlocked_levels[m]:
		unlocked_levels[m][c] = []
	return {
		"mode": m,
		"char": c,
	}

func set_round_input_locked(locked: bool) -> void:
	round_input_locked = locked

func is_round_input_locked() -> bool:
	return round_input_locked

func get_next_situation_scenario_index(emotion_key: String, scenario_count: int) -> int:
	if scenario_count <= 0:
		return 0
	var key: String = _normalize_emotion_key(emotion_key)
	var cursor: int = int(situation_scenario_cursors.get(key, 0))
	var index: int = posmod(cursor, scenario_count)
	situation_scenario_cursors[key] = posmod(cursor + 1, scenario_count)
	return index

func is_mode_unlocked(mode: String) -> bool:
	return bool(modes_unlocked.get(mode.to_lower(), false))

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

func unlock_mode(mode: String) -> bool:
	var mode_key: String = mode.to_lower()
	if not modes_unlocked.has(mode_key):
		return false
	if bool(modes_unlocked[mode_key]):
		return false
	modes_unlocked[mode_key] = true
	if mode_key in unlocked_levels:
		var joy_levels: Array = unlocked_levels[mode_key].get("joy", [])
		if 1 not in joy_levels:
			joy_levels.append(1)
			joy_levels.sort()
			unlocked_levels[mode_key]["joy"] = joy_levels
	return true

func is_emotion_character_unlocked(character: String, mode: String = "emotion") -> bool:
	var mode_key: String = mode.to_lower()
	if not is_mode_unlocked(mode_key):
		return false
	var key = _get_key(mode_key, character)
	var arr: Array = unlocked_levels[key.mode][key.char]
	return 1 in arr

func unlock_level(level: int):
	var key = _get_key(current_mode, selected_character)
	var arr: Array = unlocked_levels[key.mode][key.char]
	if level not in arr:
		arr.append(level)
		arr.sort()
		unlocked_levels[key.mode][key.char] = arr
		if AudioManager != null:
			AudioManager.play_sfx("level_unlock")
		print("Level ", level, " unlocked for ", key.mode, " / ", key.char)

func is_level_unlocked(level: int) -> bool:
	var key = _get_key(current_mode, selected_character)
	var arr: Array = unlocked_levels[key.mode][key.char]
	return level in arr

func set_level_stars(level: int, stars: int) -> void:
	var key = _get_key(current_mode, selected_character)
	if key.mode not in best_stars:
		best_stars[key.mode] = {}
	if key.char not in best_stars[key.mode]:
		best_stars[key.mode][key.char] = {}
	var prev := 0
	if level in best_stars[key.mode][key.char]:
		prev = best_stars[key.mode][key.char][level]
	if stars > prev:
		best_stars[key.mode][key.char][level] = stars

func get_level_stars(level: int) -> int:
	var key = _get_key(current_mode, selected_character)
	if key.mode in best_stars and key.char in best_stars[key.mode]:
		if level in best_stars[key.mode][key.char]:
			return int(best_stars[key.mode][key.char][level])
	return 0

func unlock_story_act(act_number: int) -> void:
	if act_number < 1:
		return
	if act_number > 3:
		return
	if act_number not in unlocked_story_acts:
		unlocked_story_acts.append(act_number)
		unlocked_story_acts.sort()
		print("Story act ", act_number, " unlocked")

func is_story_act_unlocked(act_number: int) -> bool:
	return act_number in unlocked_story_acts

func complete_story_act(act_number: int) -> void:
	if act_number < 1:
		return
	if act_number not in completed_story_acts:
		completed_story_acts.append(act_number)
		completed_story_acts.sort()
	if act_number >= 2:
		if unlock_mode("emotion"):
			queue_unlock_event(
				"mode",
				"Emotion Matching Unlocked!",
				"You can now play Emotion Matching mode.",
				"emotion"
			)

func is_story_act_completed(act_number: int) -> bool:
	return act_number in completed_story_acts

func set_story_retry_context(scene_path: String, beat_index: int) -> void:
	story_retry_scene_path = scene_path
	story_retry_beat_index = beat_index

func consume_story_retry_beat_index(scene_path: String) -> int:
	if story_retry_scene_path != scene_path:
		return -1
	var out: int = story_retry_beat_index
	story_retry_scene_path = ""
	story_retry_beat_index = -1
	return out

func clear_story_retry_context(scene_path: String = "") -> void:
	if scene_path.is_empty() or story_retry_scene_path == scene_path:
		story_retry_scene_path = ""
		story_retry_beat_index = -1

func set_story_continue_progress(scene_path: String, beat_index: int, frame_path: String) -> void:
	var cleaned_scene_path: String = scene_path.strip_edges()
	if cleaned_scene_path.is_empty():
		return
	story_continue_data[cleaned_scene_path] = {
		"beat_index": maxi(0, beat_index),
		"frame_path": frame_path.strip_edges(),
	}
	_save_story_continue_data()

func get_story_continue_progress(scene_path: String) -> Dictionary:
	var cleaned_scene_path: String = scene_path.strip_edges()
	if cleaned_scene_path.is_empty():
		return {}
	if not story_continue_data.has(cleaned_scene_path):
		return {}
	var data: Dictionary = story_continue_data[cleaned_scene_path]
	return data.duplicate(true)

func has_story_continue_progress(scene_path: String) -> bool:
	var data: Dictionary = get_story_continue_progress(scene_path)
	if data.is_empty():
		return false
	return int(data.get("beat_index", -1)) >= 0

func clear_story_continue_progress(scene_path: String = "") -> void:
	var cleaned_scene_path: String = scene_path.strip_edges()
	if cleaned_scene_path.is_empty():
		if story_continue_data.is_empty():
			return
		story_continue_data.clear()
		_save_story_continue_data()
		return
	if not story_continue_data.has(cleaned_scene_path):
		return
	story_continue_data.erase(cleaned_scene_path)
	_save_story_continue_data()

func set_pending_story_continue_scene(scene_path: String) -> void:
	pending_story_continue_scene_path = scene_path.strip_edges()

func consume_pending_story_continue_scene() -> String:
	var out: String = pending_story_continue_scene_path
	pending_story_continue_scene_path = ""
	return out

func set_story_skip_intro_once(scene_path: String) -> void:
	story_skip_intro_once_scene_path = scene_path.strip_edges()

func consume_story_skip_intro_once(scene_path: String) -> bool:
	var cleaned_scene_path: String = scene_path.strip_edges()
	if cleaned_scene_path.is_empty():
		return false
	if story_skip_intro_once_scene_path != cleaned_scene_path:
		return false
	story_skip_intro_once_scene_path = ""
	return true

func queue_unlock_event(kind: String, title: String, message: String, key: String = "") -> void:
	var dedupe_key: String = "%s:%s" % [kind.strip_edges().to_lower(), key.strip_edges().to_lower()]
	if not dedupe_key.ends_with(":"):
		for event in pending_unlock_events:
			if String(event.get("dedupe", "")) == dedupe_key:
				return
	pending_unlock_events.append({
		"kind": kind,
		"title": title,
		"message": message,
		"dedupe": dedupe_key,
	})

func consume_pending_unlock_events() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for event in pending_unlock_events:
		if event is Dictionary:
			out.append((event as Dictionary).duplicate(true))
	pending_unlock_events.clear()
	return out

func get_completed_level_count(mode: String = "emotion") -> int:
	var mode_key: String = mode.to_lower()
	if not best_stars.has(mode_key):
		return 0
	var count: int = 0
	for char_key in best_stars[mode_key].keys():
		var level_map: Variant = best_stars[mode_key][char_key]
		if level_map is Dictionary:
			for lvl in (level_map as Dictionary).keys():
				if int((level_map as Dictionary).get(lvl, 0)) > 0:
					count += 1
	return count

func process_progression_after_level_clear(mode: String, character: String, level: int) -> void:
	var mode_key: String = mode.to_lower()
	var char_key: String = character.to_lower()
	if mode_key != "emotion":
		return

	if level >= 3:
		var idx: int = EMOTION_CHAIN.find(char_key)
		if idx >= 0 and idx < EMOTION_CHAIN.size() - 1:
			var next_char: String = EMOTION_CHAIN[idx + 1]
			var next_levels: Array = unlocked_levels["emotion"].get(next_char, [])
			if 1 not in next_levels:
				next_levels.append(1)
				next_levels.sort()
				unlocked_levels["emotion"][next_char] = next_levels
				queue_unlock_event(
					"character",
					"%s Unlocked!" % next_char.capitalize(),
					"You unlocked %s in Emotion Matching." % next_char.capitalize(),
					next_char
				)

	if get_completed_level_count("emotion") >= 5:
		if unlock_mode("word"):
			queue_unlock_event(
				"mode",
				"Word Matching Unlocked!",
				"You can now play Word Matching mode.",
				"word"
			)

func _load_story_continue_data() -> void:
	story_continue_data.clear()
	var config: ConfigFile = ConfigFile.new()
	if config.load(STORY_CONTINUE_SAVE_PATH) != OK:
		return
	var loaded_data: Variant = config.get_value("story_continue", "entries", {})
	if loaded_data is Dictionary:
		story_continue_data = (loaded_data as Dictionary).duplicate(true)

func _save_story_continue_data() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("story_continue", "entries", story_continue_data)
	config.save(STORY_CONTINUE_SAVE_PATH)

func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	coins += amount
	emit_signal("coins_changed", coins)
	print("Coins +", amount, " => ", coins)

func spend_coins(amount: int) -> bool:
	var effective_amount: int = amount
	# Defensive guard: emotion-mode hint purchases should never charge less than 2.
	if current_mode == "emotion" and effective_amount == 1:
		effective_amount = 2
	if effective_amount <= 0:
		return true
	if coins < effective_amount:
		return false
	coins -= effective_amount
	emit_signal("coins_changed", coins)
	print("Coins -", effective_amount, " => ", coins)
	return true

func unlock_hint_word(word_key: String) -> void:
	var key: String = word_key.strip_edges().to_lower()
	if key.is_empty():
		return
	unlocked_hint_words[key] = true

func is_hint_word_unlocked(word_key: String) -> bool:
	var key: String = word_key.strip_edges().to_lower()
	if key.is_empty():
		return false
	return bool(unlocked_hint_words.get(key, false))
