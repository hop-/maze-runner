class_name Hud
extends Node2D
## Top status bar: mode, elapsed time and number of moves.

const HEIGHT := 12
const WIDTH := 320

var mode_name := ""
var time_text := "0:00.0"
var moves := 0


func set_values(p_time_text: String, p_moves: int) -> void:
	if p_time_text != time_text or p_moves != moves:
		time_text = p_time_text
		moves = p_moves
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, WIDTH, HEIGHT), Palette.NIGHT)
	draw_rect(Rect2(0, HEIGHT - 1, WIDTH, 1), Palette.WALL)
	PixelFont.draw_text(self, mode_name, Vector2(4, 2), Palette.FFI_LIGHT)
	PixelFont.draw_text_centered(self, "TIME " + time_text, WIDTH / 2.0, 2, Palette.MOON)
	var moves_text := "MOVES %d" % moves
	PixelFont.draw_text(self, moves_text, Vector2(WIDTH - 4 - PixelFont.text_width(moves_text), 2), Palette.MOON)
