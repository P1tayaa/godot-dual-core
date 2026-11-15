class_name ExampleEntry
extends Resource
## One entry of the launcher (scenes/home). Like Bevy's examples list: a scene, a category, what it shows.

enum Category { BASICS, INPUT, PHYSICS, RENDER, STRESS, SETTINGS }

@export var title_key: String = ""
@export var description_key: String = ""
@export var category: Category = Category.BASICS
@export_file("*.tscn") var scene: String = ""
## Sort order inside the launcher (low first).
@export var order: int = 0
