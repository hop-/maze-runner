# Maze Runner

A small 8-bit maze game made with Godot 4. Guide **FFI**, a little green
square, through a randomly generated maze to the flag. The floor is
moonlight yellow and the walls are dark blue.

Everything is drawn and synthesised in code. The project has no image, font
or audio files.

## Modes

| Mode    | Maze (cells) | Loops | Exit                  | View            | Trail |
|---------|--------------|-------|-----------------------|-----------------|-------|
| TODDLER | 7 × 4        | many  | bottom-right corner   | whole maze      | yes   |
| KID     | 15 × 8       | some  | bottom-right corner   | whole maze      | yes   |
| GROWNUP | 30 × 20      | none  | farthest cell from start | camera follows FFI | no |

In the scrolling modes, a red arrow at the screen edge points toward the flag
whenever it is off screen.

Each finished maze shows your time, your moves, and the shortest possible
number of moves. The best time for each mode is saved.

## Controls

| Action            | Keyboard              | Gamepad   |
|-------------------|-----------------------|-----------|
| Move              | Arrow keys / WASD     | D-pad     |
| Select / continue | Enter / Space         | A         |
| New maze          | R                     | Y         |
| Back to menu      | Esc / Backspace       | B         |
| Sound on/off      | M                     | Back      |

You can also use the mouse on the menu. Holding a direction keeps FFI walking.

## Running

You need Godot 4.7 or newer (standard build, not .NET).

```bash
godot --path .                    # play (or: make run)
godot --path . --mode=grownup     # skip the menu (toddler | kid | grownup)
godot --path . --maze=maze.txt    # play a maze from a text file
godot --editor --path .           # open in the editor (or: make edit)
```

The exported game takes the same flags: `./maze-runner --maze=maze.txt`.

## Maze files

`--maze=FILE` (or `--maze FILE`) plays a maze from a text file. Each tile is
two characters:

| Text | Tile   |
|------|--------|
| `[]` | wall   |
| `  ` | path (two spaces) |
| `M>` | start  |
| `>M` | finish |

```
[][][][][][][]
[]M>      [][]
[]  [][]    []
[]      []>M[]
[][][][][][][]
```

- A maze can be any size and shape. Lines can have different lengths; missing
  tiles count as wall, and so does everything outside the file.
- It needs exactly one `M>` and one `>M`, and the finish must be reachable.
  Otherwise the game prints the problem to stderr and shows it on the menu.
- A file maze shows up on the menu as **MY MAZE**. **R** reloads the file, so
  you can edit it and press R to try the change.
- Tiles are 16 px if the maze fits on screen at that size, otherwise 9 px with a
  scrolling camera. Only the visible tiles are drawn, so big mazes stay smooth.
  A 1001×1001-tile maze takes about 2 s to load.
- Relative paths are resolved from the folder you ran the command in.
- Best times are not saved for maze files.

## Building (Linux / Windows / macOS)

Builds are driven by the `Makefile` and the presets in `export_presets.cfg`.
All three platforms build on Linux; Windows and macOS themselves aren't needed.
Linux and Windows each produce a single file with the game data embedded.

```bash
make templates        # once per Godot version: download export templates (~1 GB)
make all              # build/release/{linux/maze-runner, windows/maze-runner.exe, macos/maze-runner.zip}
make linux            # or one platform: linux | windows | macos
make dist             # also make .tar.gz / .zip archives to share
make all BUILD=debug  # debug builds (console + error output) in build/debug/
make help             # every target
```

The export templates must match `godot --version` exactly. You can also install
them from the editor: **Editor → Manage Export Templates**. Set `GODOT=/path/to/godot`
to use a different Godot binary.

**macOS notes.** The build is a `.zip` containing `Maze Runner.app`, a universal
binary for both Intel and Apple Silicon Macs. It has a basic (ad-hoc) signature
from Godot and is not notarized, because that needs a paid Apple Developer ID.
Gatekeeper blocks it the first time it's opened after being downloaded. Players
can allow it in **System Settings → Privacy & Security → Open Anyway**, or run
`xattr -dr com.apple.quarantine "Maze Runner.app"`. `.dmg` images can only be made
on a Mac. The bundle ID is `io.github.hop-.maze-runner`; change it in
`export_presets.cfg`.

## Tests

```bash
make test
```

The tests check that mazes are fully connected, that perfect mazes have no
loops, and that braiding removes dead ends. They also check that seeds are
deterministic, that each mode fits its screen, and that every font glyph is 5×7.

## Layout

```
Makefile             run / test / export / package targets
export_presets.cfg   Linux, Windows (x86_64) and macOS (universal) export presets
icon.svg             app icon: FFI on a 16-unit grid, so the exported icons stay sharp at every size
project.godot        320×180 viewport, integer-scaled to the window (pixel-perfect)
scenes/main.tscn     root scene → scripts/main.gd
scripts/
  main.gd            swaps between menu and game; reads --maze / --mode
  menu.gd            title screen (MenuScreen)
  game.gd            one play session: input, clock, camera, win (GameScreen)
  maze.gd            maze generation, text maze files, BFS (Maze)
  modes.gd           difficulty settings (Modes)
  maze_view.gd       draws floor and walls (MazeView)
  maze_markers.gd    breadcrumb trail and exit flag (MazeMarkers)
  exit_pointer.gd    edge arrow toward an off-screen flag (ExitPointer)
  player.gd          FFI: movement, facing, blink, wall bump (Player)
  hud.gd             top status bar (Hud)
  win_overlay.gd     win panel with confetti (WinOverlay)
  palette.gd         the 8-bit color palette (Palette)
  pixel_font.gd      5×7 bitmap font drawn with rectangles (PixelFont)
  sprites.gd         pixel-art sprites as character grids (Sprites)
  settings.gd        autoload: input map, sound toggle, best times
  sfx.gd             autoload: square-wave chiptune sound effects
tests/test_maze.gd   headless test runner
```

To tune difficulty, edit `scripts/modes.gd`. The tests check that TODDLER and
KID still fit on one screen.
