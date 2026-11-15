class_name ThrowGap
extends DualScene
## One physics world in millimetres across both screens and the hinge gap (DualScene.use_physical_world_2d).
## Grab the ball on either screen and flick it. Going up, it leaves the bottom screen, flies through the gap you
## cannot see, then enters the top screen; the top label shows how long the crossing took.
## Tilt mode points gravity along the device's real gravity.

const BALL_RADIUS_MM: float = 4.0
const GRAB_RADIUS_MM: float = 14.0
const WALL_MM: float = 60.0
const GRAVITY_MM_S2: float = 2000.0 # ~0.2 g: a ball rolling on a tilted table, not falling
const TILT_SCALE: float = 300.0 # mm/s² per m/s² of real gravity
const MAX_SPEED_MM_S: float = 2500.0 # faster would tunnel through the walls at 60 physics steps per second

enum Crossing { ON_BOTTOM, IN_GAP, COUNTED }

var _ball: RigidBody2D
var _grabbed: bool = false
var _grab_screen: Screen = Screen.BOTTOM
var _last_world: Vector2 = Vector2.ZERO
var _last_time: float = 0.0
var _velocity: Vector2 = Vector2.ZERO
var _tilt: bool = false
var _throw_velocity: Vector2 = Vector2.ZERO
var _grab_target: Vector2 = Vector2.ZERO
var _last_throw_speed: float = 0.0
var _peak_y: float = 0.0
var _tracking_peak: bool = false
var _press_world: Vector2 = Vector2.ZERO
var _press_time: float = 0.0
var _crossing: Crossing = Crossing.ON_BOTTOM
var _gap_entered_at: float = 0.0
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


func _physics_process(delta: float) -> void:
	if _grabbed:
		# Held: the ball stays a rigid body and is steered onto the finger, so the physics server owns its position.
		_ball.linear_velocity = ((_grab_target - _ball.global_position) / delta).limit_length(MAX_SPEED_MM_S)
	elif _throw_velocity != Vector2.ZERO:
		_ball.linear_velocity = _throw_velocity.limit_length(MAX_SPEED_MM_S)
		_last_throw_speed = _ball.linear_velocity.length()
		_peak_y = _ball.global_position.y
		_tracking_peak = true
		_throw_velocity = Vector2.ZERO
	if _tilt:
		var g: Vector3 = Input.get_gravity()
		_set_gravity(Vector2(-g.x, g.y) * TILT_SCALE)
	var y: float = _ball.global_position.y
	if _tracking_peak:
		_peak_y = minf(_peak_y, y)
		if _ball.linear_velocity.y > 0.0:
			_tracking_peak = false
			_refresh_labels()
	_track_crossing(y)


## Time spent in the hinge gap: from the bottom screen's top edge (y = 0) to the top screen's lower edge (-gap).
func _track_crossing(y: float) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	if y > 0.0:
		_crossing = Crossing.ON_BOTTOM
	elif _crossing == Crossing.ON_BOTTOM:
		_crossing = Crossing.IN_GAP
		_gap_entered_at = now
	elif _crossing == Crossing.IN_GAP and y < -Screens.profile.gap_mm:
		_crossing = Crossing.COUNTED
		_last_crossing_ms = int((now - _gap_entered_at) * 1000.0)
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
			_grab_target = world
			_ball.gravity_scale = 0.0
			_velocity = Vector2.ZERO
			_press_world = world
			_press_time = now
		elif not touch.pressed and _grabbed and screen == _grab_screen:
			_grabbed = false
			_ball.gravity_scale = 1.0
			# A quick flick may send no drag events between press and release: use the whole gesture then.
			if _velocity.length() < 1.0:
				_velocity = (world - _press_world) / maxf(now - _press_time, 0.016)
			_throw_velocity = _velocity
	elif _grabbed and screen == _grab_screen:
		var dt: float = maxf(now - _last_time, 0.001)
		# Smoothed flick speed in mm/s.
		_velocity = _velocity.lerp((world - _last_world) / dt, 0.5)
		_grab_target = world
	_last_world = world
	_last_time = now


func _reset_ball() -> void:
	var bottom: Rect2 = Screens.profile.rect_mm(Screen.BOTTOM)
	_grabbed = false
	_ball.gravity_scale = 1.0
	_ball.linear_velocity = Vector2.ZERO
	# Teleport through the physics server: it owns the position of a rigid body.
	var at: Vector2 = Vector2(bottom.get_center().x, bottom.end.y - 15.0)
	PhysicsServer2D.body_set_state(_ball.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(0.0, at))
	_ball.global_position = at


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
	# Peak as height above the bottom screen's top edge: above gap_mm means it reached the top screen.
	_info.text = tr("THROW_INFO") % [Screens.profile.gap_mm, _last_throw_speed, -_peak_y, _last_crossing_ms]
	_tilt_button.text = tr("THROW_TILT") % ("ON" if _tilt else "OFF")


func _make_ball() -> RigidBody2D:
	var ball: RigidBody2D = RigidBody2D.new()
	ball.continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
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
