class_name TestThrowGap
extends TestCase
## The ball flicked up from the bottom screen must cross the gap and reach the top screen.

const SCENE: PackedScene = preload("res://examples/throw_gap/throw_gap.tscn")


func test_flick_up_reaches_top_screen() -> void:
	var scene: ThrowGap = add_scene(SCENE) as ThrowGap
	await physics_frames(5)
	var ball: RigidBody2D = scene._ball
	var bottom_vp: SubViewport = scene.bottom_viewport
	# Ball position in bottom-screen pixels, then an upward flick of 60 px per physics frame (~900 mm/s on the RG DS,
	# a normal finger flick).
	var start_px: Vector2 = bottom_vp.get_canvas_transform() * ball.global_position
	var area: Control = scene.get_node("%BottomTouch") as Control
	var down: InputEventScreenTouch = InputEventScreenTouch.new()
	down.pressed = true
	down.position = start_px
	area.gui_input.emit(down)
	for i: int in 4:
		await physics_frames(1)
		var drag: InputEventScreenDrag = InputEventScreenDrag.new()
		drag.position = start_px + Vector2(0, -60.0 * (i + 1))
		area.gui_input.emit(drag)
	var up: InputEventScreenTouch = InputEventScreenTouch.new()
	up.pressed = false
	up.position = start_px + Vector2(0, -240.0)
	area.gui_input.emit(up)
	await physics_frames(1)
	ok(ball.linear_velocity.y < -200.0, "flick gives upward speed (got %s)" % ball.linear_velocity)
	var top_bottom_edge: float = -Screens.profile.gap_mm
	var reached: bool = false
	for i: int in 120:
		await physics_frames(1)
		if ball.global_position.y < top_bottom_edge:
			reached = true
			break
	ok(reached, "ball crossed the %.1f mm gap into the top screen" % Screens.profile.gap_mm)
	await physics_frames(1)
	# 22 mm at well under 2.5 m/s takes at least ~9 ms; a 0 here means the timer re-armed itself.
	ok(scene._last_crossing_ms >= 9, "crossing time measured (%d ms)" % scene._last_crossing_ms)
