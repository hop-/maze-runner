class_name MenuScreen
extends Node2D
## Title screen: a night sky with the moon, and a list to pick a mode (plus the
## maze file given with --maze, if any), toggle sound or quit. Works with
## keyboard, gamepad and mouse.

signal mode_chosen(mode: int)
signal quit_requested

const VIEW := Vector2(320, 180)
const ITEM_X := 118
const ITEM_Y := 58
const ITEM_STEP := 16
const TEXT_SCALE := 2
const MESSAGE_CHARS := 52

## Mode to highlight first (a Modes value, CUSTOM included).
var selected_mode := Modes.TODDLER
## File name of the --maze file; empty hides the "MY MAZE" entry.
var custom_label := ""
## A problem to show at the bottom (e.g. a maze file that failed to load).
var message := ""

var _selected := 0
var _time := 0.0
var _stars: Array[Vector3] = []  # x, y, twinkle phase


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 40:
		_stars.append(Vector3(rng.randi_range(2, 317), rng.randi_range(2, 177), rng.randf() * TAU))
	var entries := _entries()
	for i in entries.size():
		if entries[i].get("mode", -1) == selected_mode:
			_selected = i
	Settings.sound_changed.connect(func(_on: bool) -> void: queue_redraw())


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		_move_selection(-1)
	elif event.is_action_pressed("move_down"):
		_move_selection(1)
	elif event.is_action_pressed("confirm"):
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


## Menu entries: {"label", "kind": mode|sound|quit, "mode"}.
func _entries() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for i in Modes.count():
		list.append({"label": Modes.config(i)["name"], "kind": "mode", "mode": i})
	if not custom_label.is_empty():
		list.append({"label": Modes.CUSTOM_CONFIG["name"], "kind": "mode", "mode": Modes.CUSTOM})
	list.append({"label": "SOUND: " + ("ON" if Settings.sound_enabled else "OFF"), "kind": "sound"})
	list.append({"label": "QUIT", "kind": "quit"})
	return list


func _move_selection(step: int) -> void:
	_selected = wrapi(_selected + step, 0, _entries().size())
	Sfx.play("move")


func _activate() -> void:
	var entry: Dictionary = _entries()[_selected]
	match entry["kind"]:
		"mode":
			Sfx.play("select")
			mode_chosen.emit(entry["mode"])
		"sound":
			Settings.set_sound(not Settings.sound_enabled)
			Sfx.play("select")
		"quit":
			quit_requested.emit()


func _entry_at(pos: Vector2) -> int:
	for i in _entries().size():
		if Rect2(ITEM_X - 20, ITEM_Y + i * ITEM_STEP - 1, 150, ITEM_STEP).has_point(pos):
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
	# The cursor is FFI, hopping and blinking now and then.
	var hop := 1 if fmod(_time, 0.6) < 0.3 else 0
	var blink := fmod(_time, 3.0) > 2.85
	Sprites.draw(self, Sprites.ffi(false, blink), Vector2(ITEM_X - 20, ITEM_Y + _selected * ITEM_STEP - hop), 2)

	if not message.is_empty():
		var lines := PixelFont.wrap(message, MESSAGE_CHARS).slice(0, 2)
		for i in lines.size():
			PixelFont.draw_text_centered(self, lines[i], VIEW.x / 2, 159 + i * 10, Palette.RED)
		return
	PixelFont.draw_text_centered(self, _info_line(entries[_selected]), VIEW.x / 2, 157, Palette.FFI_LIGHT)
	PixelFont.draw_text_centered(self, "ARROWS: MOVE  ENTER: GO  M: SOUND", VIEW.x / 2, 169, Palette.WALL_LIGHT)


func _info_line(entry: Dictionary) -> String:
	if entry["kind"] != "mode":
		return ""
	if entry["mode"] == Modes.CUSTOM:
		return custom_label
	var cfg := Modes.config(entry["mode"])
	var best: float = Settings.best_time(cfg["name"])
	if best < 0.0:
		return cfg["blurb"]
	return "%s  BEST %s" % [cfg["blurb"], Settings.format_time(best)]


func _draw_moon(center: Vector2i, radius: int) -> void:
	_draw_disc(center, radius, Palette.MOON)
	_draw_disc(center + Vector2i(-5, -4), 3, Palette.MOON_SHADE)
	_draw_disc(center + Vector2i(4, 3), 4, Palette.MOON_SHADE)
	_draw_disc(center + Vector2i(-3, 7), 2, Palette.MOON_SHADE)


func _draw_disc(center: Vector2i, radius: int, color: Color) -> void:
	for dy in range(-radius, radius + 1):
		var half := int(sqrt(radius * radius - dy * dy + radius * 0.8))
		draw_rect(Rect2(center.x - half, center.y + dy, half * 2 + 1, 1), color)
