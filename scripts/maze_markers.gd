class_name MazeMarkers
extends Node2D
## Things drawn on top of the maze floor: the breadcrumb trail and the
## waving exit flag.

var tile := 8
var exit_tile := Vector2i.ZERO
var show_trail := true
var visible_tiles := Rect2i()  # empty = everything

var _trail: Dictionary = {}  # Vector2i -> true
var _time := 0.0


func reset(p_tile: int, p_exit: Vector2i, p_show_trail: bool) -> void:
	tile = p_tile
	exit_tile = p_exit
	show_trail = p_show_trail
	_trail.clear()
	queue_redraw()


func set_visible_tiles(rect: Rect2i) -> void:
	visible_tiles = rect
	queue_redraw()


func add_trail(t: Vector2i) -> void:
	if show_trail and not _trail.has(t):
		_trail[t] = true
		queue_redraw()


func _process(delta: float) -> void:
	var before := _wave_frame()
	_time += delta
	if _wave_frame() != before:
		queue_redraw()


func _wave_frame() -> int:
	return int(_time / 0.35) % 2


func _draw() -> void:
	var u := Sprites.unit_for(tile)
	var dot := maxi(1, tile / 5)
	var cull := visible_tiles.has_area()
	for t: Vector2i in _trail:
		if cull and not visible_tiles.has_point(t):
			continue
		var c := Vector2(t * tile) + Vector2.ONE * floorf((tile - dot) / 2.0)
		draw_rect(Rect2(c, Vector2(dot, dot)), Palette.TRAIL)
	var pos := Vector2(exit_tile * tile) + Vector2.ONE * Sprites.margin_for(tile)
	pos.y -= _wave_frame() * u
	Sprites.draw(self, Sprites.FLAG, pos, u)
