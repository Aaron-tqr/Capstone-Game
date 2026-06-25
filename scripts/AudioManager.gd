extends Node

const SFX_PATHS := {
	"button_click": "res://assets/sounds/button click.wav",
	"correct_choice": "res://assets/sounds/correct choice.wav",
	"wrong_choice": "res://assets/sounds/wrong choice.wav",
	"hint_open": "res://assets/sounds/hint button opening.wav",
	"hint_close": "res://assets/sounds/hint button closing.wav",
	"level_clear": "res://assets/sounds/level clear.mp3",
	"level_failed": "res://assets/sounds/level failed.wav",
	"level_unlock": "res://assets/sounds/level unlock.wav",
}

const MUSIC_PATHS := {
	"opening_flow": "res://assets/sounds/Game Theme OST.mp3",
	"home": "res://assets/sounds/bgm home.mp3",
	"level_select": "res://assets/sounds/bgm.mp3",
	"matching": "res://assets/sounds/matching game modes bgm.mp3",
	"story": "res://assets/sounds/story bgm.mp3",
}

var _music_player: AudioStreamPlayer
var _voice_player: AudioStreamPlayer
var _current_music_key: String = ""
var _current_scene_path: String = ""
var _is_switching_music: bool = false
var _music_disabled_by_user: bool = false
var _music_key_before_disable: String = ""

var _music_loop_restarting: bool = false
var _voice_segment_token: int = 0
var _was_tree_paused: bool = false
const MUSIC_FADE_IN: float = 0.8
const MUSIC_FADE_OUT: float = 0.8
const SILENT_DB: float = -60.0
const MUSIC_TARGET_DB: float = -10.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_audio_buses()
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = "Music"
	add_child(_music_player)
	_music_player.volume_db = SILENT_DB
	_voice_player = AudioStreamPlayer.new()
	_voice_player.name = "VoicePlayer"
	_voice_player.bus = "Voice"
	add_child(_voice_player)
	if get_tree() != null:
		get_tree().node_added.connect(_on_node_added)

func _process(_delta: float) -> void:
	var tree := get_tree()
	if tree != null:
		var is_paused_now: bool = tree.paused
		if is_paused_now and not _was_tree_paused:
			stop_voice()
		_was_tree_paused = is_paused_now
	_auto_switch_music_by_scene()
	_handle_music_soft_loop()

func play_sfx(name: String, volume_db: float = 0.0) -> void:
	if not SFX_PATHS.has(name):
		return
	var stream: AudioStream = load(String(SFX_PATHS[name]))
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.bus = "SFX"
	player.volume_db = volume_db
	player.stream = stream
	add_child(player)
	player.play()
	player.finished.connect(func() -> void:
		if is_instance_valid(player):
			player.queue_free()
	)

func play_voice(stream_or_path: Variant, duck_music: bool = true, volume_db: float = 0.0) -> void:
	if _voice_player == null:
		return
	var stream: AudioStream = _resolve_audio_stream(stream_or_path)
	if stream == null:
		return
	if _voice_player.playing:
		_voice_player.stop()
	_voice_player.stream = stream
	_voice_player.volume_db = volume_db
	_voice_player.play()
	if duck_music:
		duck_music_temporarily(-18.0, 0.08, 0.2, 0.25)
		_voice_player.finished.connect(func() -> void:
			if is_instance_valid(_voice_player) and not _music_disabled_by_user and _current_music_key != "" and _music_player != null and not _music_player.playing:
				_music_player.play()
		)

func stop_voice() -> void:
	if _voice_player != null and _voice_player.playing:
		_voice_player.stop()

func is_voice_playing() -> bool:
	return _voice_player != null and _voice_player.playing

func wait_for_voiceover(max_wait: float = 6.0) -> void:
	if _voice_player == null or not _voice_player.playing:
		return
	var elapsed: float = 0.0
	while _voice_player != null and _voice_player.playing and elapsed < max_wait:
		await get_tree().create_timer(0.05).timeout
		elapsed += 0.05

func play_voice_file(path: String, duck_music: bool = true, volume_db: float = 0.0) -> void:
	play_voice(path, duck_music, volume_db)

func play_voice_segment(stream_or_path: Variant, start_time: float, end_time: float = -1.0, duck_music: bool = true, volume_db: float = 0.0) -> void:
	if _voice_player == null:
		return
	var stream: AudioStream = _resolve_audio_stream(stream_or_path)
	if stream == null:
		return
	_voice_segment_token += 1
	var token: int = _voice_segment_token
	if _voice_player.playing:
		_voice_player.stop()
	_voice_player.stream = stream
	_voice_player.volume_db = volume_db
	var play_from: float = maxf(start_time, 0.0)
	_voice_player.play(play_from)
	if duck_music:
		var hold_duration: float = 0.15
		if end_time > play_from:
			hold_duration = maxf(end_time - play_from, 0.15)
		duck_music_temporarily(-18.0, 0.08, hold_duration, 0.25)
	if end_time <= play_from:
		return
	await get_tree().create_timer(end_time - play_from).timeout
	if token == _voice_segment_token and _voice_player != null and _voice_player.playing:
		_voice_player.stop()

func play_music(key: String) -> void:
	if _is_switching_music:
		return
	if not MUSIC_PATHS.has(key):
		return
	if _current_music_key == key and _music_player.playing:
		return
	_is_switching_music = true
	await _fade_out_music(0.35)
	var stream: AudioStream = load(String(MUSIC_PATHS[key]))
	if stream == null:
		_is_switching_music = false
		return
	_set_stream_looping(stream, true)
	_music_player.stream = stream
	_music_player.play()
	_current_music_key = key
	_music_loop_restarting = false
	await _fade_in_music(MUSIC_FADE_IN)
	_is_switching_music = false

func stop_music() -> void:
	if _music_player == null or not _music_player.playing:
		_current_music_key = ""
		return
	await _fade_out_music(0.35)
	_music_player.stop()
	_current_music_key = ""
	_music_loop_restarting = false

func _auto_switch_music_by_scene() -> void:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	if _music_disabled_by_user:
		if _music_player != null and _music_player.playing:
			_music_player.stop()
		_current_music_key = ""
		_music_loop_restarting = false
		return
	var scene_path: String = String(tree.current_scene.scene_file_path)
	if scene_path == _current_scene_path:
		return
	stop_voice()
	_current_scene_path = scene_path
	var target_key: String = _music_key_for_scene(scene_path)
	if target_key.is_empty():
		stop_music()
	else:
		play_music(target_key)

func _music_key_for_scene(scene_path: String) -> String:
	if scene_path.ends_with("Settings.tscn"):
		return _current_music_key
	var is_story_select: bool = (
		scene_path.contains("/Story/")
		and (
			scene_path.find("Select") != -1
			or scene_path.find("StoryActSelect") != -1
			or scene_path.find("StoryEmotionSelect") != -1
		)
	)
	if is_story_select:
		return "home"

	if scene_path.find("LevelSelect") != -1:
		return "level_select"

	var is_menu_flow: bool = (
		scene_path.ends_with("MainMenu.tscn")
		or scene_path.find("ModeSelect") != -1
		or scene_path.find("CharacterSelect") != -1
	)
	if is_menu_flow:
		return "opening_flow"

	var is_matching_gameplay: bool = (
		(scene_path.contains("/Word Matching/") and scene_path.find("LevelSelect") == -1 and scene_path.find("CharacterSelect") == -1)
		or (scene_path.contains("/Emotion Matching/") and scene_path.find("LevelSelect") == -1 and scene_path.find("CharacterSelect") == -1)
	)
	if is_matching_gameplay:
		return "matching"

	var is_story_gameplay: bool = (
		scene_path.contains("/Story/")
		and scene_path.find("Select") == -1
		and scene_path.find("StoryEndScene") == -1
	)
	if is_story_gameplay:
		return "story"

	return ""

func _handle_music_soft_loop() -> void:
	if _current_music_key.is_empty():
		return
	if _music_player == null or _music_player.stream == null or not _music_player.playing:
		return
	if _music_loop_restarting:
		return
	var length: float = _music_player.stream.get_length()
	if length <= 0.0:
		return
	if _music_player.get_playback_position() >= maxf(length - MUSIC_FADE_OUT, 0.0):
		_restart_music_loop()

func _restart_music_loop() -> void:
	if _music_loop_restarting:
		return
	_music_loop_restarting = true
	await _fade_out_music(MUSIC_FADE_OUT)
	if _current_music_key.is_empty() or _music_player.stream == null:
		_music_loop_restarting = false
		return
	_music_player.stop()
	_music_player.play(0.0)
	await _fade_in_music(MUSIC_FADE_IN)
	_music_loop_restarting = false

func _fade_in_music(duration: float) -> void:
	if _music_player == null:
		return
	_music_player.volume_db = SILENT_DB
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(_music_player, "volume_db", MUSIC_TARGET_DB, duration)
	await tw.finished

func _fade_out_music(duration: float) -> void:
	if _music_player == null:
		return
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE)
	tw.set_ease(Tween.EASE_IN)
	tw.tween_property(_music_player, "volume_db", SILENT_DB, duration)
	await tw.finished

func duck_music_temporarily(duck_db: float = -22.0, down_duration: float = 0.12, hold_duration: float = 0.15, up_duration: float = 0.25) -> void:
	if _music_player == null or not _music_player.playing:
		return
	var original_db: float = _music_player.volume_db
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(_music_player, "volume_db", minf(original_db, duck_db), down_duration)
	tw.tween_interval(hold_duration)
	tw.tween_property(_music_player, "volume_db", original_db, up_duration)

func _set_stream_looping(stream: AudioStream, loop_enabled: bool) -> void:
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = loop_enabled
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD if loop_enabled else AudioStreamWAV.LOOP_DISABLED
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = loop_enabled

func _resolve_audio_stream(stream_or_path: Variant) -> AudioStream:
	if stream_or_path is AudioStream:
		return stream_or_path as AudioStream
	if stream_or_path is String:
		var path: String = String(stream_or_path)
		var loaded: Resource = load(path)
		if loaded is AudioStream:
			return loaded as AudioStream
		var remap_loaded: Resource = load(path + ".remap")
		if remap_loaded is AudioStream:
			return remap_loaded as AudioStream
		push_warning("AudioManager: failed to load voice stream: %s" % path)
	return null

func _on_node_added(node: Node) -> void:
	if not (node is BaseButton):
		return
	var button := node as BaseButton
	if _is_music_button(button) and _music_disabled_by_user:
		_apply_music_button_visual(button, true)
	if button.pressed.is_connected(_on_any_button_pressed):
		return
	button.pressed.connect(_on_any_button_pressed.bind(button))

func _on_any_button_pressed(button: BaseButton) -> void:
	if button == null:
		return
	if _is_music_button(button):
		_toggle_music_from_button_press(button)
		return
	if _should_skip_button_click(button):
		return
	play_sfx("button_click")

func _is_music_button(button: BaseButton) -> bool:
	return String(button.name).to_lower().find("musicbutton") != -1

func _toggle_music_from_button_press(_button: BaseButton) -> void:
	if _music_disabled_by_user:
		_enable_music_from_button_press()
	else:
		_disable_music_from_button_press()

func _disable_music_from_button_press() -> void:
	_music_disabled_by_user = true
	if _music_key_before_disable.is_empty():
		_music_key_before_disable = _current_music_key
	stop_music()
	_set_music_buttons_visual(true)

func _enable_music_from_button_press() -> void:
	_music_disabled_by_user = false
	_set_music_buttons_visual(false)
	var resume_key: String = _music_key_before_disable
	if resume_key.is_empty():
		var tree := get_tree()
		if tree != null and tree.current_scene != null:
			resume_key = _music_key_for_scene(String(tree.current_scene.scene_file_path))
	if not resume_key.is_empty():
		play_music(resume_key)
	_music_key_before_disable = ""

func _set_music_buttons_visual(muted: bool) -> void:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	var stack: Array[Node] = [tree.current_scene]
	while stack.size() > 0:
		var current: Node = stack.pop_back()
		if current is BaseButton and _is_music_button(current as BaseButton):
			_apply_music_button_visual(current as BaseButton, muted)
		for child in current.get_children():
			stack.append(child)

func _apply_music_button_visual(button: BaseButton, muted: bool) -> void:
	button.disabled = false
	if button is TextureButton:
		var texture_button := button as TextureButton
		if not texture_button.has_meta("music_normal_texture"):
			texture_button.set_meta("music_normal_texture", texture_button.texture_normal)
		if muted:
			if texture_button.texture_disabled != null:
				texture_button.texture_normal = texture_button.texture_disabled
		else:
			if texture_button.has_meta("music_normal_texture"):
				texture_button.texture_normal = texture_button.get_meta("music_normal_texture") as Texture2D

func _ensure_audio_buses() -> void:
	_ensure_audio_bus("Music")
	_ensure_audio_bus("SFX")
	_ensure_audio_bus("Voice")

func _ensure_audio_bus(bus_name: String) -> void:
	var bus_idx: int = AudioServer.get_bus_index(bus_name)
	if bus_idx >= 0:
		return
	AudioServer.add_bus()
	bus_idx = AudioServer.bus_count - 1
	AudioServer.set_bus_name(bus_idx, bus_name)
	AudioServer.set_bus_send(bus_idx, "Master")

func _should_skip_button_click(button: BaseButton) -> bool:
	var n: String = String(button.name)
	if n.to_lower().find("hint") != -1:
		return true
	if button.is_in_group("emoticons") or button.is_in_group("word_draggables"):
		return true
	var script_ref: Script = button.get_script() as Script
	if script_ref != null:
		var script_path: String = String(script_ref.resource_path)
		if script_path.ends_with("Emoticon.gd") or script_path.ends_with("WordDraggable.gd"):
			return true
	return false
