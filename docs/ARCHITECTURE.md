# Architecture

The core lives in the `addons/dual_screen` submodule (repo `godot-dual-screen`). This project is its examples and
tests. Paths below are relative to this project.

## Two screens, one scene

```
DualScene (VBoxContainer)              every screen scene inherits addons/dual_screen/dual_scene/dual_scene.tscn
├── TopContainer (SubViewportContainer)
│   └── TopViewport (SubViewport)      top content
└── BottomContainer
    └── BottomViewport                 bottom content
```

Each viewport takes its size from the device profile (`Screens.screen_size(screen)`), nearest filter, pixel snap.
Each has a redraw mode: `ALWAYS` or `ON_CHANGE` (one frame after input or `request_redraw()`).
`pixel_scale` (1-4) renders both viewports at that multiple outside the stacked layout, with `size_2d_override` keeping
the scene's coordinates at base size. `Screens` sizes the windows to match, presenters and the Android display scale
touch back to base coordinates (`ScreenPresenter._to_scene_space`).

## Device profiles

`DeviceProfile` (`addons/dual_screen/profiles/device_profile.gd`, presets in `addons/dual_screen/profiles/devices/`) describes a device:

| Field | What |
|---|---|
| `top`, `bottom` (`ScreenSpec`) | panel pixels, visible size in mm, game base size (scaled by an integer to the panel) |
| `gap_mm` | lower edge of the top screen to upper edge of the bottom screen, device opened flat |
| `offset_mm` | horizontal shift of the top screen's centre |
| `main_display_is_top` | Android: is the display the app starts on the top screen |
| `model_names` | `OS.get_model_name()` values that select it automatically |

`Screens` picks: saved choice in `user://dual_screen.cfg`, else model name match, else
`dual_screen/default_profile`. `addons/dual_screen/settings/device_settings.tscn` switches profile and calibrates gap and
offset live (`Screens.set_layout()`, `Screens.save_profile()`).

Desk coordinates (`DeviceProfile.rect_mm()`): millimetres, origin at the bottom screen's top-left corner, y down. The
top screen sits above, `gap_mm` higher, centred plus `offset_mm`.

## Physical world

`DualScene.use_physical_world_2d()`: the bottom viewport takes the top viewport's World2D (one canvas, one physics
space) and each viewport gets a Camera2D placed on its screen's `rect_mm`, zoomed to that screen's pixels per mm.
World units are millimetres. Objects crossing between screens spend real time in the gap. Per-screen UI goes in a
CanvasLayer (drawn only by its own viewport). `screen_to_world()` turns a touch into world mm. Cameras move on
`Screens.layout_changed`. `WorldGrid` draws the mm grid, screen outlines and calibration diagonals.

For 3D, a viewport with `own_world_3d` keeps its world internal: share it with
`other.world_3d = viewport.find_world_3d()` (the `world_3d` property is null there).

## Screens autoload

`Screens` (`ScreensService`) owns the current `DualScene` and the profile, and picks a mode at start:

| Mode | When | Top / bottom shown by |
|---|---|---|
| `SINGLE` | headless, web, phones, game embedded in the editor, `--screens=single` | the scene's own containers, stacked and centred |
| `DESKTOP` | desktop with native subwindows | `ScreenPresenter` in the main window (top) + one in a second OS window |
| `ANDROID` | Android with the plugin and a second display | presenter on the app's display + `AndroidDisplay` on the other |

In `DESKTOP` and `ANDROID` the containers hide (`set_external(true)`), the viewports keep rendering, and the scene
root ignores pointer input so touch reaches the presenters. Each surface keeps the size of the screen it shows
unswapped; after a swap on a device with two screen sizes the content is letterboxed.

Input:

- Touch: the surface it lands on decides the screen (container in `SINGLE`, presenter or plugin otherwise).
  Pointer input is touch only, the mouse emulates touch on desktop.
- Keys and gamepad: `Screens.push_keys()` sends them to both screens (containers do the same in `SINGLE`).
- `swap_screens` (Q, Select): swap. `home` (H, Start): back to the launcher (`dual_screen/home_scene`).

Scenes register themselves: `DualScene._ready()` calls `Screens.attach(self)`, so the main scene and F6 runs work
without going through `change_scene()`.

## Android second display

`addons/dual_screen/android/` hands `bin/*.aar` to Gradle exports. Source in `android/plugin_src/` (Kotlin), build
with `cd addons/dual_screen/android/plugin_src && ./gradlew copyToAddon`.

- `DualScreenPlugin`: Godot singleton `DualScreenAndroid`. Opens a `Presentation` on the other display. It is
  `FLAG_NOT_FOCUSABLE`, so the gamepad stays with Godot. Touch there comes back as `second_touch` (base pixels).
- GL transport (default, `dual_screen/android/transport`): `AndroidDisplay` gives the plugin the GL id of the viewport's
  render target. In `onGLDrawFrame` (Godot's render thread) `GlBlitter` makes a window surface on the second display
  current with Godot's own EGL context, draws one quad (nearest, integer scale, letterbox), swaps, restores all GL state.
  ALWAYS screens draw every frame, ON_CHANGE screens only after `requestDraw()`.
- READBACK transport (fallback): `get_image()` after each redraw, bytes to a Bitmap. About twice the CPU.

## Launcher and examples

`scenes/home/` lists every `ExampleEntry` in `data/examples/` (title and description keys, category, scene, order).
Each example is one folder in `examples/`:

| Example | Shows |
|---|---|
| `hanzi_cards` | flash cards: tap to turn, flick up across the hinge = known, down = again; Leitner boxes, saved |
| `hello_dual` | the smallest DualScene, no script |
| `input_test` | touch dots on both screens, gamepad, accelerometer / gyroscope / gravity, vibration |
| `throw_gap` | physical world: flick a ball across the real hinge gap, peak height and crossing time |
| `dice_3d` | 3D physics dice on top, flick / A / shake on the bottom, top redraws only while dice move |
| `scene_3d` | 3D stress: object count, nodes vs MultiMesh, shadows, draw calls |
| `hunter` | first person 3D on top, 2D radar aim pad on the bottom (Metroid Prime Hunters layout) |
| `two_cameras` | one World3D, chase camera on top, orthographic map on the bottom, tap to move |
| `shader_stress` | fragment shader per screen, iterations per screen |
| `sprite_stress` | sprites on both screens, second screen transport and redraw mode switches |

## Tools

| Tool | What |
|---|---|
| `tools/make_hanzi_deck.gd` | `data/hanzi/*.tsv` to `.tres` decks |
| `tools/subset_fonts.py` | cuts the CJK fonts to the decks' characters (`uv run --with fonttools --with brotli`) |
| `addons/dual_screen/tools/screenshot.gd` | renders a scene in the stacked layout to PNG (needs a display): `--scene= --out= --frames= --press=` |

## Tests

`addons/dual_screen/testing/run_tests.gd` (headless, so always `SINGLE`). `tests/fixtures/dual_fixture.tscn` is a minimal DualScene.
`test_examples.gd` opens every launcher entry and fails on any engine or script error.
