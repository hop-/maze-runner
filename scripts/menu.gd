class_name MenuScreen
extends Node2D
## Title screen: a night sky with the moon and a short menu:
##   NEW GAME        starts the chosen mode
##   MODE: KID       Enter/click or left/right cycles TODDLER -> KID -> GROWNUP
##   MY MAZE         only when a --maze file was given
##   SOUND: ON       Enter/click or left/right toggles
##   QUIT            (hidden on iOS, where apps don't quit themselves)
## Works with keyboard, gamepad (d-pad or stick), mouse and touch.

signal mode_chosen(mode: int)
signal quit_requested

const VIEW := Vector2(320, 180)
const ITEM_X := 112
const ITEM_Y := 62
const ITEM_STEP := 18
const TEXT_SCALE := 2
const MESSAGE_CHARS := 52

## Mode the last game used (a Modes value, CUSTOM included); picks the entry
## highlighted first.
var selected_mode := Modes.TODDLER
## File name of the --maze file; empty hides the "MY MAZE" entry.
var custom_label := ""
## A problem to show at the bottom (e.g. a maze file that failed to load).
var message := ""

var _selected := 0
var _time := 0.0
var _stars: Array[Vector3] = []  # x, y, twinkle phase
var _steering := DirInput.new()
var _touch_ui := DisplayServer.is_touchscreen_available()


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 40:
		_stars.append(Vector3(rng.randi_range(2, 317), rng.randi_range(2, 177), rng.randf() * TAU))
	_selected = _index_of("custom" if selected_mode == Modes.CUSTOM else "play")
	Settings.sound_changed.connect(func(_on: bool) -> void: queue_redraw())


func _process(delta: float) -> void:
	_time += delta
	_steering.poll()
	for dir in _steering.pressed:
		if dir.y != 0:
			_move_selection(dir.y)
		else:
			_change_value(dir.x)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("confirm"):
		_activate()
	elif event is InputEventMouseMotion:
		var hit := _entry_at(get_global_mouse_position())
		if hit >= 0 and hit != _selected:
			_selected = hit
			Sfx.play("move")
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var hit := _entry_at(get_global_mouse_position())
		if hit >= 0:
			_selected = hit
			_activate()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:  # Android back button
		quit_requested.emit()


## Menu entries: {"label", "kind": play|mode|custom|sound|quit}.
func _entries() -> Array[Dictionary]:
	var list: Array[Dictionary] = [
		{"label": "NEW GAME", "kind": "play"},
		{"label": "MODE: " + Modes.config(Settings.mode)["name"], "kind": "mode"},
	]
	if not custom_label.is_empty():
		list.append({"label": Modes.CUSTOM_CONFIG["name"], "kind": "custom"})
	list.append({"label": "SOUND: " + ("ON" if Settings.sound_enabled else "OFF"), "kind": "sound"})
	if not OS.has_feature("ios"):
		list.append({"label": "QUIT", "kind": "quit"})
	return list


func _index_of(kind: String) -> int:
	var entries := _entries()
	for i in entries.size():
		if entries[i]["kind"] == kind:
			return i
	return 0


func _move_selection(step: int) -> void:
	_selected = wrapi(_selected + step, 0, _entries().size())
	Sfx.play("move")


## Left/right on MODE or SOUND changes the value; elsewhere it does nothing.
func _change_value(step: int) -> void:
	match _entries()[_selected]["kind"]:
		"mode":
			Settings.set_mode(Settings.mode + step)
			Sfx.play("move")
		"sound":
			Settings.set_sound(not Settings.sound_enabled)
			Sfx.play("move")


func _activate() -> void:
	match _entries()[_selected]["kind"]:
		"play":
			Sfx.play("select")
			mode_chosen.emit(Settings.mode)
		"mode":
			_change_value(1)
		"custom":
			Sfx.play("select")
			mode_chosen.emit(Modes.CUSTOM)
		"sound":
			Settings.set_sound(not Settings.sound_enabled)
			Sfx.play("select")
		"quit":
			quit_requested.emit()


func _entry_at(pos: Vector2) -> int:
	for i in _entries().size():
		if Rect2(ITEM_X - 20, ITEM_Y + i * ITEM_STEP - 2, 190, ITEM_STEP).has_point(pos):
			return i
	return -1


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW), Palette.NIGHT)
	for s in _stars:
		var bright := sin(_time * 2.0 + s.z) > -0.2
		draw_rect(Rect2(s.x, s.y, 1, 1), Palette.STAR if bright else Palette.NIGHT_LIGHT)
	_draw_moon(Vector2i(290, 26), 15)

	PixelFont.draw_text_centered(self, "MAZE RUNNER", VIEW.x / 2, 18, Palette.MOON, 3, Palette.WALL)
	PixelFont.draw_text_centered(self, "HELP FFI FIND THE WAY OUT", VIEW.x / 2, 44, Palette.STAR)

	var entries := _entries()
	for i in entries.size():
		var y := ITEM_Y + i * ITEM_STEP
		var color := Palette.MOON if i == _selected else Palette.WALL_LIGHT
		PixelFont.draw_text(self, entries[i]["label"], Vector2(ITEM_X, y), color, TEXT_SCALE)
		if i == _selected and entries[i]["kind"] in ["mode", "sound"]:
			# Small arrows hint that left/right change this value.
			var right := ITEM_X + PixelFont.text_width(entries[i]["label"], TEXT_SCALE) + 6
			var nudge := 1 if fmod(_time, 0.6) < 0.3 else 0
			PixelFont.draw_text(self, ">", Vector2(right + nudge, y + 4), Palette.FFI_LIGHT)
	# The cursor is FFI, hopping and blinking now and then.
	var hop := 1 if fmod(_time, 0.6) < 0.3 else 0
	var blink := fmod(_time, 3.0) > 2.85
	Sprites.draw(self, Sprites.ffi(false, blink), Vector2(ITEM_X - 20, ITEM_Y + _selected * ITEM_STEP - hop), 2)

	if not message.is_empty():
		var lines := PixelFont.wrap(message, MESSAGE_CHARS).slice(0, 2)
		for i in lines.size():
			PixelFont.draw_text_centered(self, lines[i], VIEW.x / 2, 159 + i * 10, Palette.RED)
		return
	var entry: Dictionary = entries[_selected]
	PixelFont.draw_text_centered(self, _info_line(entry), VIEW.x / 2, 157, Palette.FFI_LIGHT)
	PixelFont.draw_text_centered(self, _hint_line(entry), VIEW.x / 2, 169, Palette.WALL_LIGHT)


func _info_line(entry: Dictionary) -> String:
	match entry["kind"]:
		"play", "mode":
			var cfg := Modes.config(Settings.mode)
			var best: float = Settings.best_time(cfg["name"])
			if best < 0.0:
				return cfg["blurb"]
			return "%s  BEST %s" % [cfg["blurb"], Settings.format_time(best)]
		"custom":
			return custom_label
	return ""


func _hint_line(entry: Dictionary) -> String:
	if _touch_ui:
		return "TAP TO CHOOSE"
	if entry["kind"] in ["mode", "sound"]:
		return "LEFT / RIGHT: CHANGE  ENTER: NEXT"
	return "ARROWS: MOVE  ENTER: GO  M: SOUND"


func _draw_moon(center: Vector2i, radius: int) -> void:
	_draw_disc(center, radius, Palette.MOON)
	_draw_disc(center + Vector2i(-5, -4), 3, Palette.MOON_SHADE)
	_draw_disc(center + Vector2i(4, 3), 4, Palette.MOON_SHADE)
	_draw_disc(center + Vector2i(-3, 7), 2, Palette.MOON_SHADE)


func _draw_disc(center: Vector2i, radius: int, color: Color) -> void:
	for dy in range(-radius, radius + 1):
		var half := int(sqrt(radius * radius - dy * dy + radius * 0.8))
		draw_rect(Rect2(center.x - half, center.y + dy, half * 2 + 1, 1), color)
