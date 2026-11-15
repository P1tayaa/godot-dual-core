class_name ScreensService
extends Node
## Autoload "Screens". Owns the current DualScene and decides where its two screens appear:
## SINGLE   both stacked in one window (phones, web, editor-embedded game, headless tests)
## DESKTOP  two OS windows
## ANDROID  display 0 + the second display through the Android plugin
## Also: screen swap, and routing keys/gamepad to both screens when they are shown outside their containers.

signal scene_changed(scene: DualScene)
signal swapped_changed(swapped: bool)

enum Mode { SINGLE, DESKTOP, ANDROID }

var mode: Mode = Mode.SINGLE
var current: DualScene
var swapped: bool = false

var _main_presenter: ScreenPresenter
var _second_window: Window
var _second_presenter: ScreenPresenter


func _ready() -> void:
	mode = _pick_mode()
	if mode == Mode.SINGLE:
		return
	var base: Vector2i = DualScene.base_size()
	var window: Window = get_window()
	window.content_scale_size = base
	window.size = base * 2
	_main_presenter = ScreenPresenter.new()
	add_child(_main_presenter)
	if mode == Mode.DESKTOP:
		_open_desktop_window(base)


## Frees the current scene and shows the one at `path`.
func change_scene(path: String) -> void:
	var packed: PackedScene = load(path)
	var scene: DualScene = packed.instantiate() as DualScene
	get_tree().root.add_child(scene) # its _ready calls attach()


## Called by every DualScene in _ready, so the main scene and F6 runs are picked up too.
func attach(scene: DualScene) -> void:
	if current == scene:
		return
	if current != null and is_instance_valid(current):
		current.queue_free()
	current = scene
	scene.tree_exiting.connect(_on_scene_exiting.bind(scene))
	scene.set_external(mode != Mode.SINGLE)
	_apply_layout()
	scene_changed.emit(scene)


func swap() -> void:
	swapped = not swapped
	_apply_layout()
	swapped_changed.emit(swapped)


## Which screen the main surface (main window, display 0) shows right now.
func main_screen() -> DualScene.Screen:
	var main_is_top: bool = ProjectSettings.get_setting("dual_screen/screen/main_display_is_top", true)
	return DualScene.Screen.TOP if main_is_top != swapped else DualScene.Screen.BOTTOM


func _input(event: InputEvent) -> void:
	if _handle_swap(event):
		get_viewport().set_input_as_handled()
		return
	if mode != Mode.SINGLE:
		push_keys(event)


## Sends non-pointer input (keys, gamepad, actions) to both screens. Pointer input goes through the presenters.
func push_keys(event: InputEvent) -> void:
	if current == null or event is InputEventMouse or event is InputEventScreenTouch or event is InputEventScreenDrag:
		return
	for screen: DualScene.Screen in [DualScene.Screen.TOP, DualScene.Screen.BOTTOM]:
		current.viewport(screen).push_input(event)
		current.request_redraw(screen)


func _handle_swap(event: InputEvent) -> bool:
	if event.is_action_pressed("swap_screens") and not event.is_echo():
		swap()
		return true
	return false


func _apply_layout() -> void:
	if current == null:
		return
	if mode == Mode.SINGLE:
		current.set_stacked_order(swapped)
		return
	var on_main: DualScene.Screen = main_screen()
	var on_second: DualScene.Screen = DualScene.Screen.BOTTOM if on_main == DualScene.Screen.TOP else DualScene.Screen.TOP
	_main_presenter.show_screen(current, on_main)
	if _second_presenter != null:
		_second_presenter.show_screen(current, on_second)


func _on_scene_exiting(scene: DualScene) -> void:
	if current != scene:
		return
	current = null
	if _main_presenter != null:
		_main_presenter.show_screen(null, DualScene.Screen.TOP)
	if _second_presenter != null:
		_second_presenter.show_screen(null, DualScene.Screen.BOTTOM)


func _pick_mode() -> Mode:
	var setting: String = ProjectSettings.get_setting("dual_screen/screen/mode", "auto")
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--screens="):
			setting = arg.trim_prefix("--screens=")
	match setting:
		"single":
			return Mode.SINGLE
		"desktop":
			return Mode.DESKTOP
	# auto (ANDROID comes with the plugin)
	if Engine.is_embedded_in_editor():
		return Mode.SINGLE
	if DisplayServer.has_feature(DisplayServer.FEATURE_SUBWINDOWS) and OS.get_name() != "Android":
		return Mode.DESKTOP
	return Mode.SINGLE


func _open_desktop_window(base: Vector2i) -> void:
	_second_window = Window.new()
	_second_window.title = "%s (2)" % ProjectSettings.get_setting("application/config/name", "")
	_second_window.visible = false # force_native can only change on a hidden window
	_second_window.force_native = true
	_second_window.size = base * 2
	_second_window.content_scale_size = base
	_second_window.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	_second_window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	_second_window.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_INTEGER
	_second_window.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	_second_window.position = get_window().position + Vector2i(0, base.y * 2 + 40)
	_second_window.close_requested.connect(get_tree().quit)
	# Keys pressed while the second window has focus still reach both screens.
	_second_window.window_input.connect(_on_second_window_input)
	add_child(_second_window)
	_second_presenter = ScreenPresenter.new()
	_second_window.add_child(_second_presenter)
	_second_window.show()


func _on_second_window_input(event: InputEvent) -> void:
	if not _handle_swap(event):
		push_keys(event)
