class_name Home
extends DualScene
## Launcher. Bottom: one button per ExampleEntry in data/examples/ (touch or gamepad focus). Top: what the focused
## example shows, and the current device. Both screens are ON_CHANGE: nothing redraws while you read.

const EXAMPLES_DIR: String = "res://data/examples"

var _entries: Array[ExampleEntry] = []

@onready var _list: VBoxContainer = %List
@onready var _category: Label = %Category
@onready var _title: Label = %Title
@onready var _description: Label = %Description
@onready var _device: Label = %Device


func _ready() -> void:
	super._ready()
	for file: String in ResourceLoader.list_directory(EXAMPLES_DIR):
		if file.ends_with(".tres"):
			_entries.append(load(EXAMPLES_DIR.path_join(file)) as ExampleEntry)
	_entries.sort_custom(func(a: ExampleEntry, b: ExampleEntry) -> bool: return a.order < b.order)
	for entry: ExampleEntry in _entries:
		var button: Button = Button.new()
		button.text = entry.title_key
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_entered.connect(_show_entry.bind(entry))
		button.pressed.connect(Screens.change_scene.bind(entry.scene))
		_list.add_child(button)
	_device.text = tr("HOME_DEVICE") % [
		Screens.profile.display_name, Screens.profile.gap_mm, ScreensService.Mode.keys()[Screens.mode],
	]
	if _list.get_child_count() > 0:
		(_list.get_child(0) as Button).grab_focus()


func _show_entry(entry: ExampleEntry) -> void:
	_category.text = "CAT_" + ExampleEntry.Category.keys()[entry.category]
	_title.text = entry.title_key
	_description.text = entry.description_key
	request_redraw(Screen.TOP)
	request_redraw(Screen.BOTTOM)
