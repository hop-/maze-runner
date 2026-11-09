class_name Modes
extends RefCounted
## The three difficulty modes. Harder modes get bigger mazes with fewer loops,
## no breadcrumb trail, an exit placed as far away as possible, and a camera
## that only shows part of the maze.

enum { TODDLER, KID, GROWNUP, CUSTOM }

## Settings for a maze loaded from a text file (--maze). Its tile size is
## picked to fit the maze (see GameScreen).
const CUSTOM_CONFIG := {
	"name": "MY MAZE", "blurb": "", "win": "ESCAPED!",
	"trail": true, "move_time": 0.08,
}

## cols/rows: maze size in cells. tile: pixels per tile (cell or wall).
## braid: share of dead ends opened into loops (0 = a perfect maze).
## exit_farthest: put the exit on the cell farthest from the start.
## trail: show breadcrumbs where FFI has been. move_time: seconds per step.
const LIST := [
	{
		"name": "TODDLER", "blurb": "TINY AND EASY", "win": "HOORAY!",
		"cols": 7, "rows": 4, "tile": 16, "braid": 0.6,
		"exit_farthest": false, "trail": true, "move_time": 0.14,
	},
	{
		"name": "KID", "blurb": "BIGGER AND TRICKIER", "win": "WELL DONE!",
		"cols": 15, "rows": 8, "tile": 9, "braid": 0.2,
		"exit_farthest": false, "trail": true, "move_time": 0.09,
	},
	{
		"name": "GROWNUP", "blurb": "HUGE. NO SHORTCUTS.", "win": "ESCAPED!",
		"cols": 30, "rows": 20, "tile": 9, "braid": 0.0,
		"exit_farthest": true, "trail": false, "move_time": 0.07,
	},
]


## Number of built-in (generated) modes; CUSTOM is not counted.
static func count() -> int:
	return LIST.size()


static func config(mode: int) -> Dictionary:
	if mode == CUSTOM:
		return CUSTOM_CONFIG
	return LIST[clampi(mode, 0, LIST.size() - 1)]


static func from_name(mode_name: String) -> int:
	for i in LIST.size():
		if LIST[i]["name"] == mode_name.to_upper():
			return i
	return -1
