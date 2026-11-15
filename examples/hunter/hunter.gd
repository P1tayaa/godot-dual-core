class_name Hunter
extends DualScene
## Metroid Prime Hunters layout: first person 3D on top, 2D radar on the bottom that is also the aim pad.
## Drag on the bottom screen to look, tap (or A) to fire, left stick / arrows to move.

const TARGET_COUNT: int = 8
const ROOM_HALF: float = 18.0
const MOVE_SPEED: float = 6.0
const LOOK_SPEED: float = 0.006 # radians per pixel dragged
const TAP_MAX_TIME: float = 0.2
const TAP_MAX_MOVE: float = 6.0

var _yaw: float = 0.0
var _pitch: float = 0.0
var _targets: Array[StaticBody3D] = []
var _target_positions: PackedVector3Array = []
var _hits: int = 0
var _fire_queued: bool = false
var _touch_start: Vector2 = Vector2.ZERO
var _touch_time: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var _player: Node3D = %Player
@onready var _camera: Camera3D = %Camera
@onready var _radar: HunterRadar = %Radar
@onready var _score: Label = %Score


func _ready() -> void:
	super._ready()
	_rng.seed = 42
	_build_room()
	_radar.gui_input.connect(_on_radar_input)
	_refresh_score()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_fire_queued = true


func _process(delta: float) -> void:
	var stick: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var move: Vector3 = Basis(Vector3.UP, _yaw) * Vector3(stick.x, 0.0, stick.y) * MOVE_SPEED * delta
	_player.position = (_player.position + move).clamp(Vector3(-ROOM_HALF, 1.5, -ROOM_HALF), Vector3(ROOM_HALF, 1.5, ROOM_HALF))
	_player.rotation.y = _yaw
	_camera.rotation.x = _pitch
	_radar.show_state(_player.position, -_yaw, _target_positions)


func _physics_process(_delta: float) -> void:
	if not _fire_queued:
		return
	_fire_queued = false
	Input.vibrate_handheld(20)
	var from: Vector3 = _camera.global_position
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, from - _camera.global_basis.z * 60.0)
	var hit: Dictionary = top_viewport.find_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var body: StaticBody3D = hit["collider"] as StaticBody3D
	var index: int = _targets.find(body)
	if index < 0:
		return
	_targets.remove_at(index)
	_target_positions.remove_at(index)
	body.queue_free()
	_hits += 1
	Input.vibrate_handheld(80)
	_refresh_score()


func _on_radar_input(event: InputEvent) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	if event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event as InputEventScreenDrag
		_yaw -= drag.relative.x * LOOK_SPEED
		_pitch = clampf(_pitch - drag.relative.y * LOOK_SPEED, -1.2, 1.2)
	elif event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if touch.pressed:
			_touch_start = touch.position
			_touch_time = now
		elif now - _touch_time < TAP_MAX_TIME and touch.position.distance_to(_touch_start) < TAP_MAX_MOVE:
			_fire_queued = true


func _refresh_score() -> void:
	_score.text = tr("HUNTER_SCORE") % [_hits, TARGET_COUNT]


func _build_room() -> void:
	var world: Node3D = %World
	var pillar_mesh: BoxMesh = BoxMesh.new()
	pillar_mesh.size = Vector3(1.5, 6.0, 1.5)
	var stone: StandardMaterial3D = StandardMaterial3D.new()
	stone.albedo_color = Color(0.35, 0.38, 0.5)
	pillar_mesh.material = stone
	for i: int in 16:
		var pillar: MeshInstance3D = MeshInstance3D.new()
		pillar.mesh = pillar_mesh
		pillar.position = Vector3(_rng.randf_range(-ROOM_HALF, ROOM_HALF), 3.0, _rng.randf_range(-ROOM_HALF, ROOM_HALF))
		world.add_child(pillar)
	var target_mesh: SphereMesh = SphereMesh.new()
	target_mesh.radius = 0.6
	target_mesh.height = 1.2
	var glow: StandardMaterial3D = StandardMaterial3D.new()
	glow.albedo_color = Color(1, 0.35, 0.3)
	glow.emission_enabled = true
	glow.emission = Color(1, 0.2, 0.1)
	target_mesh.material = glow
	var target_shape: SphereShape3D = SphereShape3D.new()
	target_shape.radius = 0.6
	for i: int in TARGET_COUNT:
		var target: StaticBody3D = StaticBody3D.new()
		var mesh: MeshInstance3D = MeshInstance3D.new()
		mesh.mesh = target_mesh
		target.add_child(mesh)
		var shape: CollisionShape3D = CollisionShape3D.new()
		shape.shape = target_shape
		target.add_child(shape)
		target.position = Vector3(_rng.randf_range(-ROOM_HALF, ROOM_HALF), _rng.randf_range(1.0, 3.0), _rng.randf_range(-ROOM_HALF, ROOM_HALF))
		world.add_child(target)
		_targets.append(target)
		_target_positions.append(target.position)
