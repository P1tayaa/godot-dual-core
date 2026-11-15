class_name TestScreens
extends TestCase
## DualScene + Screens in the stacked (SINGLE) layout, and the presenter used by the two-surface layouts.

const FIXTURE: PackedScene = preload("res://tests/fixtures/dual_fixture.tscn")


func after_each() -> void:
	if Screens.swapped:
		Screens.swap()


func test_scene_attaches_with_base_size() -> void:
	var scene: DualScene = add_scene(FIXTURE) as DualScene
	await frames(1)
	eq(Screens.current, scene, "current scene")
	eq(Screens.mode, ScreensService.Mode.SINGLE, "headless mode")
	eq(scene.top_viewport.size, DualScene.base_size(), "top size")
	eq(scene.bottom_viewport.size, DualScene.base_size(), "bottom size")


func test_on_change_screen_redraws_on_request() -> void:
	var scene: DualScene = FIXTURE.instantiate() as DualScene
	scene.bottom_redraw = DualScene.Redraw.ON_CHANGE
	tree.root.add_child(scene)
	_nodes.append(scene)
	await frames(1)
	eq(scene.top_viewport.render_target_update_mode, SubViewport.UPDATE_ALWAYS, "top stays ALWAYS")
	scene.bottom_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	scene.request_redraw(DualScene.Screen.BOTTOM)
	eq(scene.bottom_viewport.render_target_update_mode, SubViewport.UPDATE_ONCE, "bottom redraws once")


func test_swap_action_reorders_stacked_screens() -> void:
	var scene: DualScene = add_scene(FIXTURE) as DualScene
	await frames(1)
	eq(scene.get_child(0), scene.top_container, "top first")
	await press(&"swap_screens")
	ok(Screens.swapped, "swapped after action")
	eq(scene.get_child(0), scene.bottom_container, "bottom first when swapped")
	eq(Screens.main_screen(), DualScene.Screen.BOTTOM, "main surface shows bottom")
	await press(&"swap_screens")
	eq(scene.get_child(0), scene.top_container, "top first again")


func test_presenter_sends_touch_to_its_screen() -> void:
	var scene: DualScene = add_scene(FIXTURE) as DualScene
	await frames(1)
	var button: Button = scene.get_node("%BottomButton") as Button
	var pressed: Array[bool] = [false]
	button.pressed.connect(func() -> void: pressed[0] = true)
	var presenter: ScreenPresenter = ScreenPresenter.new()
	tree.root.add_child(presenter)
	_nodes.append(presenter)
	presenter.show_screen(scene, DualScene.Screen.BOTTOM)
	eq(presenter.texture, scene.bottom_viewport.get_texture(), "presenter shows bottom texture")
	for down: bool in [true, false]:
		var touch: InputEventScreenTouch = InputEventScreenTouch.new()
		touch.pressed = down
		touch.position = Vector2(20, 20)
		presenter._gui_input(touch)
		await frames(1)
	ok(pressed[0], "bottom button pressed through presenter")
