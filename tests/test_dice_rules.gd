class_name TestDiceRules
extends TestCase


func test_top_face_upright_is_one() -> void:
	eq(DiceRules.top_face(Basis.IDENTITY), 1, "identity")


func test_top_face_upside_down_is_six() -> void:
	eq(DiceRules.top_face(Basis(Vector3.RIGHT, PI)), 6, "flipped on X")


func test_top_face_rolled_onto_side() -> void:
	# +90 degrees around +Z turns local +X to world up; -90 around +X turns local +Z up.
	eq(DiceRules.top_face(Basis(Vector3.BACK, PI / 2.0)), 2, "rolled on Z")
	eq(DiceRules.top_face(Basis(Vector3.RIGHT, -PI / 2.0)), 3, "rolled on X")


func test_opposite_faces_sum_to_seven() -> void:
	for axis: Vector3 in DiceRules.D6_FACES:
		eq(DiceRules.D6_FACES[axis] + DiceRules.D6_FACES[-axis], 7, "faces %s" % axis)


func test_flat_detection() -> void:
	ok(DiceRules.is_flat(Basis.IDENTITY), "flat")
	ok(not DiceRules.is_flat(Basis(Vector3.BACK, PI / 4.0)), "on an edge")
