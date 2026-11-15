# Starting a new game on the core

Games do not fork this project: they add the addon as a git submodule.

```bash
mkdir ~/Projects/my-game && cd ~/Projects/my-game && git init
git submodule add <godot-dual-screen url> addons/dual_screen
```

1. Create the Godot project (Godot 4.7, Compatibility renderer), enable the Dual Screen plugin. It adds the `Screens`
   autoload, the input actions, translations and the settings the core needs.
2. Set `dual_screen/home_scene` and `run/main_scene` to your first scene (it inherits
   `res://addons/dual_screen/dual_scene/dual_scene.tscn`).
3. Copy `export_presets.cfg` from this project and change `package/unique_name` and `package/name`.
4. Tests: `tests/test_*.gd` extending `TestCase`, run with
   `$GODOT_PATH --headless --path . --script res://addons/dual_screen/testing/run_tests.gd`.
5. Follow `addons/dual_screen/docs/PHILOSOPHY.md` and `CONVENTIONS.md`.

Fixing the core from inside a game: commit in `addons/dual_screen`, push to the addon repo, then commit the new
submodule pointer in the game. Other games pick it up with `git submodule update --remote addons/dual_screen`.

Local setup note: while the addon repo only lives on disk, its `.gitmodules` URL is a local path and git needs
`-c protocol.file.allow=always` for submodule commands. Switch to the GitHub URL once pushed:
`git submodule set-url addons/dual_screen git@github.com:P1tayaa/godot-dual-screen.git`.
