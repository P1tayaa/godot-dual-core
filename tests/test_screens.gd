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
	eq(scene.top_viewport.size, Screens.screen_size(DualScene.Screen.TOP), "top size")
	eq(scene.bottom_viewport.size, Screens.screen_size(DualScene.Screen.BOTTOM), "bottom size")


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


func test_external_screens_keep_rendering() -> void:
	var scene: DualScene = FIXTURE.instantiate() as DualScene
	scene.bottom_redraw = DualScene.Redraw.ON_CHANGE
	tree.root.add_child(scene)
	_nodes.append(scene)
	await frames(1)
	scene.set_external(true)
	eq(scene.top_viewport.render_target_update_mode, SubViewport.UPDATE_ALWAYS, "top still ALWAYS when hidden")
	eq(scene.bottom_viewport.render_target_update_mode, SubViewport.UPDATE_ONCE, "bottom redraws once when hidden")
	eq(scene.mouse_filter, Control.MOUSE_FILTER_IGNORE, "scene lets touch through to presenters")
	scene.set_external(false)


func test_swap_action_reorders_stacked_screens() -> void:
	var scene: DualScene = add_scene(FIXTURE) as DualScene
	await frames(1)
	eq(scene.get_child(0), scene.top_container, "top first")
	var main_before: DualScene.Screen = Screens.main_screen()
	await press(&"swap_screens")
	ok(Screens.swapped, "swapped after action")
	eq(scene.get_child(0), scene.bottom_container, "bottom first when swapped")
	ok(Screens.main_screen() != main_before, "main surface shows the other screen")
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
		# The texture is centred in the presenter: aim 20 px into it.
		touch.position = (presenter.size - Vector2(scene.bottom_viewport.size)) / 2.0 + Vector2(20, 20)
		presenter._gui_input(touch)
		await frames(1)
	ok(pressed[0], "bottom button pressed through presenter")


func test_presenter_touch_with_pixel_scale() -> void:
	var scene: DualScene = FIXTURE.instantiate() as DualScene
	scene.pixel_scale = 2
	tree.root.add_child(scene)
	_nodes.append(scene)
	await frames(1)
	scene.set_external(true) # what DESKTOP / ANDROID do: viewports at 2x
	eq(scene.bottom_viewport.size, Screens.screen_size(DualScene.Screen.BOTTOM) * 2, "bottom renders at 2x")
	var button: Button = scene.get_node("%BottomButton") as Button
	var pressed: Array[bool] = [false]
	button.pressed.connect(func() -> void: pressed[0] = true)
	var presenter: ScreenPresenter = ScreenPresenter.new()
	tree.root.add_child(presenter)
	_nodes.append(presenter)
	presenter.show_screen(scene, DualScene.Screen.BOTTOM)
	for down: bool in [true, false]:
		var touch: InputEventScreenTouch = InputEventScreenTouch.new()
		touch.pressed = down
		# Base (50, 30) is on the button = texture (100, 60) at pixel_scale 2; unconverted, (100, 60) would miss it.
		touch.position = (presenter.size - Vector2(scene.bottom_viewport.size)) / 2.0 + Vector2(100, 60)
		presenter._gui_input(touch)
		await frames(1)
	ok(pressed[0], "button at base coordinates pressed through a 2x presenter")
	scene.set_external(false)


func test_stacked_touch_with_pixel_scale() -> void:
	var scene: DualScene = FIXTURE.instantiate() as DualScene
	scene.pixel_scale = 2
	tree.root.add_child(scene)
	_nodes.append(scene)
	await frames(2)
	eq(scene.bottom_viewport.size, Screens.screen_size(DualScene.Screen.BOTTOM) * 2, "stacked bottom renders at 2x")
	var button: Button = scene.get_node("%BottomButton") as Button
	var pressed: Array[bool] = [false]
	button.pressed.connect(func() -> void: pressed[0] = true)
	# Through the real container path: base (50, 30) on the button = (100, 60) into the 2x container.
	var at: Vector2 = scene.bottom_container.get_global_rect().position + Vector2(100, 60)
	for down: bool in [true, false]:
		var touch: InputEventScreenTouch = InputEventScreenTouch.new()
		touch.pressed = down
		touch.position = at
		Input.parse_input_event(touch)
		await frames(1)
	ok(pressed[0], "button at base coordinates pressed through a 2x stacked container")
