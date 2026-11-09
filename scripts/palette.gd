class_name Palette
extends RefCounted
## The game's limited 8-bit color palette. Every screen draws with these.

const NIGHT := Color("0e1330")        # sky, letterbox, panels
const NIGHT_LIGHT := Color("1c2550")
const STAR := Color("c8d0ff")

const MOON := Color("f6eaa6")         # moonlight-yellow maze floor
const MOON_SHADE := Color("dccb7e")   # shadow cast by walls, floor specks
const MOON_DEEP := Color("bfae62")    # moon craters

const WALL := Color("2b3a73")         # dark bluish walls
const WALL_LIGHT := Color("41579c")
const WALL_DARK := Color("1a2350")

const FFI_DARK := Color("1b6b2a")     # FFI, the green square
const FFI := Color("4cc24c")
const FFI_LIGHT := Color("9ae87f")

const WHITE := Color("fcfcfc")
const BLACK := Color("101010")
const RED := Color("d83a3a")
const POLE := Color("5a3a1e")
const TRAIL := Color("b5cc66")

const CONFETTI: Array[Color] = [MOON, FFI, FFI_LIGHT, RED, WHITE, WALL_LIGHT]
