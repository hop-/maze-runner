extends SceneTree
## Headless checks for maze generation, modes and the pixel font.
## Run from the project folder:
##   godot --headless --path . --import          (once, builds the class cache)
##   godot --headless --path . --script res://tests/test_maze.gd

const VIEW := Vector2(320, 180)
const HUD_HEIGHT := 12

var _failures := 0
var _checks := 0


func _initialize() -> void:
	_test_perfect_maze_is_a_spanning_tree()
	_test_braid_adds_loops_but_keeps_everything_reachable()
	_test_full_braid_removes_all_dead_ends()
	_test_same_seed_same_maze()
	_test_start_and_exit()
	_test_exit_farthest_is_farthest()
	_test_mode_layouts()
	_test_font_glyphs_are_5x7()
	_test_text_maze_parses()
	_test_text_maze_roundtrip()
	_test_text_maze_errors()
	_test_font_wrap()
	_test_arrow_directions()
	_test_analog_directions()
	print("%d checks, %d failed" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _check(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		printerr("FAIL: ", what)


func _all_cells_reachable(m: Maze) -> bool:
	var dist := m.distances_from(m.start)
	for y in m.rows:
		for x in m.cols:
			var t := Maze.cell_to_tile(Vector2i(x, y))
			if dist[t.y * m.width + t.x] < 0:
				return false
	return true


func _test_perfect_maze_is_a_spanning_tree() -> void:
	for seed_value in range(1, 40):
		var m := Maze.generate(12, 9, 0.0, seed_value)
		var cells := m.cols * m.rows
		# Connected + exactly cells-1 passages = a tree: one route between any two cells.
		_check(_all_cells_reachable(m), "perfect maze %d: every cell reachable" % seed_value)
		_check(m.floor_count() == cells + cells - 1, "perfect maze %d: no loops" % seed_value)


func _test_braid_adds_loops_but_keeps_everything_reachable() -> void:
	var perfect := Maze.generate(15, 8, 0.0, 99)
	var braided := Maze.generate(15, 8, 0.5, 99)
	_check(braided.floor_count() > perfect.floor_count(), "braiding opens extra passages")
	_check(_all_cells_reachable(braided), "braided maze stays connected")
	_check(braided.dead_end_cells().size() < perfect.dead_end_cells().size(), "braiding removes dead ends")


func _test_full_braid_removes_all_dead_ends() -> void:
	for seed_value in range(1, 20):
		var m := Maze.generate(10, 6, 1.0, seed_value)
		_check(m.dead_end_cells().is_empty(), "braid 1.0 seed %d leaves no dead ends" % seed_value)


func _test_same_seed_same_maze() -> void:
	var a := Maze.generate(20, 12, 0.3, 12345)
	var b := Maze.generate(20, 12, 0.3, 12345)
	var c := Maze.generate(20, 12, 0.3, 54321)
	_check(a.tiles == b.tiles, "same seed gives the same maze")
	_check(a.tiles != c.tiles, "different seeds give different mazes")


func _test_start_and_exit() -> void:
	var m := Maze.generate(7, 4, 0.6, 3)
	_check(m.start == Vector2i(1, 1), "start is the top-left cell")
	_check(m.exit == Vector2i(13, 7), "exit is the bottom-right cell")
	_check(not m.is_wall(m.start) and not m.is_wall(m.exit), "start and exit are open")
	_check(m.shortest_steps(m.start, m.exit) > 0, "exit is reachable")
	_check(m.is_wall(Vector2i(-1, 0)) and m.is_wall(Vector2i(m.width, 0)), "outside the maze counts as wall")
	for x in m.width:
		_check(m.is_wall(Vector2i(x, 0)) and m.is_wall(Vector2i(x, m.height - 1)), "border row %d is wall" % x)


func _test_exit_farthest_is_farthest() -> void:
	var m := Maze.generate(30, 20, 0.0, 77, true)
	var dist := m.distances_from(m.start)
	var exit_d := dist[m.exit.y * m.width + m.exit.x]
	var max_d := 0
	for y in m.rows:
		for x in m.cols:
			var t := Maze.cell_to_tile(Vector2i(x, y))
			max_d = maxi(max_d, dist[t.y * m.width + t.x])
	_check(exit_d == max_d, "exit_farthest picks the farthest cell")


func _test_mode_layouts() -> void:
	var area := Vector2(VIEW.x, VIEW.y - HUD_HEIGHT)
	for i in Modes.count():
		var cfg := Modes.config(i)
		var tile: int = cfg["tile"]
		var px := Vector2(int(cfg["cols"]) * 2 + 1, int(cfg["rows"]) * 2 + 1) * tile
		var fits := px.x <= area.x and px.y <= area.y
		if i == Modes.GROWNUP:
			_check(not fits, "grownup maze is bigger than the screen (camera follows)")
		else:
			_check(fits, "%s maze fits on one screen" % cfg["name"])
		_check(Sprites.unit_for(cfg["tile"]) * Sprites.SIZE <= cfg["tile"], "%s sprite fits a tile" % cfg["name"])
	_check(Modes.from_name("kid") == Modes.KID, "mode lookup by name")


func _test_font_glyphs_are_5x7() -> void:
	for ch: String in PixelFont.GLYPHS:
		var rows := PixelFont.glyph_rows(ch)
		var ok := rows.size() == PixelFont.GLYPH_H
		for row in rows:
			ok = ok and row.length() == PixelFont.GLYPH_W
		_check(ok, "glyph '%s' is 5x7" % ch)


const SAMPLE := """
[][][][][][][]
[]M>      []
[]  [][]    []
[]      []>M[]
[][][][][][][]
"""


func _test_text_maze_parses() -> void:
	var result := Maze.from_text(SAMPLE)
	_check(not result.has("error"), "sample text maze parses: %s" % result.get("error", ""))
	if result.has("error"):
		return
	var m: Maze = result["maze"]
	_check(m.width == 7 and m.height == 5, "size from the longest line (got %dx%d)" % [m.width, m.height])
	_check(m.start == Vector2i(1, 1) and m.exit == Vector2i(5, 3), "start and finish positions")
	_check(m.is_wall(Vector2i(6, 1)), "short line is padded with wall")
	_check(m.shortest_steps(m.start, m.exit) == 6, "shortest route through the sample")
	var crlf := Maze.from_text(SAMPLE.replace("\n", "\r\n"))
	_check(not crlf.has("error"), "windows line endings are accepted")


func _test_text_maze_roundtrip() -> void:
	var generated := Maze.generate(40, 25, 0.2, 2024, true)
	var result := Maze.from_text(generated.to_text())
	_check(not result.has("error"), "generated maze survives to_text/from_text")
	if result.has("error"):
		return
	var m: Maze = result["maze"]
	_check(m.tiles == generated.tiles and m.start == generated.start and m.exit == generated.exit,
			"roundtrip keeps tiles, start and finish")


func _test_text_maze_errors() -> void:
	var cases := {
		"": "EMPTY",
		"[]  []\n[]  []": "ONE START",
		"M>  M>\n>M": "ONE START",
		"M>  >M  >M": "ONE FINISH",
		"M>[]>M": "CAN'T BE REACHED",
		"M>  ##>M": "LINE 1, COLUMN 5",
	}
	for text: String in cases:
		var result := Maze.from_text(text)
		var err: String = result.get("error", "")
		_check(err.contains(cases[text]), "error for %s: want '%s', got '%s'" % [text.c_escape(), cases[text], err])
	var missing := Maze.load_file("/nonexistent/maze.txt")
	_check(missing.get("error", "").begins_with("CAN'T OPEN"), "missing file reports an error")


func _test_font_wrap() -> void:
	var lines := PixelFont.wrap("THE FINISH >M CAN'T BE REACHED FROM THE START M>", 20)
	var ok := lines.size() == 3
	for line in lines:
		ok = ok and line.length() <= 20
	_check(ok, "wrap keeps lines within the limit: %s" % [lines])


func _test_arrow_directions() -> void:
	var mirrored := func(pattern: Array) -> Array:
		return pattern.map(func(row: String) -> String: return row.reverse())
	var flipped := func(pattern: Array) -> Array:  # rotated 180 degrees
		var rows := pattern.duplicate()
		rows.reverse()
		return mirrored.call(rows)
	_check(Sprites.arrow(0) == Sprites.ARROW_E and Sprites.arrow(7) == Sprites.ARROW_NE, "east and north-east are the base arrows")
	_check(Sprites.arrow(4) == mirrored.call(Sprites.ARROW_E), "west is east mirrored")
	_check(Sprites.arrow(3) == flipped.call(Sprites.ARROW_NE), "south-west is north-east turned around")
	_check(Sprites.arrow(2)[6][3] == "K" and Sprites.arrow(2)[5][3] == "R", "south arrow tip is at the bottom")
	_check(Sprites.arrow(-1) == Sprites.arrow(7), "octants wrap around")


func _test_analog_directions() -> void:
	var r := Vector2i.RIGHT
	var cases := [
		# [stick vector, previous main direction, expected directions]
		[Vector2(1, 0), Vector2i.ZERO, [r]],
		[Vector2(0.3, 0.2), Vector2i.ZERO, []],                       # inside the dead zone
		[Vector2(0.8, 0.5), Vector2i.ZERO, [r, Vector2i.DOWN]],       # diagonal: second choice
		[Vector2(-0.2, -0.9), Vector2i.ZERO, [Vector2i.UP]],          # weak side axis ignored
		[Vector2(0.6, 0.68), r, [r, Vector2i.DOWN]],                  # near-diagonal keeps its axis
		[Vector2(0.4, 0.9), r, [Vector2i.DOWN, r]],                   # clear switch to vertical
	]
	for c in cases:
		var got := DirInput._analog_dirs(c[0], c[1])
		var want: Array[Vector2i] = []
		want.assign(c[2])
		_check(got == want, "analog %s (was %s): want %s, got %s" % [c[0], c[1], want, got])
