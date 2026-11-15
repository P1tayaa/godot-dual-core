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
| `ANDROID` | Android with the dual screen plugin | display 0 + the plugin on the second display (TODO) |

In `DESKTOP` and `ANDROID` the containers hide (`set_external(true)`) and the viewports keep rendering.
A `ScreenPresenter` is a TextureRect of one viewport's texture, sized like the screen, that forwards touch into it.

Input:

- Touch: the surface it lands on decides the screen (container in `SINGLE`, presenter otherwise).
- Keys and gamepad: `Screens.push_keys()` sends them to both screens (containers do the same in `SINGLE`).
- `swap_screens` (Q, Select): `Screens.swap()`. Stacked: reorders the containers. Two surfaces: presenters trade screens.
- `dual_screen/screen/main_display_is_top` says whether the main surface (main window, display 0) is the top screen.

Scenes register themselves: `DualScene._ready()` calls `Screens.attach(self)`, so the main scene and F6 runs work
without going through `change_scene()`.

## Tests

`tests/run_tests.gd` (headless, so always `SINGLE`). `tests/fixtures/dual_fixture.tscn` is a minimal DualScene.

## Not done yet (TODO)

- `ANDROID` mode: plugin, second display, touch from display 2.
- Home launcher, examples.
