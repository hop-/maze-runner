# Maze Runner

A small 8-bit maze game made with Godot 4. Guide **FFI**, a little green
square, through a randomly generated maze to the flag. The floor is
moonlight yellow and the walls are dark blue.

Everything is drawn and synthesised in code. The project has no image, font
or audio files.

## Menu

**NEW GAME** starts the selected mode. **MODE** picks TODDLER, KID or GROWNUP:
press Enter, click, or press left/right to cycle. The choice is remembered.
**SOUND** toggles the same way. **MY MAZE** appears when a maze file is loaded.

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

| Action            | Keyboard              | Gamepad (Xbox names)     | Touch screen              |
|-------------------|-----------------------|--------------------------|---------------------------|
| Move              | Arrow keys / WASD     | Left stick or d-pad      | Drag anywhere the way to go |
| Select / continue | Enter / Space         | A or Start               | Tap                       |
| New maze          | R                     | Y                        | Tap after a win           |
| Back to menu      | Esc / Backspace       | B                        | Tap `<` (top left), Android back |
| Sound on/off      | M                     | Back / View              | SOUND on the menu         |

You can also use the mouse on the menu. Holding a direction keeps FFI walking.
Other controllers (PlayStation, Switch, …) use the same button positions.

The stick and touch drag go the way they're pushed most. A diagonal push also
counts the weaker direction as a second choice, so FFI turns into a side
corridor without precise aiming.

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

## Building

Builds are driven by the `Makefile` and the presets in `export_presets.cfg`.
Everything is built on Linux: Windows, macOS, Android and iOS themselves aren't
needed, except a Mac for the final iOS step. Linux and Windows each produce a
single file with the game data embedded.

```bash
make templates          # once per Godot version: download export templates (~1 GB)
make desktop            # build/release/{linux/maze-runner, windows/maze-runner.exe, macos/maze-runner.zip}
make mobile             # build/release/{android/maze-runner.apk, ios/maze-runner.xcodeproj}
make linux              # or one platform: linux | windows | macos | android | ios
make all                # every platform in PLATFORMS (default: all five)
make dist               # also make archives to share, in build/release/
make dist PLATFORMS="linux windows macos"   # only some platforms
make all BUILD=debug    # debug builds (console + error output) in build/debug/
make help               # every target
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

**Android.** One-time setup: install JDK 17 (`sudo pacman -S jdk17-openjdk` on
Arch/Manjaro), then run `make android-setup`. It downloads the Android
command-line tools (checksum-verified) and installs platform-tools and
build-tools into `~/Android/Sdk`. It also creates the standard debug signing key
and points Godot's editor settings at Java and the SDK. Close the Godot editor
first, because it rewrites its settings file on exit.

```bash
make android BUILD=debug   # APK signed with the debug key: fine for your own phone
make android-install       # install it over USB (USB debugging on)
make android-keystore      # once: your own release key (keep it and its password safe)
make android               # release APK; needs the GODOT_ANDROID_KEYSTORE_RELEASE_* variables
```

The APK runs on 32- and 64-bit ARM phones in landscape. The Play Store wants an
AAB, which needs Godot's Gradle build; this setup makes APKs for sideloading.

**iOS.** Set your 10-character Apple Team ID in `export_presets.cfg`
(`application/app_store_team_id`); a free Apple ID's personal team works. Then
`make ios` exports an Xcode project to `build/release/ios/`, and `make dist`
zips it. Building, signing and installing the `.ipa` is done in Xcode on a Mac.
The bundle ID is `io.github.hop-.maze-runner`, and Android's package name is
`io.github.hop_.mazerunner` (Android doesn't allow hyphens).

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
export_presets.cfg   Linux, Windows, macOS, Android and iOS export presets
icon.svg             app icon: FFI on a 16-unit grid, so the exported icons stay sharp at every size
project.godot        320×180 viewport, integer-scaled to the window (pixel-perfect)
scenes/main.tscn     root scene → scripts/main.gd
scripts/
  main.gd            swaps between menu and game; reads --maze / --mode
  menu.gd            title screen: NEW GAME, MODE, SOUND (MenuScreen)
  dir_input.gd       keys, d-pad, stick and touch drag → maze directions (DirInput)
  game.gd            one play session: steering, clock, camera, win (GameScreen)
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
  settings.gd        autoload: input map, sound, chosen mode, best times
  sfx.gd             autoload: square-wave chiptune sound effects
tests/test_maze.gd   headless test runner
```

To tune difficulty, edit `scripts/modes.gd`. The tests check that TODDLER and
KID still fit on one screen.
