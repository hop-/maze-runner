class_name GameScreen
extends Node2D
## One play session in a mode: builds a maze, moves FFI with the keys, runs the
## clock, and shows the win panel. R makes a new maze (or reloads the maze
## file), Esc goes back to the menu.

signal exit_to_menu(mode: int)
signal load_failed(message: String)

const VIEW := Vector2(320, 180)
const CAMERA_PAD := 6
const FILE_TILE_SIZES := [16, 9]  # largest that fits the screen wins; else 9 + scrolling
const DIR_ACTIONS := {
	"move_up": Vector2i.UP,
	"move_down": Vector2i.DOWN,
	"move_left": Vector2i.LEFT,
	"move_right": Vector2i.RIGHT,
}

var mode := Modes.TODDLER
var maze_path := ""  # read for Modes.CUSTOM

var _cfg: Dictionary
var _maze: Maze
var _tile := 8
var _shortest := 0
var _elapsed := 0.0
var _moves := 0
var _clock_running := false
var _won := false
var _held: Array[Vector2i] = []     # held directions, most recent last
var _queued := Vector2i.ZERO        # tap pressed while FFI was mid-step

var _view := MazeView.new()
var _markers := MazeMarkers.new()
var _player := Player.new()
var _camera := Camera2D.new()
var _hud := Hud.new()
var _pointer := ExitPointer.new()
var _win := WinOverlay.new()
var _follow_camera := false
var _visible_tiles := Rect2i()


func _ready() -> void:
	_cfg = Modes.config(mode)
	add_child(_view)
	add_child(_markers)
	add_child(_player)
	add_child(_camera)
	_camera.make_current()
	_player.arrived.connect(_on_player_arrived)

	var hud_layer := CanvasLayer.new()
	add_child(hud_layer)
	hud_layer.add_child(_hud)
	hud_layer.add_child(_pointer)
	_pointer.visible = false
	_hud.mode_name = _cfg["name"]

	var win_layer := CanvasLayer.new()
	win_layer.layer = 2
	add_child(win_layer)
	win_layer.add_child(_win)
	_win.close()

	_new_maze()


func _new_maze() -> void:
	if mode == Modes.CUSTOM:
		# Re-read the file every time, so edits show up after pressing R.
		var result := Maze.load_file(maze_path)
		if result.has("error"):
			set_process_unhandled_input(false)
			load_failed.emit(result["error"])
			return
		_maze = result["maze"]
		_tile = _fit_tile(_maze)
	else:
		_maze = Maze.generate(_cfg["cols"], _cfg["rows"], _cfg["braid"], 0, _cfg["exit_farthest"])
		_tile = _cfg["tile"]
	_shortest = _maze.shortest_steps(_maze.start, _maze.exit)
	_view.show_maze(_maze, _tile)
	_markers.reset(_tile, _maze.exit, _cfg["trail"])
	_markers.add_trail(_maze.start)
	_player.place(_tile, _maze.start)
	_elapsed = 0.0
	_moves = 0
	_clock_running = false
	_won = false
	_queued = Vector2i.ZERO
	_win.close()
	_setup_camera()
	_update_visible_tiles()
	_update_hud()
	Sfx.play("new")


func _fit_tile(m: Maze) -> int:
	for size: int in FILE_TILE_SIZES:
		if m.width * size <= VIEW.x and m.height * size <= VIEW.y - Hud.HEIGHT:
			return size
	return FILE_TILE_SIZES.back()


func _setup_camera() -> void:
	var maze_px := Vector2(_maze.width, _maze.height) * _tile
	var area := Vector2(VIEW.x, VIEW.y - Hud.HEIGHT)
	_follow_camera = maze_px.x > area.x or maze_px.y > area.y
	if _follow_camera:
		_camera.limit_left = -CAMERA_PAD
		_camera.limit_top = -CAMERA_PAD - Hud.HEIGHT
		_camera.limit_right = int(maze_px.x) + CAMERA_PAD
		_camera.limit_bottom = int(maze_px.y) + CAMERA_PAD
		_camera.position_smoothing_enabled = true
		_camera.position_smoothing_speed = 8.0
		_camera.position = _camera_target()
		_camera.reset_smoothing()
	else:
		# The whole maze fits: center it in the area below the HUD.
		_camera.limit_left = -10000000
		_camera.limit_top = -10000000
		_camera.limit_right = 10000000
		_camera.limit_bottom = 10000000
		_camera.position_smoothing_enabled = false
		_camera.position = (maze_px / 2.0 - Vector2(0, Hud.HEIGHT / 2.0)).floor()


## With a scrolling camera only the tiles on screen are drawn, so mazes of any
## size stay cheap. Redraws happen only when that tile window changes.
func _update_visible_tiles() -> void:
	var rect := Rect2i()  # empty = draw everything
	if _follow_camera:
		var top_left := _camera.get_screen_center_position() - VIEW / 2.0
		var first := Vector2i((top_left / _tile).floor()) - Vector2i.ONE
		rect = Rect2i(first, Vector2i((VIEW / _tile).ceil()) + Vector2i(3, 3))
	if rect != _visible_tiles:
		_visible_tiles = rect
		_view.set_visible_tiles(rect)
		_markers.set_visible_tiles(rect)


## Shows the edge arrow toward the exit while the flag is scrolled off screen.
func _update_pointer() -> void:
	if not _follow_camera or _won or _maze == null:
		_pointer.visible = false
		return
	var view_origin := _camera.get_screen_center_position() - VIEW / 2.0
	var flag_center := Vector2(_maze.exit * _tile) + Vector2(_tile, _tile) / 2.0
	var play_area := Rect2(0, Hud.HEIGHT, VIEW.x, VIEW.y - Hud.HEIGHT)
	_pointer.point_at(flag_center - view_origin, play_area)


func _camera_target() -> Vector2:
	return (_player.center() - Vector2(0, Hud.HEIGHT / 2.0)).floor()


func _process(delta: float) -> void:
	if _follow_camera:
		_camera.position = _camera_target()
		_update_visible_tiles()
	_update_pointer()
	if _clock_running and not _won:
		_elapsed += delta
		_update_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("back"):
		exit_to_menu.emit(mode)
		return
	if _won:
		if event.is_action_pressed("confirm") or event.is_action_pressed("new_maze"):
			_new_maze()
		return
	if event.is_action_pressed("new_maze"):
		_new_maze()
		return
	for action: String in DIR_ACTIONS:
		var dir: Vector2i = DIR_ACTIONS[action]
		if event.is_action_pressed(action):
			_held.erase(dir)
			_held.append(dir)
			_try_step(dir, true)
		elif event.is_action_released(action):
			_held.erase(dir)


## Tries to move one tile. Taps during a step are queued; held keys keep FFI
## walking. Only a fresh key press bumps (so holding into a wall stays quiet).
func _try_step(dir: Vector2i, pressed_now: bool) -> void:
	if _won:
		return
	if _player.is_moving():
		if pressed_now:
			_queued = dir
		return
	var target := _player.tile_pos + dir
	if _maze.is_wall(target):
		if pressed_now:
			_player.bump(dir)
			Sfx.play("bump")
		return
	_clock_running = true
	_moves += 1
	_player.step_to(target, _cfg["move_time"])
	_markers.add_trail(target)
	Sfx.play("step")
	_update_hud()


func _on_player_arrived(at: Vector2i) -> void:
	if at == _maze.exit:
		_finish()
		return
	if _queued != Vector2i.ZERO:
		var dir := _queued
		_queued = Vector2i.ZERO
		_try_step(dir, true)
		return
	# Drop keys released while the window was unfocused, then keep walking.
	_held = _held.filter(func(d: Vector2i) -> bool: return Input.is_action_pressed(_action_for(d)))
	if not _held.is_empty():
		_try_step(_held.back(), false)


func _finish() -> void:
	_won = true
	_held.clear()
	_queued = Vector2i.ZERO
	var mode_name: String = _cfg["name"]
	# Best times are kept for the built-in modes only, not for maze files.
	var new_best: bool = mode != Modes.CUSTOM and Settings.record_time(mode_name, _elapsed)
	var lines := PackedStringArray([
		"TIME " + Settings.format_time(_elapsed),
		"MOVES %d   SHORTEST %d" % [_moves, _shortest],
	])
	if mode != Modes.CUSTOM and not new_best:
		lines.append("BEST " + Settings.format_time(Settings.best_time(mode_name)))
	_win.open(_cfg["win"], lines, new_best)
	Sfx.play("win")


func _update_hud() -> void:
	_hud.set_values(Settings.format_time(_elapsed), _moves)


func _action_for(dir: Vector2i) -> String:
	for action: String in DIR_ACTIONS:
		if DIR_ACTIONS[action] == dir:
			return action
	return ""
