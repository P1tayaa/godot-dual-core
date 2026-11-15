class_name ThrowGap
extends DualScene
## One physics world in millimetres across both screens and the hinge gap (DualScene.use_physical_world_2d).
## Grab the ball on either screen and flick it. Going up, it leaves the bottom screen, flies through the gap you
## cannot see, then enters the top screen; the top label shows how long the crossing took.
## Tilt mode points gravity along the device's real gravity.

const BALL_RADIUS_MM: float = 4.0
const GRAB_RADIUS_MM: float = 14.0
const WALL_MM: float = 20.0
const GRAVITY_MM_S2: float = 3000.0 # ~0.3 g: tabletop feel at this scale
const TILT_SCALE: float = 300.0 # mm/s² per m/s² of real gravity

var _ball: RigidBody2D
var _grabbed: bool = false
var _grab_screen: Screen = Screen.BOTTOM
var _last_world: Vector2 = Vector2.ZERO
var _last_time: float = 0.0
var _velocity: Vector2 = Vector2.ZERO
var _tilt: bool = false
var _left_bottom_at: float = -1.0
var _last_crossing_ms: int = 0

@onready var _info: Label = %Info
@onready var _tilt_button: Button = %TiltButton


func _ready() -> void:
	super._ready()
	use_physical_world_2d()
	var world_root: Node2D = %World
	world_root.add_child(WorldGrid.new())
	_build_walls(world_root)
	_ball = _make_ball()
	world_root.add_child(_ball)
	_set_gravity(Vector2.DOWN * GRAVITY_MM_S2)
	%TopTouch.gui_input.connect(_on_touch.bind(Screen.TOP))
	%BottomTouch.gui_input.connect(_on_touch.bind(Screen.BOTTOM))
	%ResetButton.pressed.connect(_reset_ball)
	_tilt_button.pressed.connect(_toggle_tilt)
	Screens.layout_changed.connect(_rebuild_walls)
	_reset_ball()
	_refresh_labels()


func _physics_process(_delta: float) -> void:
	if _tilt:
		var g: Vector3 = Input.get_gravity()
		_set_gravity(Vector2(-g.x, g.y) * TILT_SCALE)
	# Crossing time: from leaving the bottom screen's top edge to entering the top screen.
	var y: float = _ball.global_position.y
	var now: float = Time.get_ticks_msec() / 1000.0
	if y > 0.0:
		_left_bottom_at = -1.0
	elif _left_bottom_at < 0.0 and _ball.linear_velocity.y < 0.0:
		_left_bottom_at = now
	if _left_bottom_at >= 0.0 and y < -Screens.profile.gap_mm:
		_last_crossing_ms = int((now - _left_bottom_at) * 1000.0)
		_left_bottom_at = -2.0 # counted, wait until it is back on the bottom screen
		_refresh_labels()


func _on_touch(event: InputEvent, screen: Screen) -> void:
	if not (event is InputEventScreenTouch or event is InputEventScreenDrag):
		return
	var world: Vector2 = screen_to_world(screen, (event as InputEventFromWindow).position)
	var now: float = Time.get_ticks_msec() / 1000.0
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if touch.pressed and world.distance_to(_ball.global_position) < GRAB_RADIUS_MM:
			_grabbed = true
			_grab_screen = screen
			_ball.freeze = true
			_velocity = Vector2.ZERO
		elif not touch.pressed and _grabbed and screen == _grab_screen:
			_grabbed = false
			_ball.freeze = false
			_ball.linear_velocity = _velocity
	elif _grabbed and screen == _grab_screen:
		var dt: float = maxf(now - _last_time, 0.001)
		# Smoothed flick speed in mm/s.
		_velocity = _velocity.lerp((world - _last_world) / dt, 0.5)
		_ball.global_position = world
	_last_world = world
	_last_time = now


func _reset_ball() -> void:
	var bottom: Rect2 = Screens.profile.rect_mm(Screen.BOTTOM)
	_grabbed = false
	_ball.freeze = true
	_ball.global_position = Vector2(bottom.get_center().x, bottom.end.y - 15.0)
	_ball.linear_velocity = Vector2.ZERO
	_ball.freeze = false


func _toggle_tilt() -> void:
	_tilt = not _tilt
	if not _tilt:
		_set_gravity(Vector2.DOWN * GRAVITY_MM_S2)
	_refresh_labels()


func _set_gravity(gravity: Vector2) -> void:
	var space: RID = top_viewport.world_2d.space
	PhysicsServer2D.area_set_param(space, PhysicsServer2D.AREA_PARAM_GRAVITY, gravity.length())
	if gravity.length() > 0.0:
		PhysicsServer2D.area_set_param(space, PhysicsServer2D.AREA_PARAM_GRAVITY_VECTOR, gravity.normalized())


func _refresh_labels() -> void:
	_info.text = tr("THROW_INFO") % [Screens.profile.gap_mm, _last_crossing_ms]
	_tilt_button.text = tr("THROW_TILT") % ("ON" if _tilt else "OFF")


func _make_ball() -> RigidBody2D:
	var ball: RigidBody2D = RigidBody2D.new()
	ball.continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	ball.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	var material: PhysicsMaterial = PhysicsMaterial.new()
	material.bounce = 0.6
	ball.physics_material_override = material
	var shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = BALL_RADIUS_MM
	shape.shape = circle
	ball.add_child(shape)
	var look: Polygon2D = Polygon2D.new()
	var points: PackedVector2Array = []
	for i: int in 16:
		points.append(Vector2.from_angle(TAU * i / 16.0) * BALL_RADIUS_MM)
	look.polygon = points
	look.color = Color(1, 0.706, 0.329)
	ball.add_child(look)
	return ball


func _rebuild_walls() -> void:
	var old: Node = %World.get_node_or_null("Walls")
	if old != null:
		old.free()
	_build_walls(%World)


## Four thick walls around both screens and the gap.
func _build_walls(parent: Node) -> void:
	var area: Rect2 = Screens.profile.union_rect_mm()
	var walls: StaticBody2D = StaticBody2D.new()
	walls.name = "Walls"
	var sides: Array[Rect2] = [
		Rect2(area.position.x - WALL_MM, area.position.y - WALL_MM, area.size.x + WALL_MM * 2.0, WALL_MM),
		Rect2(area.position.x - WALL_MM, area.end.y, area.size.x + WALL_MM * 2.0, WALL_MM),
		Rect2(area.position.x - WALL_MM, area.position.y, WALL_MM, area.size.y),
		Rect2(area.end.x, area.position.y, WALL_MM, area.size.y),
	]
	for side: Rect2 in sides:
		var shape: CollisionShape2D = CollisionShape2D.new()
		var box: RectangleShape2D = RectangleShape2D.new()
		box.size = side.size
		shape.shape = box
		shape.position = side.get_center()
		walls.add_child(shape)
	parent.add_child(walls)
