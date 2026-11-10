class_name WinOverlay
extends Node2D
## The "you made it" panel with falling pixel confetti and a hopping FFI.

const VIEW := Vector2(320, 180)
const PANEL := Rect2(56, 40, 208, 104)

var _title := ""
var _lines: PackedStringArray = []
var _new_best := false
var _footer := ""
var _time := 0.0
var _confetti: Array[Dictionary] = []


func open(title: String, lines: PackedStringArray, new_best: bool, footer: String) -> void:
	_title = title
	_footer = footer
	_lines = lines
	_new_best = new_best
	_time = 0.0
	_confetti.clear()
	for i in 70:
		_confetti.append({
			"pos": Vector2(randf_range(0, VIEW.x), randf_range(-VIEW.y, 0)),
			"vel": Vector2(randf_range(-12, 12), randf_range(30, 70)),
			"color": Palette.CONFETTI.pick_random(),
		})
	visible = true
	queue_redraw()


func close() -> void:
	visible = false


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	for c in _confetti:
		c["pos"] += c["vel"] * delta
		if c["pos"].y > VIEW.y:
			c["pos"] = Vector2(randf_range(0, VIEW.x), -2)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(Palette.NIGHT, 0.55))
	for c in _confetti:
		draw_rect(Rect2(c["pos"].floor(), Vector2(2, 2)), c["color"])

	draw_rect(PANEL.grow(2), Palette.WALL_LIGHT)
	draw_rect(PANEL, Palette.NIGHT)
	var cx := PANEL.get_center().x
	var hop := 2 if fmod(_time, 0.5) < 0.25 else 0
	Sprites.draw(self, Sprites.ffi(), Vector2(cx - 7, PANEL.position.y + 6 - hop), 2)
	PixelFont.draw_text_centered(self, _title, cx, PANEL.position.y + 24, Palette.MOON, 2, Palette.WALL)

	var y := PANEL.position.y + 44
	for line in _lines:
		PixelFont.draw_text_centered(self, line, cx, y, Palette.STAR)
		y += 10
	if _new_best and fmod(_time, 0.8) < 0.55:
		PixelFont.draw_text_centered(self, "NEW BEST TIME!", cx, y + 2, Palette.FFI)
	PixelFont.draw_text_centered(self, _footer, cx, PANEL.end.y - 11, Palette.WALL_LIGHT)
