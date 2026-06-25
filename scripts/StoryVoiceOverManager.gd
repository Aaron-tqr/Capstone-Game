extends RefCounted
class_name StoryVoiceOverManager

const _VOICE_INDEX_PATH := "res://assets/voice over/voice_index.txt"

const _SOURCES := {
	1: {
		"Narration": "res://assets/voice over/Narrator/act 1",
		"Jimm": "res://assets/voice over/act 1/Jimm",
		"Mom": "res://assets/voice over/act 1/Mother",
		"Friend": "res://assets/voice over/act 1/Friend",
		"Cousin": "res://assets/voice over/act 1/Cousin.mp3",
		"Joy": "res://assets/voice over/Joy/act 1",
		"Sadness": "res://assets/voice over/Sadness/act 1",
		"Anger": "res://assets/voice over/Anger/act 1",
		"Disgust": "res://assets/voice over/Disgust/act 1",
		"Fear": "res://assets/voice over/Fear/act 1"
	},
	2: {
		"Narration": "res://assets/voice over/Narrator/act 2",
		"Jimm": "res://assets/voice over/act 2/Jimm",
		"Friend": "res://assets/voice over/act 2/Friend",
		"Joy": "res://assets/voice over/Joy/act 2",
		"Sadness": "res://assets/voice over/Sadness/act 2",
		"Anger": "res://assets/voice over/Anger/act 2",
		"Disgust": "res://assets/voice over/Disgust/act 2",
		"Fear": "res://assets/voice over/Fear/act 2"
	},
	3: {
		"Narration": "res://assets/voice over/Narrator/act 3",
		"Jimm": "res://assets/voice over/act 3/Jimm",
		"Teacher": "res://assets/voice over/act 3/Teacher.mp3",
		"Big Kid": "res://assets/voice over/act 3/Big Kid.mp3",
		"Auntie": "res://assets/voice over/act 3/Auntie.mp3",
		"Joy": "res://assets/voice over/Joy/act 3",
		"Sadness": "res://assets/voice over/Sadness/act 3",
		"Anger": "res://assets/voice over/Anger/act 3",
		"Disgust": "res://assets/voice over/Disgust/act 3",
		"Fear": "res://assets/voice over/Fear/act 3"
	}
}

static var _file_cache: Dictionary = {}
static var _voice_index_loaded: bool = false
static var _indexed_voice_paths: Array[String] = []
const _DEFAULT_VOICE_DB: float = -4.0
const _SADNESS_VOICE_BOOST_DB: float = 4.0
const _TEACHER_VOICE_DB: float = -1.5
const _STORY_DUCK_DB: float = -28.0
const _STORY_DUCK_DOWN_DURATION: float = 0.05
const _STORY_DUCK_UP_DURATION: float = 0.40
const _MIN_STORY_DUCK_HOLD: float = 0.40

static func play_story_line(act_number: int, speaker: String, text: String, plain_story: bool, speaker_line_index: int = -1) -> void:
	if AudioManager == null:
		return
	if text.strip_edges().is_empty():
		return
	if not _SOURCES.has(act_number):
		return
	var resolved_speaker: String = _resolve_speaker_key(speaker, plain_story)
	var source: String = String(_SOURCES[act_number].get(resolved_speaker, ""))
	if source.is_empty():
		return
	var clip_paths: Array[String] = _collect_clips_from_source(source)
	if clip_paths.is_empty():
		return
	if source.to_lower().ends_with(".mp3") and clip_paths.size() == 1:
		_play_story_voice(clip_paths[0], resolved_speaker)
		return
	var normalized_text: String = _normalize_text(text)
	if normalized_text.is_empty():
		return
	var override_clip: String = _find_exact_story_override(act_number, resolved_speaker, normalized_text)
	if not override_clip.is_empty():
		_play_story_voice(override_clip, resolved_speaker)
		return
	if _is_strict_override_line(act_number, resolved_speaker, normalized_text):
		return
	var intro_clip: String = _pick_emotion_intro_clip(clip_paths, resolved_speaker, normalized_text)
	if not intro_clip.is_empty():
		_play_story_voice(intro_clip, resolved_speaker)
		return
	var chosen: String = _select_story_clip(clip_paths, normalized_text, speaker_line_index)
	if chosen.is_empty():
		return
	_play_story_voice(chosen, resolved_speaker)

static func play_story_question(act_number: int, question_text: String, question_number: int) -> void:
	if AudioManager == null:
		return
	if not _SOURCES.has(act_number):
		return
	var source: String = String(_SOURCES[act_number].get("Narration", ""))
	if source.is_empty():
		return
	var clip_paths: Array[String] = _collect_clips_from_source(source)
	if clip_paths.is_empty():
		return
	var by_number: String = _find_numbered_clip(clip_paths, "question", question_number)
	if not by_number.is_empty():
		_play_story_voice(by_number, "Narration")
		return
	var by_name: String = _best_named_match(_filter_named_clips(clip_paths), _normalize_text(question_text))
	if by_name.is_empty():
		return
	_play_story_voice(by_name, "Narration")

static func play_emotion_question_feedback(act_number: int, emotion_name: String, question_number: int) -> void:
	if AudioManager == null:
		return
	if not _SOURCES.has(act_number):
		return
	var source: String = String(_SOURCES[act_number].get(_normalize_speaker(emotion_name), ""))
	if source.is_empty():
		return
	var clip_paths: Array[String] = _collect_clips_from_source(source)
	if clip_paths.is_empty():
		return
	var by_number: String = _find_numbered_clip(clip_paths, "question", question_number)
	if by_number.is_empty():
		return
	_play_story_voice(by_number, _normalize_speaker(emotion_name))

static func _play_story_voice(path: String, speaker_key: String) -> void:
	if AudioManager == null or path.is_empty():
		return
	var hold_duration: float = maxf(_voice_length_seconds(path), _MIN_STORY_DUCK_HOLD)
	AudioManager.duck_music_temporarily(_STORY_DUCK_DB, _STORY_DUCK_DOWN_DURATION, hold_duration, _STORY_DUCK_UP_DURATION)
	AudioManager.play_voice_file(path, false, _voice_volume_for_speaker(speaker_key))

static func _voice_volume_for_speaker(speaker_key: String) -> float:
	if speaker_key == "Sadness":
		return _SADNESS_VOICE_BOOST_DB
	if speaker_key == "Teacher":
		return _TEACHER_VOICE_DB
	return _DEFAULT_VOICE_DB

static func _voice_length_seconds(path: String) -> float:
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		stream = load(path + ".remap") as AudioStream
	if stream == null:
		return 1.0
	var length: float = stream.get_length()
	if length <= 0.0:
		return 1.0
	return length

static func _collect_clips_from_source(source: String) -> Array[String]:
	if source.to_lower().ends_with(".mp3"):
		if _can_load_resource(source):
			return [source]
		return []
	return _list_mp3_files(source)

static func _can_load_resource(path: String) -> bool:
	if path.is_empty():
		return false
	if ResourceLoader.exists(path):
		return true
	return load(path) != null

static func _find_exact_story_override(act_number: int, speaker_key: String, normalized_text: String) -> String:
	if act_number == 3:
		if speaker_key == "Narration" and normalized_text.begins_with("the long day was finally over"):
			if _can_load_resource("res://assets/voice over/Narrator/act 3/line 9.mp3"):
				return "res://assets/voice over/Narrator/act 3/line 9.mp3"
		if speaker_key == "Narration" and normalized_text.begins_with("jimm closed his eyes"):
			if _can_load_resource("res://assets/voice over/Narrator/act 3/line 10.mp3"):
				return "res://assets/voice over/Narrator/act 3/line 10.mp3"
		if speaker_key == "Narration" and normalized_text.begins_with("the feelings never truly end"):
			if _can_load_resource("res://assets/voice over/Narrator/act 3/line 11.mp3"):
				return "res://assets/voice over/Narrator/act 3/line 11.mp3"
		if speaker_key == "Joy" and normalized_text.begins_with("you did it jimm"):
			if _can_load_resource("res://assets/voice over/Joy/act 1/you did it jimm.mp3"):
				return "res://assets/voice over/Joy/act 1/you did it jimm.mp3"
		return ""
	if act_number != 1:
		return ""
	if speaker_key == "Joy" and normalized_text.begins_with("whenever you are not sure"):
		var joy_candidates: Array[String] = [
			"res://assets/voice over/Joy/act 1/whenever you are  not sure.mp3",
			"res://assets/voice over/Joy/act 1/whenever you are not sure.mp3"
		]
		for joy_path in joy_candidates:
			if _can_load_resource(joy_path):
				return joy_path
		return ""
	if speaker_key == "Jimm" and (normalized_text.begins_with("oooh what") or normalized_text.begins_with("ooh what")):
		if _can_load_resource("res://assets/voice over/act 1/Jimm/ooh what.mp3"):
			return "res://assets/voice over/act 1/Jimm/ooh what.mp3"
	if speaker_key == "Friend" and normalized_text == "that is so cool jimm":
		if _can_load_resource("res://assets/voice over/act 1/Friend/line 5.mp3"):
			return "res://assets/voice over/act 1/Friend/line 5.mp3"
	var key: String = "%s|%s" % [speaker_key, normalized_text]
	var candidates: Dictionary = {
		"Jimm|woah is all of this for my birthday it looks amazing": [
			"res://assets/voice over/act 1/Jimm/line 3.mp3"
		],
		"Jimm|wow a present for me thank you so much mom i can t wait to open it": [
			"res://assets/voice over/act 1/Jimm/line 4.mp3"
		],
		"Jimm|woah it s pretty heavy i m so excited to open this gift": [
			"res://assets/voice over/act 1/Jimm/line 5.mp3"
		],
		"Mom|it s time to blow the birthday cake": [
			"res://assets/voice over/act 1/Mother/line 4.mp3"
		],
		"Jimm|wow you all look so different": [
			"res://assets/voice over/act 1/Jimm/line 2.mp3"
		],
		"Fear|no im fear": [
			"res://assets/voice over/Fear/act 1/im fear.mp3"
		]
	}
	if not candidates.has(key):
		return ""
	for path in Array(candidates[key]):
		if _can_load_resource(path):
			return path
	return ""

static func _is_strict_override_line(act_number: int, speaker_key: String, normalized_text: String) -> bool:
	if act_number != 1:
		return false
	return speaker_key == "Joy" and normalized_text.begins_with("whenever you are not sure")

static func _list_mp3_files(dir_path: String) -> Array[String]:
	if _file_cache.has(dir_path):
		return _file_cache[dir_path]
	var files: Array[String] = []
	var seen: Dictionary = {}
	var dir := DirAccess.open(dir_path)
	if dir == null:
		files = _list_mp3_files_from_index(dir_path)
		_file_cache[dir_path] = files
		return files
	dir.list_dir_begin()
	while true:
		var name: String = dir.get_next()
		if name.is_empty():
			break
		if dir.current_is_dir():
			continue
		var lower: String = name.to_lower()
		var resolved_name: String = ""
		if lower.ends_with(".mp3"):
			resolved_name = name
		elif lower.ends_with(".mp3.remap"):
			resolved_name = name.substr(0, name.length() - 6)
		else:
			continue
		var resolved_path: String = "%s/%s" % [dir_path, resolved_name]
		if seen.has(resolved_path):
			continue
		seen[resolved_path] = true
		files.append(resolved_path)
	dir.list_dir_end()
	if files.is_empty():
		# Exported builds can fail to enumerate packed directories on some devices.
		files = _list_mp3_files_from_index(dir_path)
		_file_cache[dir_path] = files
		return files
	files.sort_custom(func(a: String, b: String) -> bool:
		return _compare_file_name(a.get_file().get_basename(), b.get_file().get_basename())
	)
	_file_cache[dir_path] = files
	return files

static func _list_mp3_files_from_index(dir_path: String) -> Array[String]:
	_load_voice_index_if_needed()
	if _indexed_voice_paths.is_empty():
		return []
	var normalized_prefix: String = dir_path.replace("\\", "/").trim_suffix("/")
	if normalized_prefix.is_empty():
		return []
	var prefix_with_slash: String = normalized_prefix + "/"
	var output: Array[String] = []
	var seen: Dictionary = {}
	for raw_path in _indexed_voice_paths:
		var normalized_path: String = raw_path.replace("\\", "/")
		if not normalized_path.to_lower().begins_with(prefix_with_slash.to_lower()):
			continue
		if not normalized_path.to_lower().ends_with(".mp3"):
			continue
		if seen.has(normalized_path):
			continue
		seen[normalized_path] = true
		output.append(normalized_path)
	output.sort_custom(func(a: String, b: String) -> bool:
		return _compare_file_name(a.get_file().get_basename(), b.get_file().get_basename())
	)
	return output

static func _load_voice_index_if_needed() -> void:
	if _voice_index_loaded:
		return
	_voice_index_loaded = true
	if not FileAccess.file_exists(_VOICE_INDEX_PATH):
		return
	var index_text: String = FileAccess.get_file_as_string(_VOICE_INDEX_PATH)
	if index_text.is_empty():
		return
	for line in index_text.split("\n", false):
		var path: String = line.strip_edges().replace("\\", "/")
		if path.is_empty():
			continue
		if not path.to_lower().ends_with(".mp3"):
			continue
		_indexed_voice_paths.append(path)

static func _select_story_clip(clip_paths: Array[String], normalized_text: String, speaker_line_index: int) -> String:
	var by_name: String = _best_named_match(_filter_named_clips(clip_paths), normalized_text)
	if not by_name.is_empty():
		return by_name
	var line_paths: Array[String] = _filter_numbered_clips(clip_paths, "line")
	if line_paths.is_empty():
		line_paths = _filter_numbered_clips(clip_paths, "question")
	if line_paths.is_empty():
		return ""
	var index: int = 0
	if speaker_line_index > 0:
		index = speaker_line_index - 1
	var selected: String = line_paths[index % line_paths.size()]
	return selected

static func _filter_numbered_clips(clip_paths: Array[String], prefix: String) -> Array[String]:
	var output: Array[String] = []
	for path in clip_paths:
		var stem: String = _normalize_text(path.get_file().get_basename())
		if _extract_index(stem, prefix) != -1:
			output.append(path)
	output.sort_custom(func(a: String, b: String) -> bool:
		var ai: int = _extract_index(_normalize_text(a.get_file().get_basename()), prefix)
		var bi: int = _extract_index(_normalize_text(b.get_file().get_basename()), prefix)
		return ai < bi
	)
	return output

static func _filter_named_clips(clip_paths: Array[String]) -> Array[String]:
	var output: Array[String] = []
	for path in clip_paths:
		var stem: String = _normalize_text(path.get_file().get_basename())
		if _extract_index(stem, "line") != -1:
			continue
		if _extract_index(stem, "question") != -1:
			continue
		output.append(path)
	return output

static func _find_numbered_clip(clip_paths: Array[String], prefix: String, number: int) -> String:
	for path in clip_paths:
		var stem: String = _normalize_text(path.get_file().get_basename())
		if _extract_index(stem, prefix) == number:
			return path
	return ""

static func _best_named_match(named_paths: Array[String], normalized_text: String) -> String:
	if named_paths.is_empty() or normalized_text.is_empty():
		return ""
	var best_path: String = ""
	var best_score: int = 0
	for path in named_paths:
		var file_stem: String = _normalize_text(path.get_file().get_basename())
		var score: int = _score_match(normalized_text, file_stem)
		if score > best_score:
			best_score = score
			best_path = path
	if best_score <= 0:
		return ""
	return best_path

static func _pick_emotion_intro_clip(clip_paths: Array[String], speaker_key: String, normalized_text: String) -> String:
	if not _is_emotion_speaker(speaker_key):
		return ""
	if not normalized_text.begins_with("i m ") and not normalized_text.begins_with("im ") and not normalized_text.begins_with("hi i m ") and not normalized_text.begins_with("hi im ") and not normalized_text.begins_with("and i m ") and not normalized_text.begins_with("and im "):
		return ""
	var target: String = speaker_key.to_lower()
	for path in _filter_named_clips(clip_paths):
		var stem: String = _normalize_text(path.get_file().get_basename())
		if stem.find("im") == -1:
			continue
		if stem.find(target) == -1:
			continue
		return path
	return ""

static func _is_emotion_speaker(speaker_key: String) -> bool:
	match speaker_key:
		"Joy", "Sadness", "Anger", "Disgust", "Fear":
			return true
		_:
			return false

static func _compare_file_name(name_a: String, name_b: String) -> bool:
	var normalized_a: String = _normalize_text(name_a)
	var normalized_b: String = _normalize_text(name_b)
	var line_a: int = _extract_index(normalized_a, "line")
	var line_b: int = _extract_index(normalized_b, "line")
	if line_a != -1 and line_b != -1 and line_a != line_b:
		return line_a < line_b
	if line_a != -1 and line_b == -1:
		return true
	if line_b != -1 and line_a == -1:
		return false
	var q_a: int = _extract_index(normalized_a, "question")
	var q_b: int = _extract_index(normalized_b, "question")
	if q_a != -1 and q_b != -1 and q_a != q_b:
		return q_a < q_b
	if q_a != -1 and q_b == -1:
		return false
	if q_b != -1 and q_a == -1:
		return true
	return name_a.to_lower() < name_b.to_lower()

static func _extract_index(file_name: String, prefix: String) -> int:
	var regex := RegEx.new()
	regex.compile("^" + prefix + "\\s+(\\d+)$")
	var result: RegExMatch = regex.search(file_name.strip_edges().to_lower())
	if result == null:
		return -1
	return int(result.get_string(1))

static func _score_match(text: String, file_name: String) -> int:
	if text.is_empty() or file_name.is_empty():
		return 0
	if text == file_name:
		return 1000
	var tight_text: String = text.replace(" ", "")
	var tight_file: String = file_name.replace(" ", "")
	if tight_text.begins_with(tight_file):
		return 900 + tight_file.length()
	if text.begins_with(file_name):
		return 820 + file_name.length()
	var text_words: PackedStringArray = text.split(" ", false)
	var file_words: PackedStringArray = file_name.split(" ", false)
	if text_words.is_empty() or file_words.is_empty():
		return 0
	var prefix_matches: int = 0
	for i in range(mini(text_words.size(), file_words.size())):
		if text_words[i] != file_words[i]:
			break
		prefix_matches += 1
	if prefix_matches >= 2:
		return 700 + prefix_matches * 20
	var overlap: int = 0
	for word in file_words:
		if word.length() <= 2:
			continue
		if text_words.has(word):
			overlap += 1
	if overlap < 2:
		return 0
	return overlap * 40

static func _resolve_speaker_key(speaker: String, plain_story: bool) -> String:
	if plain_story:
		return "Narration"
	var s: String = speaker.strip_edges()
	if s.is_empty():
		return "Narration"
	var lowered: String = s.to_lower()
	if lowered == "narrator":
		return "Narration"
	if lowered == "mother":
		return "Mom"
	return _normalize_speaker(s)

static func _normalize_speaker(speaker: String) -> String:
	var s: String = speaker.strip_edges()
	if s.is_empty():
		return s
	var lowered: String = s.to_lower()
	match lowered:
		"jimm":
			return "Jimm"
		"mom", "mother":
			return "Mom"
		"friend":
			return "Friend"
		"cousin":
			return "Cousin"
		"joy":
			return "Joy"
		"sadness", "sadnes":
			return "Sadness"
		"anger", "angry":
			return "Anger"
		"disgust":
			return "Disgust"
		"fear", "scared":
			return "Fear"
		"teacher":
			return "Teacher"
		"big kid":
			return "Big Kid"
		"auntie":
			return "Auntie"
		_:
			return s

static func _normalize_text(raw_text: String) -> String:
	var lowered: String = raw_text.to_lower().strip_edges()
	if lowered.is_empty():
		return ""
	var output: String = ""
	for i in range(lowered.length()):
		var code: int = lowered.unicode_at(i)
		var c: String = lowered.substr(i, 1)
		var is_letter: bool = (code >= 97 and code <= 122)
		var is_number: bool = (code >= 48 and code <= 57)
		if is_letter or is_number or c == " ":
			output += c
		else:
			output += " "
	return " ".join(output.split(" ", false)).strip_edges()