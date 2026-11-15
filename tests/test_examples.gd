class_name TestExamples
extends TestCase
## Smoke test: every launcher entry opens, runs a few frames and attaches to Screens without errors.


func test_every_example_opens() -> void:
	var dir: String = "res://data/examples"
	for file: String in ResourceLoader.list_directory(dir):
		if not file.ends_with(".tres"):
			continue
		var entry: ExampleEntry = load(dir.path_join(file)) as ExampleEntry
		ok(ResourceLoader.exists(entry.scene), "%s: scene exists" % file)
		var scene: DualScene = add_scene(load(entry.scene)) as DualScene
		await frames(5)
		eq(Screens.current, scene, "%s attached" % file)
		cleanup()
		await frames(1)


func test_home_lists_every_example() -> void:
	var home: Home = add_scene(load("res://scenes/home/home.tscn")) as Home
	await frames(2)
	var count: int = 0
	for file: String in ResourceLoader.list_directory("res://data/examples"):
		if file.ends_with(".tres"):
			count += 1
	eq(home.get_node("%List").get_child_count(), count, "one button per entry")
