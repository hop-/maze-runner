class_name ExitPointer
extends Node2D
## Screen-space arrow shown when the exit flag is off screen. It sits on the
## screen edge on the straight line from the view center to the flag and points
## that way, snapped to 8 directions to keep the pixel-art look.

const VIEW := Vector2(320, 180)
const UNIT := 2
const EDGE_MARGIN := 10.0  # arrow center to screen edge

var _target := Vector2.ZERO  # flag position in screen coordinates
var _time := 0.0


## Points at [param screen_pos] (the flag's center on screen), or hides the
## arrow when the flag is inside the visible play area.
func point_at(screen_pos: Vector2, play_area: Rect2) -> void:
	_target = screen_pos
	visible = not play_area.grow(-2.0).has_point(screen_pos)


func _process(delta: float) -> void:
	if visible:
		_time += delta
		queue_redraw()


func _draw() -> void:
	var area := Rect2(0, Hud.HEIGHT, VIEW.x, VIEW.y - Hud.HEIGHT)
	var center := area.get_center()
	var dir := _target - center
	if dir.is_zero_approx():
		return
	# Walk from the center toward the flag until the inset screen edge.
	var inset := area.grow(-EDGE_MARGIN)
	var half := inset.size / 2.0
	var t := INF
	if not is_zero_approx(dir.x):
		t = minf(t, half.x / absf(dir.x))
	if not is_zero_approx(dir.y):
		t = minf(t, half.y / absf(dir.y))
	var octant := roundi(dir.angle() / (PI / 4.0))
	var step := Vector2.from_angle(octant * PI / 4.0).round()
	var bob := step * (UNIT if fmod(_time, 0.5) < 0.25 else 0)  # nudge toward the flag
	var size := Sprites.SIZE * UNIT
	var pos := (center + dir * t - Vector2(size, size) / 2.0 + bob).round()
	Sprites.draw(self, Sprites.arrow(octant), pos, UNIT)
