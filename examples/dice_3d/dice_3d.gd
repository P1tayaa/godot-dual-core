class_name Dice3D
extends DualScene
## Physics d6 in 3D on the top screen. Bottom: flick to throw (direction and strength from the swipe), A to roll,
## or shake the device. The top screen redraws every frame only while dice move, then drops to ON_CHANGE.

const DICE_COUNT: int = 2
const SHAKE_THRESHOLD: float = 12.0 # m/s² of motion, gravity removed
const SETTLE_SPEED: float = 0.05
const SETTLE_FRAMES: int = 20
const HISTORY_SIZE: int = 6

var _dice: Array[RigidBody3D] = []
var _rolling: bool = false
var _settled_frames: int = 0
var _history: PackedStringArray = []
var _flick_start: Vector2 = Vector2.ZERO
var _flick_time: float = 0.0
var _shake_ready_at: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var _result: Label = %Result
@onready var _history_label: Label = %History
@onready var _font: Font = load("res://assets/fonts/fusion_pixel/fusion-pixel-12px-proportional-zh_hans.ttf.woff2")


func _ready() -> void:
	super._ready()
	for i: int in DICE_COUNT:
		var die: RigidBody3D = _make_die()
		die.position = Vector3(-1.0 + 2.0 * i, 0.6, 0.0)
		%Tray.add_child(die)
		_dice.append(die)
	%RollButton.pressed.connect(_roll.bind(Vector2.UP * 0.6))
	%FlickArea.gui_input.connect(_on_flick_input)
	_rng.randomize()
	_finish_roll()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_roll(Vector2.UP * 0.6)


func _physics_process(_delta: float) -> void:
	var motion: float = (Input.get_accelerometer() - Input.get_gravity()).length()
	var now: float = Time.get_ticks_msec() / 1000.0
	if motion > SHAKE_THRESHOLD and now > _shake_ready_at:
		_shake_ready_at = now + 1.0
		_roll(Vector2.from_angle(_rng.randf() * TAU))
	if not _rolling:
		return
	var moving: bool = false
	for die: RigidBody3D in _dice:
		if die.linear_velocity.length() > SETTLE_SPEED or die.angular_velocity.length() > SETTLE_SPEED:
			moving = true
	_settled_frames = 0 if moving else _settled_frames + 1
	if _settled_frames >= SETTLE_FRAMES:
		_finish_roll()


## `swipe` is the flick in bottom-screen space, length ~0..1 (strength).
func _roll(swipe: Vector2) -> void:
	_rolling = true
	_settled_frames = 0
	set_redraw(Screen.TOP, Redraw.ALWAYS)
	_result.text = "DICE_ROLLING"
	request_redraw(Screen.BOTTOM)
	Input.vibrate_handheld(60)
	var strength: float = clampf(swipe.length(), 0.3, 1.5)
	var direction: Vector3 = Vector3(swipe.x, 0.0, swipe.y).normalized() if swipe.length() > 0.01 else Vector3.FORWARD
	for i: int in _dice.size():
		var die: RigidBody3D = _dice[i]
		die.position = Vector3(-0.8 + 1.6 * i, 2.5, 2.0)
		die.basis = Basis.from_euler(Vector3(_rng.randf() * TAU, _rng.randf() * TAU, _rng.randf() * TAU))
		die.linear_velocity = direction * 9.0 * strength + Vector3(_rng.randf_range(-1, 1), 2.0, 0.0)
		die.angular_velocity = Vector3(_rng.randf_range(-20, 20), _rng.randf_range(-20, 20), _rng.randf_range(-20, 20))
		die.sleeping = false


func _finish_roll() -> void:
	_rolling = false
	var values: PackedStringArray = []
	var total: int = 0
	for die: RigidBody3D in _dice:
		var value: int = DiceRules.top_face(die.basis)
		total += value
		values.append(str(value))
	_result.text = tr("DICE_RESULT") % total + "  (" + " + ".join(values) + ")"
	_history.insert(0, str(total))
	if _history.size() > HISTORY_SIZE:
		_history.resize(HISTORY_SIZE)
	_history_label.text = tr("DICE_HISTORY") % " ".join(_history)
	Input.vibrate_handheld(25)
	# Nothing moves now: stop redrawing the 3D screen until the next roll.
	set_redraw(Screen.TOP, Redraw.ON_CHANGE)
	request_redraw(Screen.TOP)
	request_redraw(Screen.BOTTOM)


func _on_flick_input(event: InputEvent) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if touch.pressed:
			_flick_start = touch.position
			_flick_time = now
		else:
			var swipe: Vector2 = touch.position - _flick_start
			var speed: float = swipe.length() / maxf(now - _flick_time, 0.05) # px/s
			if swipe.length() > 10.0:
				_roll(swipe.normalized() * clampf(speed / 600.0, 0.3, 1.5))


func _make_die() -> RigidBody3D:
	var die: RigidBody3D = RigidBody3D.new()
	die.mass = 0.2
	die.gravity_scale = 3.0
	var material: PhysicsMaterial = PhysicsMaterial.new()
	material.bounce = 0.3
	material.friction = 0.8
	die.physics_material_override = material
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3.ONE
	shape.shape = box
	die.add_child(shape)
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var cube: BoxMesh = BoxMesh.new()
	var look: StandardMaterial3D = StandardMaterial3D.new()
	look.albedo_color = Color(0.95, 0.92, 0.85)
	cube.material = look
	mesh.mesh = cube
	die.add_child(mesh)
	for axis: Vector3 in DiceRules.D6_FACES:
		var label: Label3D = Label3D.new()
		var value: int = DiceRules.D6_FACES[axis]
		label.text = "6." if value == 6 else str(value) # the dot tells 6 from an upside-down 9
		label.font = _font
		label.font_size = 48
		label.outline_size = 0
		label.pixel_size = 0.012
		label.modulate = Color(0.12, 0.1, 0.2)
		label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		label.position = axis * 0.501
		# Label3D reads from +Z: point +Z out of the face.
		var up: Vector3 = Vector3.FORWARD if absf(axis.y) > 0.5 else Vector3.UP
		label.basis = Basis.looking_at(-axis, up)
		die.add_child(label)
	return die
