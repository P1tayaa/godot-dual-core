class_name ShaderStress
extends DualScene
## Full screen fragment shader on each screen (fractal.gdshader). The buttons set the iterations per pixel of each
## screen separately, so you can see what one screen costs against the other.

const LEVELS: Array[int] = [4, 16, 64, 256, 1024]

var _top_level: int = 1
var _bottom_level: int = 1

@onready var _top_material: ShaderMaterial = %TopFractal.material as ShaderMaterial
@onready var _bottom_material: ShaderMaterial = %BottomFractal.material as ShaderMaterial


func _ready() -> void:
	super._ready()
	%TopLess.pressed.connect(_change.bind(Screen.TOP, -1))
	%TopMore.pressed.connect(_change.bind(Screen.TOP, 1))
	%BottomLess.pressed.connect(_change.bind(Screen.BOTTOM, -1))
	%BottomMore.pressed.connect(_change.bind(Screen.BOTTOM, 1))
	_apply()


func _change(screen: Screen, step: int) -> void:
	if screen == Screen.TOP:
		_top_level = clampi(_top_level + step, 0, LEVELS.size() - 1)
	else:
		_bottom_level = clampi(_bottom_level + step, 0, LEVELS.size() - 1)
	_apply()


func _apply() -> void:
	_top_material.set_shader_parameter("iterations", LEVELS[_top_level])
	_bottom_material.set_shader_parameter("iterations", LEVELS[_bottom_level])
	%Levels.text = tr("SHADER_LEVEL") % [LEVELS[_top_level], LEVELS[_bottom_level]]
