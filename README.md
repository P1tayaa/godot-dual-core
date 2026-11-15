# Godot Dual Core

Starting point for dual-screen tools and games in Godot 4.7: one scene, two screens, on dual-screen Android handhelds
(Anbernic RG DS, AYN Thor), on desktop (two windows) and stacked in one window everywhere else.

The core is the `addons/dual_screen` submodule (repo `godot-dual-screen`); this project holds the examples and tests.
Clone with `git clone --recurse-submodules`, or run `git submodule update --init` after cloning.

Read `addons/dual_screen/docs/PHILOSOPHY.md`, `addons/dual_screen/docs/CONVENTIONS.md` and `docs/ARCHITECTURE.md`
first. Decisions and measurements are in `docs/DECISIONS.md`. New game on the core: `docs/NEW_GAME.md`.

## Requirements

- Godot 4.7.2 at `$GODOT_PATH`, with the export templates (Android ones for device builds).
- For Android: Android SDK (`~/Android/Sdk`), JDK 21, Godot editor settings with the Java SDK path and debug keystore.

## Run

```bash
"$GODOT_PATH" --path .                          # desktop: two windows (top + bottom)
"$GODOT_PATH" --path . -- --screens=single      # stacked in one window
"$GODOT_PATH" -e --path .                       # editor
```

Keys: arrows / Z / X for menus, Q (Select) swaps the screens, H (Start) goes back to the launcher.

## Tests

```bash
"$GODOT_PATH" --headless --path . --import                            # after adding a class_name or a CSV key
"$GODOT_PATH" --headless --path . --script res://addons/dual_screen/testing/run_tests.gd   # all tests
```

## Android build

```bash
(cd addons/dual_screen/android/plugin_src && ./gradlew copyToAddon)   # only after changing the Kotlin plugin
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk ANDROID_HOME=~/Android/Sdk
"$GODOT_PATH" --headless --path . --export-debug "Android" exports/dual-core.apk
adb install -r exports/dual-core.apk
adb logcat -s godot DualScreen                                        # logs
adb exec-out screencap -d 0 -p > bottom.png                           # screenshot one display
```

## Add a device

Copy `addons/dual_screen/profiles/devices/rg_ds.tres`, fill in both screens (pixels, millimetres, base size), the gap, which display the
app starts on and the model name `OS.get_model_name()` reports. Then fine-tune gap and offset on the device in
Device settings and save.

## Examples

The launcher lists them (see the table in `docs/ARCHITECTURE.md`). Each lives in its own folder under `examples/`.

## TODO

- AYN Thor profile values are from memory, not checked on a device.
- Measure the real RG DS hinge gap (22 mm is an estimate) and put it in `addons/dual_screen/profiles/devices/rg_ds.tres`.
- Potion brewing minigame.
- Games on the addon: `hanzi-cards` and `dm-dice` (own repos).
