class_name Player
extends Node2D
## FFI on the maze: moves one tile at a time with a short slide, looks the way
## it walks, blinks, and nudges against walls it bumps into.

signal arrived(tile_pos: Vector2i)

var tile := 8
var tile_pos := Vector2i.ZERO

var _facing_left := false
var _blink := false
var _blink_clock := 0.0
var _nudge := Vector2.ZERO
var _move_tween: Tween
var _nudge_tween: Tween


func place(p_tile: int, at: Vector2i) -> void:
	tile = p_tile
	tile_pos = at
	if _move_tween:
		_move_tween.kill()
	position = Vector2(at * tile)
	queue_redraw()


func is_moving() -> bool:
	return _move_tween != null and _move_tween.is_running()


## Center of FFI in world coordinates (for the camera).
func center() -> Vector2:
	return position + Vector2(tile, tile) / 2.0


func step_to(target: Vector2i, duration: float) -> void:
	_face(target - tile_pos)
	tile_pos = target
	if _move_tween:
		_move_tween.kill()
	_move_tween = create_tween()
	_move_tween.tween_property(self, "position", Vector2(target * tile), duration)
	_move_tween.finished.connect(func() -> void: arrived.emit(tile_pos))


func bump(dir: Vector2i) -> void:
	_face(dir)
	if _nudge_tween:
		_nudge_tween.kill()
	var u := Sprites.unit_for(tile)
	_nudge_tween = create_tween()
	_nudge_tween.tween_method(_set_nudge, Vector2(dir) * u, Vector2.ZERO, 0.12)


func _set_nudge(v: Vector2) -> void:
	_nudge = v.round()
	queue_redraw()


func _face(dir: Vector2i) -> void:
	if dir.x != 0:
		_facing_left = dir.x < 0
		queue_redraw()


func _process(delta: float) -> void:
	_blink_clock += delta
	var blink := fmod(_blink_clock, 3.2) > 3.05
	if blink != _blink:
		_blink = blink
		queue_redraw()


func _draw() -> void:
	var m := Sprites.margin_for(tile)
	Sprites.draw(self, Sprites.ffi(_facing_left, _blink), Vector2(m, m) + _nudge, Sprites.unit_for(tile))
