class_name DirInput
extends RefCounted
## Turns every way of steering into maze directions: arrow keys/WASD, the
## gamepad d-pad, the left stick, and a touch drag (a "floating stick": put a
## finger down anywhere and slide it the way FFI should go).
##
## Call [method poll] once per frame, then read [member pressed] (directions
## newly pushed this frame) and [method wanted] (everything held right now).
## Analog input (stick or touch) picks its stronger axis; on a diagonal push the
## weaker axis is kept as a second choice, which lets FFI take a side corridor
## without the player having to be exact.

const ACTIONS := {
	"move_up": Vector2i.UP,
	"move_down": Vector2i.DOWN,
	"move_left": Vector2i.LEFT,
	"move_right": Vector2i.RIGHT,
}
const ANALOG_ON := 0.5        # push strength that counts as a direction
const ANALOG_SECOND := 0.35   # weaker axis of a diagonal, used as a second choice
const ANALOG_STICKY := 0.15   # the current axis stays until the other beats it by this
const TOUCH_FULL := 20.0      # drag distance (view pixels) that counts as a full push
const TOUCH_LEASH := 28.0     # beyond this the touch origin follows the finger

## Directions pushed this frame, in order (keys first, then analog).
var pressed: Array[Vector2i] = []

var _held: Array[Vector2i] = []    # keys / d-pad, most recent last
var _analog: Array[Vector2i] = []  # stick or touch: [main] or [main, second]
var _touch_index := -1
var _touch_origin := Vector2.ZERO
var _touch_offset := Vector2.ZERO


func poll() -> void:
	pressed.clear()
	for action: String in ACTIONS:
		var dir: Vector2i = ACTIONS[action]
		if Input.is_action_just_pressed(action):
			_held.erase(dir)
			_held.append(dir)
			pressed.append(dir)
		elif not Input.is_action_pressed(action):
			_held.erase(dir)
	var before := main_analog()
	_analog = _analog_dirs(_analog_vector(), before)
	var now := main_analog()
	if now != before and now != Vector2i.ZERO:
		pressed.append(now)


## Every direction held right now, most wanted first.
func wanted() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for i in range(_held.size() - 1, -1, -1):
		out.append(_held[i])
	out.append_array(_analog)
	return out


## The analog direction (stick or touch), or ZERO.
func main_analog() -> Vector2i:
	return _analog[0] if not _analog.is_empty() else Vector2i.ZERO


## The second choice for [param dir] when it came from a diagonal analog push.
func alternative(dir: Vector2i) -> Vector2i:
	if _analog.size() == 2 and _analog[0] == dir:
		return _analog[1]
	return Vector2i.ZERO


func is_touching() -> bool:
	return _touch_index != -1


## Feeds a touch event into the floating stick. Returns true if it was used.
func handle_touch(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _touch_index == -1:
			_touch_index = touch.index
			_touch_origin = touch.position
			_touch_offset = Vector2.ZERO
			return true
		if not touch.pressed and touch.index == _touch_index:
			_touch_index = -1
			_touch_offset = Vector2.ZERO
			return true
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _touch_index:
			_touch_offset = drag.position - _touch_origin
			if _touch_offset.length() > TOUCH_LEASH:
				# Drag the origin along so turning back needs only a short slide.
				_touch_origin = drag.position - _touch_offset.normalized() * TOUCH_LEASH
				_touch_offset = drag.position - _touch_origin
			return true
	return false


func _analog_vector() -> Vector2:
	var stick := Input.get_vector("stick_left", "stick_right", "stick_up", "stick_down")
	if stick.length() >= ANALOG_ON or _touch_index == -1:
		return stick
	return (_touch_offset / TOUCH_FULL).limit_length(1.0)


static func _analog_dirs(v: Vector2, previous: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if v.length() < ANALOG_ON:
		return out
	var ax := absf(v.x)
	var ay := absf(v.y)
	var horizontal := ax >= ay
	# Hysteresis: near a perfect diagonal, keep the axis already in use.
	if previous.x != 0 and ay < ax + ANALOG_STICKY:
		horizontal = true
	elif previous.y != 0 and ax < ay + ANALOG_STICKY:
		horizontal = false
	var x_dir := Vector2i(1 if v.x > 0.0 else -1, 0)
	var y_dir := Vector2i(0, 1 if v.y > 0.0 else -1)
	if horizontal:
		out.append(x_dir)
		if ay >= ANALOG_SECOND:
			out.append(y_dir)
	else:
		out.append(y_dir)
		if ax >= ANALOG_SECOND:
			out.append(x_dir)
	return out
