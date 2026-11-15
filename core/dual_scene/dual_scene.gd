class_name DualScene
extends VBoxContainer
## Base of every screen scene: a top and a bottom SubViewport, stacked like a DS in the editor and with F6.
## Put top content under %TopViewport and bottom content under %BottomViewport. `Screens` decides where each one
## is shown (stacked in one window, two desktop windows, or the two displays of a handheld).

enum Screen { TOP, BOTTOM }
## ALWAYS redraws every frame. ON_CHANGE redraws only after input or `request_redraw()`: a static screen costs nothing.
enum Redraw { ALWAYS, ON_CHANGE }

@export var top_redraw: Redraw = Redraw.ALWAYS
@export var bottom_redraw: Redraw = Redraw.ALWAYS

@onready var top_container: SubViewportContainer = %TopContainer
@onready var bottom_container: SubViewportContainer = %BottomContainer
@onready var top_viewport: SubViewport = %TopViewport
@onready var bottom_viewport: SubViewport = %BottomViewport


## Size of one screen in game pixels, from the `dual_screen/screen/base_size` project setting.
static func base_size() -> Vector2i:
	return ProjectSettings.get_setting("dual_screen/screen/base_size", Vector2i(320, 240))


func _ready() -> void:
	var base: Vector2i = DualScene.base_size()
	top_container.custom_minimum_size = Vector2(base)
	bottom_container.custom_minimum_size = Vector2(base)
	top_viewport.size = base
	bottom_viewport.size = base
	top_viewport.render_target_update_mode = _update_mode(top_redraw)
	bottom_viewport.render_target_update_mode = _update_mode(bottom_redraw)
	Screens.attach(self)


func viewport(screen: Screen) -> SubViewport:
	return top_viewport if screen == Screen.TOP else bottom_viewport


func redraw_mode(screen: Screen) -> Redraw:
	return top_redraw if screen == Screen.TOP else bottom_redraw


## Draws one more frame of an ON_CHANGE screen. Call it after changing that screen from code (tween, timer, data).
func request_redraw(screen: Screen) -> void:
	if redraw_mode(screen) == Redraw.ON_CHANGE:
		viewport(screen).render_target_update_mode = SubViewport.UPDATE_ONCE


## Stacked layout only: puts the bottom screen first when swapped.
func set_stacked_order(swapped: bool) -> void:
	move_child(bottom_container, 0 if swapped else 1)


## True when the screens are shown elsewhere (two windows, two displays): the containers hide, the viewports keep
## rendering by their own update mode.
func set_external(external: bool) -> void:
	top_container.visible = not external
	bottom_container.visible = not external


func _input(event: InputEvent) -> void:
	# Stacked layout: the containers forward input themselves, ON_CHANGE screens just need one more frame.
	if event is InputEventMouseMotion and (event as InputEventMouseMotion).button_mask == 0:
		return
	request_redraw(Screen.TOP)
	request_redraw(Screen.BOTTOM)


func _update_mode(mode: Redraw) -> SubViewport.UpdateMode:
	return SubViewport.UPDATE_ALWAYS if mode == Redraw.ALWAYS else SubViewport.UPDATE_ONCE
