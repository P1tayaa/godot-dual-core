@tool
class_name DualScreenEditorPlugin
extends EditorPlugin
## Only job: hand the plugin AAR to Android exports. Build the AAR with
## `cd android/plugin && ./gradlew copyToAddon`.

var _export_plugin: DualScreenExportPlugin


func _enter_tree() -> void:
	_export_plugin = DualScreenExportPlugin.new()
	add_export_plugin(_export_plugin)


func _exit_tree() -> void:
	remove_export_plugin(_export_plugin)
	_export_plugin = null
