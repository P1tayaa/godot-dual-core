class_name TwoCameras
extends DualScene
## One 3D world seen by two cameras: the bottom viewport borrows the top viewport's World3D. Top: chase camera.
## Bottom: orthographic map. Tap the map: a ray from the map camera hits the ground plane, the robot walks there.
## Left stick / arrows also drive the robot.

const SPEED: float = 5.0
const TURN: float = 8.0
const CHASE_OFFSET: Vector3 = Vector3(0, 4, 7)

var _target: Vector3 = Vector3.ZERO
var _has_target: bool = false

@onready var _robot: Node3D = %Robot
@onready var _chase: Camera3D = %ChaseCamera
@onready var _map: Camera3D = %MapCamera
@onready var _marker: Node3D = %Marker


func _ready() -> void:
	super._ready()
	# find_world_3d(): with own_world_3d the world is internal, the world_3d property stays null.
	bottom_viewport.world_3d = top_viewport.find_world_3d()
	%MapTouch.gui_input.connect(_on_map_input)
	_marker.visible = false


func _process(delta: float) -> void:
	var stick: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction: Vector3 = Vector3(stick.x, 0.0, stick.y)
	if direction.length() > 0.1:
		_has_target = false
		_marker.visible = false
	elif _has_target:
		var to_target: Vector3 = _target - _robot.position
		to_target.y = 0.0
		if to_target.length() < 0.2:
			_has_target = false
			_marker.visible = false
		direction = to_target.normalized()
	if direction.length() > 0.1:
		_robot.position += direction.limit_length(1.0) * SPEED * delta
		var facing: float = atan2(-direction.x, -direction.z)
		_robot.rotation.y = lerp_angle(_robot.rotation.y, facing, minf(TURN * delta, 1.0))
	var wanted: Vector3 = _robot.position + Basis(Vector3.UP, _robot.rotation.y) * CHASE_OFFSET
	_chase.position = _chase.position.lerp(wanted, minf(4.0 * delta, 1.0))
	_chase.look_at(_robot.position + Vector3.UP, Vector3.UP)
	_map.position = Vector3(_robot.position.x, _map.position.y, _robot.position.z)


func _on_map_input(event: InputEvent) -> void:
	if not (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed):
		return
	var at: Vector2 = (event as InputEventScreenTouch).position
	var origin: Vector3 = _map.project_ray_origin(at)
	var normal: Vector3 = _map.project_ray_normal(at)
	var hit: Variant = Plane(Vector3.UP, 0.0).intersects_ray(origin, normal)
	if hit == null:
		return
	_target = hit as Vector3
	_has_target = true
	_marker.position = _target
	_marker.visible = true
	Input.vibrate_handheld(20)
