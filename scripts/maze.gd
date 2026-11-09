class_name Maze
extends RefCounted
## A randomly generated grid maze stored as tiles.
##
## A maze of cols x rows cells is a (2*cols+1) x (2*rows+1) tile grid: cells sit
## on odd tile coordinates, and the tiles between them are walls or passages.
## Generation uses an iterative recursive backtracker (long winding corridors),
## then optionally "braids" some dead ends into loops to make it easier.
##
## Mazes can also be read from text ([method from_text]): two characters per
## tile, [code][][/code] wall, two spaces path, [code]M>[/code] start,
## [code]>M[/code] finish. Text mazes can be any size and any shape.

const WALL := 1
const FLOOR := 0
const DIRS := [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]

const TOKEN_WALL := "[]"
const TOKEN_FLOOR := "  "
const TOKEN_START := "M>"
const TOKEN_EXIT := ">M"
const TOKEN_HELP := "USE [] WALL, 2 SPACES PATH, M> START, >M FINISH"

var cols: int  # cells; 0 for mazes read from text
var rows: int
var width: int   # in tiles
var height: int  # in tiles
var tiles := PackedByteArray()
var start: Vector2i  # tile coordinates
var exit: Vector2i   # tile coordinates


## Builds a new maze. A [param seed_value] of 0 picks a random seed.
static func generate(p_cols: int, p_rows: int, braid: float = 0.0, seed_value: int = 0,
		exit_farthest: bool = false) -> Maze:
	assert(p_cols >= 2 and p_rows >= 2, "a maze needs at least 2x2 cells")
	var m := Maze.new()
	m.cols = p_cols
	m.rows = p_rows
	m.width = p_cols * 2 + 1
	m.height = p_rows * 2 + 1
	m.tiles.resize(m.width * m.height)
	m.tiles.fill(WALL)

	var rng := RandomNumberGenerator.new()
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()

	m._carve(rng)
	if braid > 0.0:
		m._braid(rng, braid)

	m.start = cell_to_tile(Vector2i.ZERO)
	if exit_farthest:
		m.exit = m._farthest_cell_from(m.start)
	else:
		m.exit = cell_to_tile(Vector2i(p_cols - 1, p_rows - 1))
	return m


## Reads a maze file. Returns {"maze": Maze} or {"error": String}.
static func load_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"error": "CAN'T OPEN %s: %s" % [path.get_file(), error_string(FileAccess.get_open_error())]}
	return from_text(file.get_as_text())


## Parses a text maze (see the class description). Blank lines around the maze
## are ignored and short lines are padded with wall. Returns {"maze": Maze} or
## {"error": String}.
static func from_text(text: String) -> Dictionary:
	var lines := text.replace("\r", "").split("\n")
	var first := 0
	var last := lines.size() - 1
	while first <= last and lines[first].strip_edges().is_empty():
		first += 1
	while last >= first and lines[last].strip_edges().is_empty():
		last -= 1
	if first > last:
		return {"error": "THE MAZE FILE IS EMPTY"}

	var m := Maze.new()
	m.height = last - first + 1
	for i in range(first, last + 1):
		m.width = maxi(m.width, (lines[i].length() + 1) / 2)
	m.tiles.resize(m.width * m.height)
	m.tiles.fill(WALL)

	var starts := 0
	var exits := 0
	for y in m.height:
		var line: String = lines[first + y]
		if line.length() % 2 == 1:
			line += " "  # a trailing half-token: let the checks below judge it
		for x in line.length() / 2:
			var token := line.substr(x * 2, 2)
			if token == TOKEN_WALL:
				continue
			match token:
				TOKEN_FLOOR:
					pass
				TOKEN_START:
					m.start = Vector2i(x, y)
					starts += 1
				TOKEN_EXIT:
					m.exit = Vector2i(x, y)
					exits += 1
				_:
					return {"error": "LINE %d, COLUMN %d: UNKNOWN TILE '%s'. %s" % [
						first + y + 1, x * 2 + 1, token, TOKEN_HELP]}
			m._set_floor(Vector2i(x, y))

	if starts != 1:
		return {"error": "NEED EXACTLY ONE START M> (FOUND %d)" % starts}
	if exits != 1:
		return {"error": "NEED EXACTLY ONE FINISH >M (FOUND %d)" % exits}
	if m.shortest_steps(m.start, m.exit) < 0:
		return {"error": "THE FINISH >M CAN'T BE REACHED FROM THE START M>"}
	return {"maze": m}


## The maze in the text format read by [method from_text].
func to_text() -> String:
	var out := PackedStringArray()
	for y in height:
		var line := ""
		for x in width:
			var t := Vector2i(x, y)
			if t == start:
				line += TOKEN_START
			elif t == exit:
				line += TOKEN_EXIT
			else:
				line += TOKEN_WALL if is_wall(t) else TOKEN_FLOOR
		out.append(line)
	return "\n".join(out) + "\n"


static func cell_to_tile(cell: Vector2i) -> Vector2i:
	return cell * 2 + Vector2i.ONE


func is_wall(t: Vector2i) -> bool:
	if t.x < 0 or t.y < 0 or t.x >= width or t.y >= height:
		return true
	return tiles[t.y * width + t.x] == WALL


func floor_count() -> int:
	return tiles.count(FLOOR)


## Breadth-first distances in steps from [param from] to every tile (-1 = unreachable).
func distances_from(from: Vector2i) -> PackedInt32Array:
	var dist := PackedInt32Array()
	dist.resize(width * height)
	dist.fill(-1)
	if is_wall(from):
		return dist
	dist[from.y * width + from.x] = 0
	var queue: Array[Vector2i] = [from]
	var head := 0
	while head < queue.size():
		var cur := queue[head]
		head += 1
		var d := dist[cur.y * width + cur.x]
		for dir in DIRS:
			var n: Vector2i = cur + dir
			if not is_wall(n) and dist[n.y * width + n.x] == -1:
				dist[n.y * width + n.x] = d + 1
				queue.append(n)
	return dist


## Number of steps on the shortest route between two tiles (-1 if none).
func shortest_steps(from: Vector2i, to: Vector2i) -> int:
	return distances_from(from)[to.y * width + to.x]


## Cells whose only opening is a single passage.
func dead_end_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in rows:
		for x in cols:
			var cell := Vector2i(x, y)
			if _open_sides(cell) == 1:
				result.append(cell)
	return result


func _carve(rng: RandomNumberGenerator) -> void:
	var visited := PackedByteArray()
	visited.resize(cols * rows)
	var first := Vector2i(rng.randi_range(0, cols - 1), rng.randi_range(0, rows - 1))
	visited[first.y * cols + first.x] = 1
	_set_floor(cell_to_tile(first))
	var stack: Array[Vector2i] = [first]
	var options: Array[Vector2i] = []
	while not stack.is_empty():
		var cur: Vector2i = stack.back()
		options.clear()
		for dir in DIRS:
			var n: Vector2i = cur + dir
			if _cell_in_bounds(n) and visited[n.y * cols + n.x] == 0:
				options.append(n)
		if options.is_empty():
			stack.pop_back()
			continue
		var nxt := options[rng.randi_range(0, options.size() - 1)]
		visited[nxt.y * cols + nxt.x] = 1
		_set_floor(cell_to_tile(cur) + (nxt - cur))  # passage between the cells
		_set_floor(cell_to_tile(nxt))
		stack.append(nxt)


func _braid(rng: RandomNumberGenerator, amount: float) -> void:
	var ends := dead_end_cells()
	# Fisher-Yates with our own RNG so a seed always gives the same maze.
	for i in range(ends.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := ends[i]
		ends[i] = ends[j]
		ends[j] = tmp
	for cell in ends:
		if rng.randf() >= amount or _open_sides(cell) != 1:
			continue
		var walled: Array[Vector2i] = []
		var preferred: Array[Vector2i] = []  # joining two dead ends removes both
		for dir in DIRS:
			var n: Vector2i = cell + dir
			if _cell_in_bounds(n) and is_wall(cell_to_tile(cell) + dir):
				walled.append(dir)
				if _open_sides(n) == 1:
					preferred.append(dir)
		var pool := preferred if not preferred.is_empty() else walled
		if pool.is_empty():
			continue
		_set_floor(cell_to_tile(cell) + pool[rng.randi_range(0, pool.size() - 1)])


func _farthest_cell_from(from: Vector2i) -> Vector2i:
	var dist := distances_from(from)
	var best := from
	var best_d := -1
	for y in rows:
		for x in cols:
			var t := cell_to_tile(Vector2i(x, y))
			var d := dist[t.y * width + t.x]
			if d > best_d:
				best_d = d
				best = t
	return best


func _open_sides(cell: Vector2i) -> int:
	var t := cell_to_tile(cell)
	var n := 0
	for dir in DIRS:
		if not is_wall(t + dir):
			n += 1
	return n


func _cell_in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < cols and c.y < rows


func _set_floor(t: Vector2i) -> void:
	tiles[t.y * width + t.x] = FLOOR
