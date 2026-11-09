class_name Sprites
extends RefCounted
## Pixel-art sprites as character grids, drawn with rectangles at any integer
## pixel size ("unit"). Each letter maps to a palette color; "." is transparent.

const SIZE := 7  # every sprite is 7x7

const FLAG := [
	"PRWRWR.",
	"PWRWRW.",
	"PRWRWR.",
	"P......",
	"P......",
	"P......",
	"PP.....",
]


## Off-screen pointer arrows; the other six directions are rotations of these.
const ARROW_E := [
	"..KK...",
	"..KRK..",
	"KKKRRK.",
	"KRRRRRK",
	"KKKRRK.",
	"..KRK..",
	"..KK...",
]
const ARROW_NE := [
	"..KKKKK",
	"..KRRRK",
	"...KRRK",
	"..KRKRK",
	".KRK.KK",
	"KRK....",
	"KK.....",
]

static var _arrows: Array = []


## Arrow for one of 8 directions: 0 = east, then clockwise (1 = south-east,
## 2 = south, ... 7 = north-east), with y pointing down as on screen.
static func arrow(octant: int) -> Array:
	if _arrows.is_empty():
		_arrows.resize(8)
		var straight := ARROW_E
		var diagonal := ARROW_NE
		for quarter in 4:  # each quarter turn clockwise adds 2 octants
			_arrows[quarter * 2] = straight
			_arrows[(quarter * 2 + 7) % 8] = diagonal
			straight = _rotate_cw(straight)
			diagonal = _rotate_cw(diagonal)
	return _arrows[posmod(octant, 8)]


static func _rotate_cw(pattern: Array) -> Array:
	var n := pattern.size()
	var out := []
	for y in n:
		var row := ""
		for x in n:
			row += pattern[n - 1 - x][y]
		out.append(row)
	return out


## FFI the green square. Pupils follow the facing direction; blink closes the eyes.
static func ffi(facing_left: bool = false, blink: bool = false) -> Array:
	var eyes := "OWKGWKO"
	if blink:
		eyes = "OGGGGGO"
	elif facing_left:
		eyes = "OKWGKWO"
	return [
		"OOOOOOO",
		"OLLGGGO",
		eyes,
		"OGGGGGO",
		"OKGGGKO",
		"OGKKKGO",
		"OOOOOOO",
	]


## Pixel size that fits a 7x7 sprite inside a tile with a little margin.
static func unit_for(tile: int) -> int:
	return maxi(1, (tile - 2) / SIZE)


## Offset that centers a sprite drawn at [method unit_for] inside a tile.
static func margin_for(tile: int) -> int:
	return (tile - SIZE * unit_for(tile)) / 2


static func color_of(code: String) -> Color:
	match code:
		"O": return Palette.FFI_DARK
		"G": return Palette.FFI
		"L": return Palette.FFI_LIGHT
		"W": return Palette.WHITE
		"K": return Palette.BLACK
		"R": return Palette.RED
		"P": return Palette.POLE
	return Color.MAGENTA


static func draw(ci: CanvasItem, pattern: Array, pos: Vector2, unit: int) -> void:
	for y in pattern.size():
		var row: String = pattern[y]
		for x in row.length():
			var code := row[x]
			if code != ".":
				ci.draw_rect(Rect2(pos.x + x * unit, pos.y + y * unit, unit, unit), color_of(code))
