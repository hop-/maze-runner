class_name PixelFont
extends RefCounted
## A tiny 5x7 bitmap font drawn with rectangles, so text stays crisp and 8-bit
## at any integer scale. Unknown characters render as "?".

const GLYPH_W := 5
const GLYPH_H := 7
const ADVANCE := 6  # glyph width + 1px gap

const GLYPHS := {
	"A": ".###. #...# #...# ##### #...# #...# #...#",
	"B": "####. #...# #...# ####. #...# #...# ####.",
	"C": ".###. #...# #.... #.... #.... #...# .###.",
	"D": "####. #...# #...# #...# #...# #...# ####.",
	"E": "##### #.... #.... ####. #.... #.... #####",
	"F": "##### #.... #.... ####. #.... #.... #....",
	"G": ".###. #...# #.... #.### #...# #...# .####",
	"H": "#...# #...# #...# ##### #...# #...# #...#",
	"I": ".###. ..#.. ..#.. ..#.. ..#.. ..#.. .###.",
	"J": "..### ...#. ...#. ...#. ...#. #..#. .##..",
	"K": "#...# #..#. #.#.. ##... #.#.. #..#. #...#",
	"L": "#.... #.... #.... #.... #.... #.... #####",
	"M": "#...# ##.## #.#.# #.#.# #...# #...# #...#",
	"N": "#...# #...# ##..# #.#.# #..## #...# #...#",
	"O": ".###. #...# #...# #...# #...# #...# .###.",
	"P": "####. #...# #...# ####. #.... #.... #....",
	"Q": ".###. #...# #...# #...# #.#.# #..#. .##.#",
	"R": "####. #...# #...# ####. #.#.. #..#. #...#",
	"S": ".#### #.... #.... .###. ....# ....# ####.",
	"T": "##### ..#.. ..#.. ..#.. ..#.. ..#.. ..#..",
	"U": "#...# #...# #...# #...# #...# #...# .###.",
	"V": "#...# #...# #...# #...# #...# .#.#. ..#..",
	"W": "#...# #...# #...# #.#.# #.#.# #.#.# .#.#.",
	"X": "#...# #...# .#.#. ..#.. .#.#. #...# #...#",
	"Y": "#...# #...# .#.#. ..#.. ..#.. ..#.. ..#..",
	"Z": "##### ....# ...#. ..#.. .#... #.... #####",
	"0": ".###. #...# #..## #.#.# ##..# #...# .###.",
	"1": "..#.. .##.. ..#.. ..#.. ..#.. ..#.. .###.",
	"2": ".###. #...# ....# ...#. ..#.. .#... #####",
	"3": "##### ...#. ..#.. ...#. ....# #...# .###.",
	"4": "...#. ..##. .#.#. #..#. ##### ...#. ...#.",
	"5": "##### #.... ####. ....# ....# #...# .###.",
	"6": "..##. .#... #.... ####. #...# #...# .###.",
	"7": "##### ....# ...#. ..#.. .#... .#... .#...",
	"8": ".###. #...# #...# .###. #...# #...# .###.",
	"9": ".###. #...# #...# .#### ....# ...#. .##..",
	":": "..... ..#.. ..#.. ..... ..#.. ..#.. .....",
	".": "..... ..... ..... ..... ..... .##.. .##..",
	",": "..... ..... ..... ..... .##.. ..#.. .#...",
	"!": "..#.. ..#.. ..#.. ..#.. ..#.. ..... ..#..",
	"?": ".###. #...# ....# ...#. ..#.. ..... ..#..",
	"-": "..... ..... ..... .###. ..... ..... .....",
	"/": "....# ....# ...#. ..#.. .#... #.... #....",
	">": ".#... ..#.. ...#. ....# ...#. ..#.. .#...",
	"<": "...#. ..#.. .#... #.... .#... ..#.. ...#.",
	"'": "..#.. ..#.. ..... ..... ..... ..... .....",
	"+": "..... ..#.. ..#.. ##### ..#.. ..#.. .....",
	"=": "..... ..... ##### ..... ##### ..... .....",
	"_": "..... ..... ..... ..... ..... ..... #####",
	"[": ".###. .#... .#... .#... .#... .#... .###.",
	"]": ".###. ...#. ...#. ...#. ...#. ...#. .###.",
	"(": "...#. ..#.. .#... .#... .#... ..#.. ...#.",
	")": ".#... ..#.. ...#. ...#. ...#. ..#.. .#...",
	"\"": ".#.#. .#.#. ..... ..... ..... ..... .....",
}

static var _rows_cache: Dictionary = {}


static func text_width(text: String, scale: int = 1) -> int:
	if text.is_empty():
		return 0
	return (text.length() * ADVANCE - 1) * scale


static func text_height(scale: int = 1) -> int:
	return GLYPH_H * scale


## Draws [param text] with its top-left corner at [param pos]. A non-transparent
## [param shadow] adds a one-pixel (scaled) drop shadow.
static func draw_text(ci: CanvasItem, text: String, pos: Vector2, color: Color,
		scale: int = 1, shadow: Color = Color.TRANSPARENT) -> void:
	if shadow.a > 0.0:
		_draw_run(ci, text, pos + Vector2(scale, scale), shadow, scale)
	_draw_run(ci, text, pos, color, scale)


static func draw_text_centered(ci: CanvasItem, text: String, center_x: float, y: float,
		color: Color, scale: int = 1, shadow: Color = Color.TRANSPARENT) -> void:
	var x := floorf(center_x - text_width(text, scale) / 2.0)
	draw_text(ci, text, Vector2(x, y), color, scale, shadow)


## Splits [param text] into lines of at most [param max_chars], breaking at spaces.
static func wrap(text: String, max_chars: int) -> PackedStringArray:
	var lines := PackedStringArray()
	var line := ""
	for word in text.split(" ", false):
		while word.length() > max_chars:  # hard-break words that never fit
			if not line.is_empty():
				lines.append(line)
				line = ""
			lines.append(word.left(max_chars))
			word = word.substr(max_chars)
		if line.is_empty():
			line = word
		elif line.length() + 1 + word.length() <= max_chars:
			line += " " + word
		else:
			lines.append(line)
			line = word
	if not line.is_empty():
		lines.append(line)
	return lines


static func glyph_rows(ch: String) -> PackedStringArray:
	if not _rows_cache.has(ch):
		var src: String = GLYPHS.get(ch, GLYPHS["?"])
		_rows_cache[ch] = src.split(" ", false)
	return _rows_cache[ch]


static func _draw_run(ci: CanvasItem, text: String, pos: Vector2, color: Color, scale: int) -> void:
	var x := pos.x
	for ch in text.to_upper():
		if ch != " ":
			var rows := glyph_rows(ch)
			for r in rows.size():
				var row: String = rows[r]
				var c := 0
				# Merge horizontal runs of lit pixels into one rectangle each.
				while c < GLYPH_W:
					if row[c] == "#":
						var start := c
						while c < GLYPH_W and row[c] == "#":
							c += 1
						ci.draw_rect(Rect2(x + start * scale, pos.y + r * scale,
								(c - start) * scale, scale), color)
					else:
						c += 1
		x += ADVANCE * scale
