# Forking the core

Every tool or game is a clone of this repo that keeps the core as a remote, so core fixes can be merged later.

```bash
git clone ~/Projects/godot-dual-core ~/Projects/my-tool
cd ~/Projects/my-tool
git remote rename origin upstream
# later, to take core fixes:
git fetch upstream && git merge upstream/master
```

In the new project:

1. `project.godot`: change `application/config/name`, `run/main_scene` and `dual_screen/home_scene`.
2. `export_presets.cfg`: change `package/unique_name` and `package/name`.
3. Delete the examples you do not need (`examples/<name>/` and `data/examples/<name>.tres`) or keep them as
   reference. Their strings in `i18n/strings.csv` can go too.
4. Put the project's own scenes in `scenes/<name>/`, data in `data/schema/` and `data/rules/`, as in the core.

Keep core files (`autoload/`, `core/`, `addons/`, `android/`, `tests/run_tests.gd`) unchanged in the fork where you
can; fix them in the core and merge, so every project gets the fix.
