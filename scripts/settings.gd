extends Node
## Autoload "Settings": input actions, the sound toggle, and best times per
## mode, saved to user://maze_runner.cfg.

signal sound_changed(enabled: bool)

const SAVE_PATH := "user://maze_runner.cfg"

var sound_enabled := true
var _best: Dictionary = {}  # mode name -> best time in seconds


func _ready() -> void:
	_register_inputs()
	_load()
	_apply_sound()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_sound"):
		set_sound(not sound_enabled)
		get_viewport().set_input_as_handled()


func set_sound(enabled: bool) -> void:
	sound_enabled = enabled
	_apply_sound()
	_save()
	sound_changed.emit(enabled)


## Best time for a mode in seconds, or -1.0 if it has never been finished.
func best_time(mode_name: String) -> float:
	return _best.get(mode_name, -1.0)


## Stores [param seconds] if it beats the current best. Returns true on a new record.
func record_time(mode_name: String, seconds: float) -> bool:
	var best := best_time(mode_name)
	if best >= 0.0 and seconds >= best:
		return false
	_best[mode_name] = seconds
	_save()
	return true


func format_time(seconds: float) -> String:
	var tenths := int(seconds * 10.0)
	return "%d:%02d.%d" % [tenths / 600, (tenths / 10) % 60, tenths % 10]


func _apply_sound() -> void:
	AudioServer.set_bus_mute(0, not sound_enabled)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	sound_enabled = cfg.get_value("settings", "sound", true)
	for mode_name in cfg.get_section_keys("best") if cfg.has_section("best") else []:
		_best[mode_name] = float(cfg.get_value("best", mode_name))


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("settings", "sound", sound_enabled)
	for mode_name in _best:
		cfg.set_value("best", mode_name, _best[mode_name])
	cfg.save(SAVE_PATH)


func _register_inputs() -> void:
	_add_action("move_up", [KEY_UP, KEY_W], JOY_BUTTON_DPAD_UP)
	_add_action("move_down", [KEY_DOWN, KEY_S], JOY_BUTTON_DPAD_DOWN)
	_add_action("move_left", [KEY_LEFT, KEY_A], JOY_BUTTON_DPAD_LEFT)
	_add_action("move_right", [KEY_RIGHT, KEY_D], JOY_BUTTON_DPAD_RIGHT)
	_add_action("confirm", [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE], JOY_BUTTON_A)
	_add_action("back", [KEY_ESCAPE, KEY_BACKSPACE], JOY_BUTTON_B)
	_add_action("new_maze", [KEY_R], JOY_BUTTON_Y)
	_add_action("toggle_sound", [KEY_M], JOY_BUTTON_BACK)


func _add_action(action: StringName, keys: Array, joy_button: JoyButton) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event(action, ev)
	var joy := InputEventJoypadButton.new()
	joy.button_index = joy_button
	InputMap.action_add_event(action, joy)
