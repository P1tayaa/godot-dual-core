class_name HunterRadar
extends Control
## Bottom screen of the hunter example: top-down radar centred on the player, forward = up. Also the aim surface
## (the scene listens to gui_input). Redrawn when the scene calls show_state().

const RANGE: float = 20.0 # world units from centre to edge

var _player: Vector3 = Vector3.ZERO
var _yaw: float = 0.0
var _targets: PackedVector3Array = []


func show_state(player: Vector3, yaw: float, targets: PackedVector3Array) -> void:
	_player = player
	_yaw = yaw
	_targets = targets
	queue_redraw()


func _draw() -> void:
	var centre: Vector2 = size / 2.0
	var radius: float = minf(size.x, size.y) * 0.45
	draw_circle(centre, radius, Color(0.08, 0.16, 0.12))
	for ring: int in [1, 2, 3]:
		draw_arc(centre, radius * ring / 3.0, 0.0, TAU, 48, Color(0.3, 0.9, 0.5, 0.35), 1.0)
	draw_line(centre - Vector2(radius, 0), centre + Vector2(radius, 0), Color(0.3, 0.9, 0.5, 0.2))
	draw_line(centre - Vector2(0, radius), centre + Vector2(0, radius), Color(0.3, 0.9, 0.5, 0.2))
	for target: Vector3 in _targets:
		var offset: Vector2 = Vector2(target.x - _player.x, target.z - _player.z).rotated(-_yaw)
		if offset.length() > RANGE:
			offset = offset.normalized() * RANGE
		draw_circle(centre + offset / RANGE * radius, 3.0, Color(1, 0.35, 0.3))
	var nose: PackedVector2Array = [centre + Vector2(0, -7), centre + Vector2(-5, 5), centre + Vector2(5, 5)]
	draw_colored_polygon(nose, Color(1, 0.706, 0.329))
