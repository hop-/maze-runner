extends Node
## Root node: shows the title menu or a game and swaps between them.
##
## Command line (works for `godot --path .` and for exported builds, with or
## without a `--` separator):
##   --maze=FILE   play a maze from a text file ([] wall, 2 spaces path,
##                 M> start, >M finish); it also appears as "MY MAZE" on the menu
##   --mode=NAME   start straight in toddler, kid or grownup

var _screen: Node
var _maze_path := ""


func _ready() -> void:
	var maze_arg := _arg_value("maze")
	if not maze_arg.is_empty():
		_maze_path = _resolve_path(maze_arg)
		var result := Maze.load_file(_maze_path)
		if result.has("error"):
			_fail(result["error"])
		else:
			_start_game(Modes.CUSTOM)
		return
	var mode := Modes.from_name(_arg_value("mode"))
	if mode >= 0:
		_start_game(mode)
	else:
		_show_menu(Modes.TODDLER)


func _show_menu(selected: int, message: String = "") -> void:
	var menu := MenuScreen.new()
	menu.selected_mode = selected
	menu.message = message
	if not _maze_path.is_empty():
		menu.custom_label = _maze_path.get_file()
	menu.mode_chosen.connect(_start_game)
	menu.quit_requested.connect(get_tree().quit)
	_swap(menu)


func _start_game(mode: int) -> void:
	var game := GameScreen.new()
	game.mode = mode
	game.maze_path = _maze_path
	game.exit_to_menu.connect(_show_menu)
	game.load_failed.connect(_fail)
	_swap(game)


## Reports a maze-file problem on stderr and on the menu.
func _fail(message: String) -> void:
	printerr("maze file %s: %s" % [_maze_path, message])
	_show_menu.call_deferred(Modes.CUSTOM, message)


func _swap(screen: Node) -> void:
	if _screen:
		_screen.queue_free()
	_screen = screen
	add_child(screen)


## Value of --name=value or --name value, from user args (after --) or plain args.
func _arg_value(arg_name: String) -> String:
	var args := OS.get_cmdline_user_args() + OS.get_cmdline_args()
	var flag := "--" + arg_name
	for i in args.size():
		if args[i].begins_with(flag + "="):
			return args[i].trim_prefix(flag + "=")
		if args[i] == flag and i + 1 < args.size():
			return args[i + 1]
	return ""


## Godot changes the working directory to the project folder when run with
## --path, so relative paths are resolved against the shell's $PWD first.
func _resolve_path(path: String) -> String:
	if path.begins_with("~"):
		path = OS.get_environment("HOME") + path.substr(1)
	if path.is_absolute_path():
		return path
	var pwd := OS.get_environment("PWD")
	if not pwd.is_empty() and FileAccess.file_exists(pwd.path_join(path)):
		return pwd.path_join(path)
	return path
