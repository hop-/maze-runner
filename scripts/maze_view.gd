class_name MazeView
extends Node2D
## Draws the maze: moonlight-yellow floor and dark bluish walls with a lit top
## edge, a darker front face and a soft shadow on the floor below, 8-bit style.
## Draws everything once for mazes that fit the screen; for scrolling mazes it
## draws only the tile window the game passes to [method set_visible_tiles].

var maze: Maze
var tile := 8
var visible_tiles := Rect2i()  # empty = the whole maze


func show_maze(p_maze: Maze, p_tile: int) -> void:
	maze = p_maze
	tile = p_tile
	queue_redraw()


func set_visible_tiles(rect: Rect2i) -> void:
	visible_tiles = rect
	queue_redraw()


func _draw() -> void:
	if maze == null:
		return
	var u := maxi(1, tile / 8)  # one "pixel" of detail
	var area := Rect2i(0, 0, maze.width, maze.height)
	if visible_tiles.has_area():
		area = area.intersection(visible_tiles)
	draw_rect(Rect2(area.position * tile, area.size * tile), Palette.MOON)
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var t := Vector2i(x, y)
			var px := Vector2(x * tile, y * tile)
			if maze.is_wall(t):
				draw_rect(Rect2(px, Vector2(tile, tile)), Palette.WALL)
				if not maze.is_wall(t + Vector2i.UP):
					draw_rect(Rect2(px, Vector2(tile, u)), Palette.WALL_LIGHT)
				if not maze.is_wall(t + Vector2i.DOWN):
					draw_rect(Rect2(px.x, px.y + tile - 2 * u, tile, 2 * u), Palette.WALL_DARK)
			else:
				if maze.is_wall(t + Vector2i.UP):
					draw_rect(Rect2(px, Vector2(tile, u)), Palette.MOON_SHADE)
				if (x * 7 + y * 13) % 5 == 0:  # sparse floor specks
					draw_rect(Rect2(px.x + tile / 3, px.y + tile * 2 / 3, u, u), Palette.MOON_SHADE)
