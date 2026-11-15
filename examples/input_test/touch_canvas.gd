class_name TouchCanvas
extends Control
## Full-screen touch view: one circle per finger with its index. Proves which screen receives touch.

signal touches_changed(count: int)

var _touches: Dictionary[int, Vector2] = {}


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if touch.pressed:
			_touches[touch.index] = touch.position
		else:
			_touches.erase(touch.index)
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event as InputEventScreenDrag
		_touches[drag.index] = drag.position
	else:
		return
	touches_changed.emit(_touches.size())
	queue_redraw()
	accept_event()


func _draw() -> void:
	for index: int in _touches:
		var at: Vector2 = _touches[index]
		draw_circle(at, 14.0, Color(1, 0.706, 0.329, 0.35))
		draw_arc(at, 14.0, 0.0, TAU, 24, Color(1, 0.706, 0.329), 1.0)
		draw_line(Vector2(at.x, 0), Vector2(at.x, size.y), Color(1, 1, 1, 0.15))
		draw_line(Vector2(0, at.y), Vector2(size.x, at.y), Color(1, 1, 1, 0.15))
		draw_string(get_theme_default_font(), at + Vector2(16, -16), str(index), HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
