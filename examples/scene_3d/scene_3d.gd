class_name Scene3D
extends DualScene
## 3D stress on the top screen: N lit meshes, as N nodes (one draw call each) or one MultiMesh (one draw call),
## with or without shadows and spin. Bottom (ON_CHANGE, refreshed once a second): count, draw calls, fps.

const COUNTS: Array[int] = [10, 50, 100, 200, 400, 800]
const SPACING: float = 1.6

var _count_index: int = 1
var _shadows: bool = true
var _spin: bool = true
var _multimesh: bool = false
var _mesh: Mesh
var _nodes: Array[MeshInstance3D] = []

@onready var _objects: Node3D = %Objects
@onready var _sun: DirectionalLight3D = %Sun


func _ready() -> void:
	super._ready()
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = 0.25
	torus.outer_radius = 0.5
	torus.rings = 12
	torus.ring_segments = 8
	var look: StandardMaterial3D = StandardMaterial3D.new()
	look.albedo_color = Color(1, 0.706, 0.329)
	torus.material = look
	_mesh = torus
	%Less.pressed.connect(_change_count.bind(-1))
	%More.pressed.connect(_change_count.bind(1))
	%Shadows.pressed.connect(func() -> void: _shadows = not _shadows; _apply())
	%Spin.pressed.connect(func() -> void: _spin = not _spin; _apply())
	%MultiMeshToggle.pressed.connect(func() -> void: _multimesh = not _multimesh; _rebuild())
	%StatsTimer.timeout.connect(_refresh_labels)
	_rebuild()


func _process(delta: float) -> void:
	if not _spin:
		return
	_objects.rotate_y(delta * 0.3)
	for node: MeshInstance3D in _nodes:
		node.rotate_x(delta * 2.0)


func _change_count(step: int) -> void:
	_count_index = clampi(_count_index + step, 0, COUNTS.size() - 1)
	_rebuild()


func _rebuild() -> void:
	for child: Node in _objects.get_children():
		child.queue_free()
	_nodes.clear()
	var count: int = COUNTS[_count_index]
	var side: int = ceili(sqrt(float(count)))
	if _multimesh:
		var multi: MultiMesh = MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = _mesh
		multi.instance_count = count
		for i: int in count:
			multi.set_instance_transform(i, Transform3D(Basis.from_euler(Vector3(i, i * 0.5, 0.0)), _grid_position(i, side)))
		var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
		instance.multimesh = multi
		_objects.add_child(instance)
	else:
		for i: int in count:
			var node: MeshInstance3D = MeshInstance3D.new()
			node.mesh = _mesh
			node.position = _grid_position(i, side)
			node.rotation = Vector3(i, i * 0.5, 0.0)
			_objects.add_child(node)
			_nodes.append(node)
	_apply()


func _grid_position(i: int, side: int) -> Vector3:
	var half: float = (side - 1) * SPACING / 2.0
	return Vector3((i % side) * SPACING - half, 0.6, (i / side) * SPACING - half)


func _apply() -> void:
	_sun.shadow_enabled = _shadows
	_refresh_labels()


func _refresh_labels() -> void:
	%Count.text = tr("SCENE3D_COUNT") % COUNTS[_count_index]
	%Draws.text = tr("SCENE3D_DRAWS") % int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	%Fps.text = tr("FPS_LABEL") % Engine.get_frames_per_second()
	%Shadows.text = tr("SCENE3D_SHADOWS") % ("ON" if _shadows else "OFF")
	%Spin.text = tr("SCENE3D_SPIN") % ("ON" if _spin else "OFF")
	%MultiMeshToggle.text = tr("SCENE3D_MULTIMESH") % ("ON" if _multimesh else "OFF")
	request_redraw(Screen.BOTTOM)
