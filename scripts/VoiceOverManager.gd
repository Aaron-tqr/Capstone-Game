extends RefCounted
class_name VoiceOverManager

const _VOICE_INDEX_PATH := "res://assets/voice over/voice_index.txt"

const MODE_WORD: String = "word"
const MODE_EMOTION: String = "emotion"

const _VOICE_CLIP_DIR_BY_EMOTION := {
	"joy": {
		MODE_WORD: "res://assets/voice over/Joy/word matching",
		MODE_EMOTION: "res://assets/voice over/Joy/emotion matching"
	},
	"anger": {
		MODE_WORD: "res://assets/voice over/Anger/word matching",
		MODE_EMOTION: "res://assets/voice over/Anger/emotion matching"
	},
	"fear": {
		MODE_WORD: "res://assets/voice over/Fear/word matching",
		MODE_EMOTION: "res://assets/voice over/Fear/emotion matching"
	},
	"sadness": {
		MODE_WORD: "res://assets/voice over/Sadness/word matching",
		MODE_EMOTION: "res://assets/voice over/Sadness/emotion matching"
	},
	"disgust": {
		MODE_WORD: "res://assets/voice over/Disgust/word matching",
		MODE_EMOTION: "res://assets/voice over/Disgust/emotion matching"
	}
}

static var _clip_cache: Dictionary = {}
static var _fallback_cursor: Dictionary = {}
static var _voice_index_loaded: bool = false
static var _indexed_voice_paths: Array[String] = []
const _DEFAULT_VOICE_DB: float = -4.0
const _SADNESS_VOICE_BOOST_DB: float = 4.0

static func play_matching_cue(character_key: String, mode: String, cue_text: String) -> void:
	if AudioManager == null:
		return
	var emotion: String = _normalize_emotion(character_key)
	if not _VOICE_CLIP_DIR_BY_EMOTION.has(emotion):
		return
	var normalized_mode: String = mode.strip_edges().to_lower()
	if normalized_mode != MODE_WORD and normalized_mode != MODE_EMOTION:
		return
	var clip_path: String = _select_clip_path(emotion, normalized_mode, cue_text)
	if clip_path.is_empty():
		return
	AudioManager.play_voice_file(clip_path, true, _voice_volume_for_emotion(emotion))

static func _voice_volume_for_emotion(emotion: String) -> float:
	if emotion == "sadness":
		return _SADNESS_VOICE_BOOST_DB
	return _DEFAULT_VOICE_DB

static func _select_clip_path(emotion: String, mode: String, cue_text: String) -> String:
	var files: Array[String] = _get_mode_clips(emotion, mode)
	if files.is_empty():
		return ""
	var normalized_cue: String = _normalize_text(cue_text)
	if not normalized_cue.is_empty():
		var best_path: String = ""
		var best_score: int = 0
		for path in files:
			var file_name: String = _normalize_text(path.get_file().get_basename())
			var score: int = _score_match(normalized_cue, file_name)
			if score > best_score:
				best_score = score
				best_path = path
		if best_score > 0 and not best_path.is_empty():
			return best_path

	var cursor_key: String = "%s|%s" % [emotion, mode]
	var index: int = int(_fallback_cursor.get(cursor_key, 0))
	var selected: String = files[index % files.size()]
	_fallback_cursor[cursor_key] = index + 1
	return selected

static func _get_mode_clips(emotion: String, mode: String) -> Array[String]:
	var cache_key: String = "%s|%s" % [emotion, mode]
	if _clip_cache.has(cache_key):
		return _clip_cache[cache_key]
	var emotion_dirs: Dictionary = _VOICE_CLIP_DIR_BY_EMOTION.get(emotion, {})
	var dir_path: String = String(emotion_dirs.get(mode, ""))
	if dir_path.is_empty():
		return []
	var files: Array[String] = _list_mp3_files(dir_path)
	_clip_cache[cache_key] = files
	return files

static func _list_mp3_files(dir_path: String) -> Array[String]:
	var files: Array[String] = []
	var seen: Dictionary = {}
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return _list_mp3_files_from_index(dir_path)
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
		return _list_mp3_files_from_index(dir_path)
	files.sort_custom(func(a: String, b: String) -> bool:
		return _compare_clip_name(a.get_file().get_basename(), b.get_file().get_basename())
	)
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
		return _compare_clip_name(a.get_file().get_basename(), b.get_file().get_basename())
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

static func _compare_clip_name(name_a: String, name_b: String) -> bool:
	var num_a: int = _extract_index(name_a)
	var num_b: int = _extract_index(name_b)
	if num_a != -1 and num_b != -1 and num_a != num_b:
		return num_a < num_b
	if num_a != -1 and num_b == -1:
		return true
	if num_b != -1 and num_a == -1:
		return false
	return name_a.to_lower() < name_b.to_lower()

static func _extract_index(file_stem: String) -> int:
	var regex := RegEx.new()
	regex.compile("^(?:line|question)\\s+(\\d+)$")
	var result: RegExMatch = regex.search(file_stem.strip_edges().to_lower())
	if result == null:
		return -1
	return int(result.get_string(1))

static func _score_match(cue: String, file_name: String) -> int:
	if cue.is_empty() or file_name.is_empty():
		return 0
	if cue == file_name:
		return 1000
	if cue.find(file_name) != -1 or file_name.find(cue) != -1:
		return 500
	var cue_words: PackedStringArray = cue.split(" ", false)
	var file_words: PackedStringArray = file_name.split(" ", false)
	var overlap: int = 0
	for word in cue_words:
		if word.length() <= 2:
			continue
		if file_words.has(word):
			overlap += 1
	if overlap <= 0:
		return 0
	return overlap * 40 + mini(cue_words.size(), file_words.size())

static func _normalize_emotion(raw_emotion: String) -> String:
	var emotion: String = raw_emotion.strip_edges().to_lower()
	match emotion:
		"sad", "sadnes":
			return "sadness"
		"angry":
			return "anger"
		"scared":
			return "fear"
		_:
			return emotion

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