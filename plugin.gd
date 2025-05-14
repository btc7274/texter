@tool
extends EditorPlugin

var export_window = null
var quick_export_config = ConfigFile.new()
const QUICK_EXPORT_CONFIG_PATH = "res://addons/texter/quick_export.cfg"

func _enter_tree():
	# Check if config directory exists
	var config_dir = "res://addons/texter"
	var dir = DirAccess.open(config_dir)
	if not dir:
		_show_error("Config directory not found: " + config_dir)
		return
	# Load quick export settings
	var err = quick_export_config.load(QUICK_EXPORT_CONFIG_PATH)
	if err != OK:
		quick_export_config.set_value("settings", "last_directory", "res://")
		quick_export_config.set_value("settings", "preset", "All Files")
		quick_export_config.set_value("settings", "format", "JSON")
		quick_export_config.save(QUICK_EXPORT_CONFIG_PATH)
	# Add menu items under Tools
	add_tool_menu_item(tr("Export Context"), Callable(self, "_on_export_context"))
	add_tool_menu_item(tr("Quick Context"), Callable(self, "_on_quick_export"))
	# Add shortcut for Quick Context (Ctrl+Shift+E)
	var shortcut = InputEventKey.new()
	shortcut.ctrl_pressed = true
	shortcut.shift_pressed = true
	shortcut.keycode = KEY_E
	get_editor_interface().get_command_palette().add_command(
		"Quick Context",
		"quick_context",
		Callable(self, "_on_quick_export"),
		"Ctrl+Shift+E"
	)

func _exit_tree():
	# Clean up menu items
	remove_tool_menu_item(tr("Export Context"))
	remove_tool_menu_item(tr("Quick Context"))
	# Remove command from EditorCommandPalette
	get_editor_interface().get_command_palette().remove_command("quick_context")
	# Free window if it exists
	if export_window:
		export_window.queue_free()

func _on_export_context():
	# Show the export context window
	if not export_window:
		export_window = preload("res://addons/texter/export_context.tscn").instantiate()
		get_editor_interface().get_base_control().add_child(export_window)
	export_window.popup_centered()

func _on_quick_export():
	# Perform quick export using last settings
	if export_window:
		export_window.queue_free()
		export_window = null
	
	var last_dir = quick_export_config.get_value("settings", "last_directory", "res://")
	var dir = DirAccess.open(last_dir)
	if not dir:
		last_dir = "res://"
		quick_export_config.set_value("settings", "last_directory", last_dir)
		quick_export_config.save(QUICK_EXPORT_CONFIG_PATH)
		dir = DirAccess.open(last_dir)
		if not dir:
			_show_error("Failed to access project directory")
			return
	
	var preset = quick_export_config.get_value("settings", "preset", "All Files")
	var format = quick_export_config.get_value("settings", "format", "JSON").to_lower()
	
	# Generate output file path
	var datetime = Time.get_datetime_dict_from_system()
	var timestamp = "%04d-%02d-%02d_%02d-%02d" % [
		datetime.year, datetime.month, datetime.day, datetime.hour, datetime.minute
	]
	var extension = "json" if format == "json" else ("md" if format == "markdown" else "txt")
	var output_path = last_dir + ("/" if not last_dir.ends_with("/") else "") + "proj_" + timestamp + "." + extension
	
	# Create and show export window for progress only
	export_window = preload("res://addons/texter/export_context.tscn").instantiate()
	get_editor_interface().get_base_control().add_child(export_window)
	export_window.start_quick_export(output_path, preset, format)

func _show_error(message: String):
	# Show error dialog
	var dialog = AcceptDialog.new()
	dialog.dialog_text = message
	dialog.title = "Quick Context Error"
	get_editor_interface().get_base_control().add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
