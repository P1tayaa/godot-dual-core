class_name DiceRules
extends RefCounted
## Dice formulas. Numbers in, result out.

## Face values of a d6 by local axis. Opposite faces sum to 7.
const D6_FACES: Dictionary[Vector3, int] = {
	Vector3.UP: 1, Vector3.DOWN: 6,
	Vector3.RIGHT: 2, Vector3.LEFT: 5,
	Vector3.BACK: 3, Vector3.FORWARD: 4,
}


## The d6 value facing up for a die with this orientation (world up is +Y).
static func top_face(basis: Basis) -> int:
	var best_value: int = 1
	var best_dot: float = -INF
	for axis: Vector3 in D6_FACES:
		var dot: float = (basis * axis).dot(Vector3.UP)
		if dot > best_dot:
			best_dot = dot
			best_value = D6_FACES[axis]
	return best_value


## True when the die rests on a face, not on an edge (top face within ~25 degrees of up).
static func is_flat(basis: Basis) -> bool:
	for axis: Vector3 in D6_FACES:
		if (basis * axis).dot(Vector3.UP) > 0.9:
			return true
	return false
