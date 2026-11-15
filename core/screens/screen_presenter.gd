class_name ScreenPresenter
extends TextureRect
## Shows one screen of a DualScene on a surface (the main window, or the desktop bottom window) and sends the
## touch input it receives into that screen's viewport. Same size as the screen, so positions map 1:1.
## Only touch is forwarded: a viewport outside a container has no hover, so mouse clicks would not reach buttons.
## On desktop the mouse emulates touch (project setting), on Android touch is native.

var _scene: DualScene
var _screen: DualScene.Screen = DualScene.Screen.TOP


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stretch_mode = TextureRect.STRETCH_KEEP
	mouse_filter = Control.MOUSE_FILTER_STOP


func show_screen(scene: DualScene, screen: DualScene.Screen) -> void:
	_scene = scene
	_screen = screen
	texture = scene.viewport(screen).get_texture() if scene != null else null


func shown_screen() -> DualScene.Screen:
	return _screen


func _gui_input(event: InputEvent) -> void:
	if _scene == null or not is_instance_valid(_scene):
		return
	if not (event is InputEventScreenTouch or event is InputEventScreenDrag):
		return
	# _gui_input positions are already local to this rect, which is the viewport's own space.
	_scene.viewport(_screen).push_input(event, true)
	_scene.request_redraw(_screen)
	accept_event()
