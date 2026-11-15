# Architecture

## Two screens, one scene

```
DualScene (VBoxContainer)              every screen scene inherits core/dual_scene/dual_scene.tscn
├── TopContainer (SubViewportContainer)
│   └── TopViewport (SubViewport)      top content
└── BottomContainer
    └── BottomViewport                 bottom content
```

Both viewports are `dual_screen/screen/base_size` (default 320x240), nearest filter, pixel snap.
Each has a redraw mode: `ALWAYS` or `ON_CHANGE` (one frame after input or `request_redraw()`).

## Screens autoload

`Screens` (`ScreensService`) owns the current `DualScene` and picks a mode at start:

| Mode | When | Top / bottom shown by |
|---|---|---|
| `SINGLE` | headless, web, phones, game embedded in the editor, `--screens=single` | the scene's own containers, stacked (window 320x480) |
| `DESKTOP` | desktop with native subwindows | `ScreenPresenter` in the main window + one in a second OS window |
| `ANDROID` | Android with the dual screen plugin and a second display | presenter on display 0 + `AndroidDisplay` on the second display |

In `DESKTOP` and `ANDROID` the containers hide (`set_external(true)`) and the viewports keep rendering.
A `ScreenPresenter` is a TextureRect of one viewport's texture, sized like the screen, that forwards touch into it.

Input:

- Touch: the surface it lands on decides the screen (container in `SINGLE`, presenter otherwise).
- Keys and gamepad: `Screens.push_keys()` sends them to both screens (containers do the same in `SINGLE`).
- `swap_screens` (Q, Select): `Screens.swap()`. Stacked: reorders the containers. Two surfaces: presenters trade screens.
- `dual_screen/screen/main_display_is_top` says whether the main surface (main window, display 0) is the top screen.

Scenes register themselves: `DualScene._ready()` calls `Screens.attach(self)`, so the main scene and F6 runs work
without going through `change_scene()`.

## Android second display

`addons/dual_screen_android/` hands `bin/*.aar` to Gradle exports. Source in `android/plugin/` (Kotlin), build with
`cd android/plugin && ./gradlew copyToAddon`.

- `DualScreenPlugin`: Godot singleton `DualScreenAndroid`. Opens a `Presentation` on the other display. It is
  `FLAG_NOT_FOCUSABLE`, so the gamepad stays with Godot. Touch there comes back as `second_touch` (base pixels).
- GL transport (default, `dual_screen/android/transport`): `AndroidDisplay` gives the plugin the GL id of the viewport's
  render target. In `onGLDrawFrame` (Godot's render thread) `GlBlitter` makes a window surface on the second display
  current with Godot's own EGL context, draws one quad (nearest, integer scale, letterbox), swaps, restores all GL state.
  ALWAYS screens draw every frame, ON_CHANGE screens only after `requestDraw()`.
- READBACK transport (fallback): `get_image()` after each redraw, bytes to a Bitmap. About twice the CPU.
- On the RG DS display 0 is the bottom screen, so `main_display_is_top=false`.

`tools/bench/bench.tscn`: 40 sprites per screen, T switches transport, R switches the bottom redraw mode, logs
`BENCH ...` lines (`adb logcat -s godot`).

## Tests

`tests/run_tests.gd` (headless, so always `SINGLE`). `tests/fixtures/dual_fixture.tscn` is a minimal DualScene.

## Not done yet (TODO)

- Home launcher, examples.
