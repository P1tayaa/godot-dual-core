class_name InputTest
extends DualScene
## Every input the device has. Touch dots on both screens, gamepad on top, sensors and vibration on the bottom.
## Polls the gamepad and sensors each frame on purpose: this is a diagnostic screen.

var _buttons: PackedStringArray = []
var _axes: PackedStringArray = []

@onready var _top_touches: Label = %TopTouches
@onready var _bottom_touches: Label = %BottomTouches
@onready var _gamepad: Label = %Gamepad
@onready var _sticks: Label = %Sticks
@onready var _sensors: Label = %Sensors


func _ready() -> void:
	super._ready()
	%TopCanvas.touches_changed.connect(func(count: int) -> void: _top_touches.text = tr("INPUT_TOUCHES") % count)
	%BottomCanvas.touches_changed.connect(func(count: int) -> void: _bottom_touches.text = tr("INPUT_TOUCHES") % count)
	%Vibrate.pressed.connect(func() -> void: Input.vibrate_handheld(300))
	_top_touches.text = tr("INPUT_TOUCHES") % 0
	_bottom_touches.text = tr("INPUT_TOUCHES") % 0


func _process(_delta: float) -> void:
	_buttons.clear()
	_axes.clear()
	for device: int in Input.get_connected_joypads():
		for button: int in JOY_BUTTON_SDL_MAX:
			if Input.is_joy_button_pressed(device, button as JoyButton):
				_buttons.append(str(button))
		for axis: int in JOY_AXIS_SDL_MAX:
			var value: float = Input.get_joy_axis(device, axis as JoyAxis)
			if absf(value) > 0.1:
				_axes.append("%d:%.2f" % [axis, value])
	_gamepad.text = tr("INPUT_GAMEPAD") % " ".join(_buttons)
	_sticks.text = tr("INPUT_AXES") % " ".join(_axes)
	_sensors.text = tr("INPUT_SENSORS") % [
		_vec(Input.get_accelerometer()), _vec(Input.get_gyroscope()), _vec(Input.get_gravity()),
	]


func _vec(v: Vector3) -> String:
	return "%+.2f %+.2f %+.2f" % [v.x, v.y, v.z]
