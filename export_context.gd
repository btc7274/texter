@tool
extends Window

var all_files = []
var unique_extensions = {}
var sorted_extensions = []
var folder_paths = []
var sorted_folders = []
var scene_paths = []
var sorted_scenes = []
var extension_checkboxes = {}
var folder_checkboxes = {}
var scene_checkboxes = {}
var estimate_label: Label
var preset_option: OptionButton
var save_preset_button: Button
var update_preset_button: Button
var delete_preset_button: Button
var format_option: OptionButton
var export_button: Button
var cancel_button: Button
var progress_bar: ProgressBar
var progress_label: Label
var save_preset_dialog: Window
var preset_name_line_edit: LineEdit
var delete_preset_dialog: ConfirmationDialog
var search_extensions: LineEdit
var search_folders: LineEdit
var search_scenes: LineEdit
var is_exporting = false
var processed_files = 0
var total_files_to_export = 0
var presets = {}
var config = ConfigFile.new()
var quick_export_config = ConfigFile.new()
var excluded_extensions = []
var excluded_folders = []
var excluded_scenes = []
var visible_extensions = []
var visible_folders = []
var visible_scenes = []
var estimate_flash_timer: float = 0.0
var estimate_flash_active: bool = false
var default_color: Color
var highlight_color: Color = Color(1, 0.9, 0.5)  # Light yellow/orange for highlight
var is_quick_export: bool = false

const PRESETS_PATH = "res://addons/texter/presets.cfg"
const QUICK_EXPORT_CONFIG_PATH = "res://addons/texter/quick_export.cfg"
const FLASH_DURATION: float = 0.2  # Duration of the color flash in seconds
const TEXT_EXTENSIONS = [
	"gd", "tscn", "scn", "txt", "json", "md", "cfg", "godot", "ini", "csv"
]

func _ready():
	# Initialize UI elements
	estimate_label = $MarginContainer/ScrollContainer/VBoxContainer/EstimateLabel
	preset_option = $MarginContainer/ScrollContainer/VBoxContainer/HBoxContainerPresets/PresetOption
	save_preset_button = $MarginContainer/ScrollContainer/VBoxContainer/HBoxContainerPresets/SavePresetButton
	update_preset_button = $MarginContainer/ScrollContainer/VBoxContainer/HBoxContainerPresets/UpdatePresetButton
	delete_preset_button = $MarginContainer/ScrollContainer/VBoxContainer/HBoxContainerPresets/DeletePresetButton
	format_option = $MarginContainer/ScrollContainer/VBoxContainer/HBoxContainerFormat/FormatOption
	export_button = $MarginContainer/ScrollContainer/VBoxContainer/HBoxContainerActions/ExportButton
	cancel_button = $MarginContainer/ScrollContainer/VBoxContainer/HBoxContainerActions/CancelButton
	progress_bar = $MarginContainer/ProgressBar
	progress_label = $MarginContainer/ProgressLabel
	save_preset_dialog = $SavePresetDialog
	preset_name_line_edit = $SavePresetDialog/VBoxContainer/PresetNameLineEdit
	delete_preset_dialog = $DeletePresetDialog
	search_extensions = $MarginContainer/ScrollContainer/VBoxContainer/TabContainer/Extensions/HBoxContainerExtensionsHeader/SearchExtensions
	search_folders = $MarginContainer/ScrollContainer/VBoxContainer/TabContainer/Folders/HBoxContainerFoldersHeader/SearchFolders
	search_scenes = $MarginContainer/ScrollContainer/VBoxContainer/TabContainer/Scenes/HBoxContainerScenesHeader/SearchScenes
	
	connect("close_requested", _on_close_requested)
	
	# Set icons for UI elements
	save_preset_button.icon = get_theme_icon("Save", "EditorIcons")
	update_preset_button.icon = get_theme_icon("Reload", "EditorIcons")
	delete_preset_button.icon = get_theme_icon("Remove", "EditorIcons")
	
	# Set icons for "All" and "None" buttons
	var select_all_extensions = $MarginContainer/ScrollContainer/VBoxContainer/TabContainer/Extensions/HBoxContainerExtensionsHeader/SelectAllExtensionsButton
	var select_none_extensions = $MarginContainer/ScrollContainer/VBoxContainer/TabContainer/Extensions/HBoxContainerExtensionsHeader/SelectNoneExtensionsButton
	var select_all_folders = $MarginContainer/ScrollContainer/VBoxContainer/TabContainer/Folders/HBoxContainerFoldersHeader/SelectAllFoldersButton
	var select_none_folders = $MarginContainer/ScrollContainer/VBoxContainer/TabContainer/Folders/HBoxContainerFoldersHeader/SelectNoneFoldersButton
	var select_all_scenes = $MarginContainer/ScrollContainer/VBoxContainer/TabContainer/Scenes/HBoxContainerScenesHeader/SelectAllScenesButton
	var select_none_scenes = $MarginContainer/ScrollContainer/VBoxContainer/TabContainer/Scenes/HBoxContainerScenesHeader/SelectNoneScenesButton
	
	select_all_extensions.icon = get_theme_icon("CheckBox", "EditorIcons")
	select_none_extensions.icon = get_theme_icon("Remove", "EditorIcons")
	select_all_folders.icon = get_theme_icon("CheckBox", "EditorIcons")
	select_none_folders.icon = get_theme_icon("Remove", "EditorIcons")
	select_all_scenes.icon = get_theme_icon("CheckBox", "EditorIcons")
	select_none_scenes.icon = get_theme_icon("Remove", "EditorIcons")
	
	# Set tab icons
	var tab_container = $MarginContainer/ScrollContainer/VBoxContainer/TabContainer
	tab_container.set_tab_icon(0, get_theme_icon("File", "EditorIcons"))
	tab_container.set_tab_icon(1, get_theme_icon("Folder", "EditorIcons"))
	tab_container.set_tab_icon(2, get_theme_icon("Node", "EditorIcons"))
	
	# Retrieve default color for estimate label
	default_color = estimate_label.get_theme_color("font_color")
	
	_load_presets()
	_scan_project()
	_populate_extensions()
	_populate_folders()
	_populate_scenes()
	_update_estimate()

func _process(delta: float):
	# Handle color flash animation for estimate label
	if estimate_flash_active:
		estimate_flash_timer -= delta
		if estimate_flash_timer <= 0:
			estimate_flash_active = false
			estimate_label.add_theme_color_override("font_color", default_color)

func _load_presets():
	# Load presets from config file or set defaults
	var err = config.load(PRESETS_PATH)
	if err != OK:
		presets["All Files"] = {
			"extensions": [],
			"folders": [],
			"scenes": []
		}
		presets["Scripts Only"] = {
			"extensions": ["txt", "json", "md", "tscn", "scn", "godot", "cfg"],
			"folders": [],
			"scenes": []
		}
		presets["Scenes Only"] = {
			"extensions": ["gd", "txt", "json", "md", "godot", "cfg"],
			"folders": [],
			"scenes": []
		}
		presets["Core Project"] = {
			"extensions": ["txt", "json", "md", "cfg"],
			"folders": [],
			"scenes": []
		}
		_save_presets()
	
	for section in config.get_sections():
		var extensions = config.get_value(section, "extensions", [])
		var folders = config.get_value(section, "folders", [])
		var scenes = config.get_value(section, "scenes", [])
		presets[section] = {
			"extensions": extensions if extensions is Array else [],
			"folders": folders if folders is Array else [],
			"scenes": scenes if scenes is Array else []
		}
	
	_update_preset_option()

func _update_preset_option():
	# Populate preset dropdown
	preset_option.clear()
	for preset in presets.keys():
		preset_option.add_item(preset)
	if preset_option.item_count > 0:
		preset_option.select(0)
		_on_preset_option_item_selected(0)

func _on_preset_option_item_selected(index: int):
	# Apply selected preset
	var preset_name = preset_option.get_item_text(index)
	var preset = presets[preset_name]
	excluded_extensions = preset["extensions"].duplicate()
	excluded_folders = preset["folders"].duplicate()
	excluded_scenes = preset["scenes"].duplicate()
	
	# Update UI to reflect preset
	for ext in extension_checkboxes:
		extension_checkboxes[ext].button_pressed = ext.to_lower() in excluded_extensions
	for folder in folder_checkboxes:
		folder_checkboxes[folder].button_pressed = folder in excluded_folders
	for scene in scene_checkboxes:
		scene_checkboxes[scene].button_pressed = scene in excluded_scenes
	_update_estimate()

func _on_save_preset_button_pressed():
	# Open dialog to save a new preset
	preset_name_line_edit.text = ""
	save_preset_dialog.popup_centered()

func _on_delete_preset_confirmed():
	# Delete selected preset
	var preset_name = preset_option.get_item_text(preset_option.selected)
	presets.erase(preset_name)
	config.erase_section(preset_name)
	_save_presets()
	_update_preset_option()

func _on_update_preset_button_pressed():
	# Update current preset with current settings
	var preset_name = preset_option.get_item_text(preset_option.selected)
	_save_current_settings_to_preset(preset_name)
	_save_presets()

func _on_save_preset_save_pressed():
	# Save new preset
	var preset_name = preset_name_line_edit.text.strip_edges()
	if preset_name == "" or presets.has(preset_name):
		_show_error("Invalid or duplicate preset name")
		return
	_save_current_settings_to_preset(preset_name)
	_save_presets()
	_update_preset_option()
	save_preset_dialog.hide()

func _on_save_preset_cancel_pressed():
	# Close save preset dialog
	save_preset_dialog.hide()

func _save_current_settings_to_preset(preset_name: String):
	# Save current exclusion settings to preset
	presets[preset_name] = {
		"extensions": excluded_extensions.duplicate(),
		"folders": excluded_folders.duplicate(),
		"scenes": excluded_scenes.duplicate()
	}

func _save_presets():
	# Save presets to config file
	for preset_name in presets:
		config.set_value(preset_name, "extensions", presets[preset_name]["extensions"])
		config.set_value(preset_name, "folders", presets[preset_name]["folders"])
		config.set_value(preset_name, "scenes", presets[preset_name]["scenes"])
	config.save(PRESETS_PATH)

func _scan_project():
	# Scan project directory for files, extensions, and folders
	all_files = []
	unique_extensions = {}
	folder_paths = []
	scene_paths = []
	var dir = DirAccess.open("res://")
	if not dir:
		var err = DirAccess.get_open_error()
		_show_error("Failed to access project directory: " + str(err))
		return
	_scan_directory(dir, "res://")
	
	# Precompute sorted lists for performance
	sorted_extensions = unique_extensions.keys()
	sorted_extensions.sort()
	sorted_folders = folder_paths.duplicate()
	sorted_folders.sort()
	sorted_scenes = scene_paths.duplicate()
	sorted_scenes.sort()

func _scan_directory(dir: DirAccess, path: String):
	# Recursively scan directories and collect all files and folders
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name != "." and file_name != "..":
			var full_path = path + ("/" if not path.ends_with("/") else "") + file_name
			if dir.current_is_dir():
				folder_paths.append(full_path)
				var sub_dir = DirAccess.open(full_path)
				if sub_dir:
					_scan_directory(sub_dir, full_path)
				else:
					var err = DirAccess.get_open_error()
					print("Failed to open directory: " + full_path + ", error: " + str(err))
			else:
				all_files.append(full_path)
				var ext = full_path.get_extension().to_lower()
				if ext != "":
					unique_extensions[ext] = true
				if ext in ["tscn", "scn"]:
					scene_paths.append(full_path)
		file_name = dir.get_next()
	dir.list_dir_end()

func _populate_extensions():
	# Populate extension list with checkboxes
	var extension_vbox = $MarginContainer/ScrollContainer/VBoxContainer/TabContainer/Extensions/ExtensionsScroll/ExtensionVBox
	visible_extensions = sorted_extensions
	for ext in sorted_extensions:
		var checkbox = CheckBox.new()
		checkbox.text = ext
		checkbox.tooltip_text = "Exclude this extension"
		checkbox.button_pressed = ext.to_lower() in excluded_extensions
		checkbox.toggled.connect(_on_extension_toggled.bind(ext))
		extension_vbox.add_child(checkbox)
		extension_checkboxes[ext] = checkbox

func _on_search_extensions_text_changed(new_text: String):
	# Filter extensions based on search text
	var extension_vbox = $MarginContainer/ScrollContainer/VBoxContainer/TabContainer/Extensions/ExtensionsScroll/ExtensionVBox
	for child in extension_vbox.get_children():
		child.queue_free()
	extension_checkboxes.clear()
	
	visible_extensions = []
	for ext in sorted_extensions:
		if new_text == "" or ext.to_lower().find(new_text.to_lower()) != -1:
			visible_extensions.append(ext)
	
	for ext in visible_extensions:
		var checkbox = CheckBox.new()
		checkbox.text = ext
		checkbox.tooltip_text = "Exclude this extension"
		checkbox.button_pressed = ext.to_lower() in excluded_extensions
		checkbox.toggled.connect(_on_extension_toggled.bind(ext))
		extension_vbox.add_child(checkbox)
		extension_checkboxes[ext] = checkbox

func _on_select_all_extensions_pressed():
	# Exclude all visible extensions
	for ext in visible_extensions:
		extension_checkboxes[ext].button_pressed = true
		if not ext.to_lower() in excluded_extensions:
			excluded_extensions.append(ext.to_lower())
	_update_estimate()

func _on_select_none_extensions_pressed():
	# Clear all visible extension exclusions
	for ext in visible_extensions:
		extension_checkboxes[ext].button_pressed = false
		excluded_extensions.erase(ext.to_lower())
	_update_estimate()

func _populate_folders():
	# Populate folder list with checkboxes
	var folder_vbox = $MarginContainer/ScrollContainer/VBoxContainer/TabContainer/Folders/FoldersScroll/FolderVBox
	visible_folders = sorted_folders
	for folder in sorted_folders:
		var checkbox = CheckBox.new()
		checkbox.text = folder
		checkbox.tooltip_text = "Exclude this folder"
		checkbox.button_pressed = folder in excluded_folders
		checkbox.toggled.connect(_on_folder_toggled.bind(folder))
		folder_vbox.add_child(checkbox)
		folder_checkboxes[folder] = checkbox

func _on_search_folders_text_changed(new_text: String):
	# Filter folders based on search text
	var folder_vbox = $MarginContainer/ScrollContainer/VBoxContainer/TabContainer/Folders/FoldersScroll/FolderVBox
	for child in folder_vbox.get_children():
		child.queue_free()
	folder_checkboxes.clear()
	
	visible_folders = []
	for folder in sorted_folders:
		if new_text == "" or folder.to_lower().find(new_text.to_lower()) != -1:
			visible_folders.append(folder)
	
	for folder in visible_folders:
		var checkbox = CheckBox.new()
		checkbox.text = folder
		checkbox.tooltip_text = "Exclude this folder"
		checkbox.button_pressed = folder in excluded_folders
		checkbox.toggled.connect(_on_folder_toggled.bind(folder))
		folder_vbox.add_child(checkbox)
		folder_checkboxes[folder] = checkbox

func _on_select_all_folders_pressed():
	# Exclude all visible folders
	for folder in visible_folders:
		folder_checkboxes[folder].button_pressed = true
		if not folder in excluded_folders:
			excluded_folders.append(folder)
	_update_estimate()

func _on_select_none_folders_pressed():
	# Clear all visible folder exclusions
	for folder in visible_folders:
		folder_checkboxes[folder].button_pressed = false
		excluded_folders.erase(folder)
	_update_estimate()

func _populate_scenes():
	# Populate scene list with checkboxes
	var scene_vbox = $MarginContainer/ScrollContainer/VBoxContainer/TabContainer/Scenes/ScenesScroll/SceneVBox
	visible_scenes = sorted_scenes
	for file in visible_scenes:
		var file_name = file.get_file()
		var checkbox = CheckBox.new()
		checkbox.text = file_name
		checkbox.tooltip_text = "Exclude this scene"
		checkbox.button_pressed = file in excluded_scenes
		checkbox.toggled.connect(_on_scene_toggled.bind(file))
		scene_vbox.add_child(checkbox)
		scene_checkboxes[file] = checkbox

func _on_search_scenes_text_changed(new_text: String):
	# Filter scenes based on search text
	var scene_vbox = $MarginContainer/ScrollContainer/VBoxContainer/TabContainer/Scenes/ScenesScroll/SceneVBox
	for child in scene_vbox.get_children():
		child.queue_free()
	scene_checkboxes.clear()
	visible_scenes = []
	
	for file in sorted_scenes:
		var file_name = file.get_file()
		if new_text == "" or file_name.to_lower().find(new_text.to_lower()) != -1:
			var checkbox = CheckBox.new()
			checkbox.text = file_name
			checkbox.tooltip_text = "Exclude this scene"
			checkbox.button_pressed = file in excluded_scenes
			checkbox.toggled.connect(_on_scene_toggled.bind(file))
			scene_vbox.add_child(checkbox)
			scene_checkboxes[file] = checkbox
			visible_scenes.append(file)

func _on_select_all_scenes_pressed():
	# Exclude all visible scenes
	for scene_path in visible_scenes:
		scene_checkboxes[scene_path].button_pressed = true
		if not scene_path in excluded_scenes:
			excluded_scenes.append(scene_path)
	_update_estimate()

func _on_select_none_scenes_pressed():
	# Clear all visible scene exclusions
	for scene_path in visible_scenes:
		scene_checkboxes[scene_path].button_pressed = false
		excluded_scenes.erase(scene_path)
	_update_estimate()

func _on_extension_toggled(toggled: bool, ext: String):
	# Toggle exclusion of a file extension
	ext = ext.to_lower()
	if toggled:
		if not ext in excluded_extensions:
			excluded_extensions.append(ext)
	else:
		excluded_extensions.erase(ext)
	_update_estimate()

func _on_folder_toggled(toggled: bool, folder: String):
	# Toggle exclusion of a folder
	if toggled:
		if not folder in excluded_folders:
			excluded_folders.append(folder)
	else:
		excluded_folders.erase(folder)
	_update_estimate()

func _on_scene_toggled(toggled: bool, scene_path: String):
	# Toggle exclusion of a scene
	if toggled:
		if not scene_path in excluded_scenes:
			excluded_scenes.append(scene_path)
	else:
		excluded_scenes.erase(scene_path)
	_update_estimate()

func _is_excluded(file_path: String, excluded_folders: Array, excluded_scenes: Array) -> bool:
	# Check if file is excluded by extension, folder, or scene
	if file_path.get_extension().to_lower() in excluded_extensions:
		return true
	if file_path in excluded_scenes:
		return true
	for folder in excluded_folders:
		if file_path.begins_with(folder + "/"):
			return true
	return false

func _update_estimate():
	# Calculate number of files to export based on exclusions
	var count = 0
	for file in all_files:
		if not _is_excluded(file, excluded_folders, excluded_scenes):
			count += 1
	
	# Update label and trigger color flash if count changes
	var previous_text = estimate_label.text
	var previous_count = int(previous_text.replace("Estimated files to export: ", "")) if previous_text.begins_with("Estimated files to export: ") else 0
	estimate_label.text = "Estimated files to export: %d" % count
	
	if previous_text != estimate_label.text:
		# Set flash color based on count change
		var flash_color = Color.GREEN if count > previous_count else Color.RED
		estimate_label.add_theme_color_override("font_color", flash_color)
		estimate_flash_timer = FLASH_DURATION
		estimate_flash_active = true

func _on_export_pressed():
	# Show file dialog to select export location
	var file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.use_native_dialog = true # Use native file dialog
	file_dialog.mode = FileDialog.MODE_WINDOWED
	file_dialog.initial_position = FileDialog.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	file_dialog.size = Vector2i(1000, 800)
	file_dialog.min_size = Vector2i(800, 600)
	var format = format_option.get_item_text(format_option.selected).split(" ")[0].to_lower()
	var extension
	if format == "json":
		extension = "json"
	elif format == "markdown":
		extension = "md"
	elif format == "text":
		extension = "txt"
	
	var datetime = Time.get_datetime_dict_from_system()
	var timestamp = "%04d-%02d-%02d_%02d-%02d" % [
		datetime.year, datetime.month, datetime.day, datetime.hour, datetime.minute
	]
	file_dialog.current_file = "proj_" + timestamp + "." + extension
	
	file_dialog.file_selected.connect(_on_file_selected.bind(file_dialog, format))
	file_dialog.canceled.connect(file_dialog.queue_free)
	add_child(file_dialog)
	file_dialog.popup_centered()
	
	# Save settings for quick export
	quick_export_config.load(QUICK_EXPORT_CONFIG_PATH)
	quick_export_config.set_value("settings", "preset", preset_option.get_item_text(preset_option.selected))
	quick_export_config.set_value("settings", "format", format_option.get_item_text(format_option.selected).split(" ")[0])
	quick_export_config.save(QUICK_EXPORT_CONFIG_PATH)

func _on_file_selected(path: String, file_dialog: FileDialog, format: String):
	# Export files synchronously
	is_exporting = true
	progress_bar.visible = true
	progress_label.visible = true
	progress_bar.value = 0
	processed_files = 0
	
	var files_to_export = []
	for file in all_files:
		if not _is_excluded(file, excluded_folders, excluded_scenes):
			files_to_export.append(file)
	
	total_files_to_export = files_to_export.size()
	progress_bar.max_value = total_files_to_export
	
	file_dialog.queue_free()
	
	# Save last directory for quick export
	var last_dir = path.get_base_dir()
	quick_export_config.load(QUICK_EXPORT_CONFIG_PATH)
	quick_export_config.set_value("settings", "last_directory", last_dir)
	quick_export_config.save(QUICK_EXPORT_CONFIG_PATH)
	
	var success = _export_files(path, files_to_export, format)
	_on_export_finished(path if success else "")

func start_quick_export(path: String, preset_name: String, format: String):
	# Start quick export with specified settings
	is_quick_export = true
	is_exporting = true
	progress_bar.visible = true
	progress_label.visible = true
	progress_bar.value = 0
	processed_files = 0
	
	# Hide all UI except progress bar and label
	$MarginContainer/ScrollContainer.visible = false
	$SavePresetDialog.visible = false
	$DeletePresetDialog.visible = false
	
	# Apply preset
	if presets.has(preset_name):
		var preset = presets[preset_name]
		excluded_extensions = preset["extensions"].duplicate()
		excluded_folders = preset["folders"].duplicate()
		excluded_scenes = preset["scenes"].duplicate()
	else:
		excluded_extensions = []
		excluded_folders = []
		excluded_scenes = []
	
	var files_to_export = []
	for file in all_files:
		if not _is_excluded(file, excluded_folders, excluded_scenes):
			files_to_export.append(file)
	
	total_files_to_export = files_to_export.size()
	progress_bar.max_value = total_files_to_export
	
	var success = _export_files(path, files_to_export, format)
	_on_export_finished(path if success else "")

func _export_files(path: String, files_to_export: Array, format: String) -> bool:
	# Export files synchronously
	if files_to_export.is_empty():
		_show_error("No files to export")
		return false
	
	var output = []
	for file in files_to_export:
		if not is_exporting:
			return false
		var file_entry = _process_file(file)
		output.append(file_entry)
		processed_files += 1
		progress_bar.value = processed_files
		progress_label.text = "Processing: %d / %d" % [processed_files, total_files_to_export]
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		if format == "json":
			file.store_string(JSON.stringify(output, "    "))
		elif format == "markdown":
			file.store_string(_to_markdown(output))
		elif format == "text":
			file.store_string(_to_text(output))
		file.close()
	else:
		var err = FileAccess.get_open_error()
		_show_error("Failed to write to " + path + ": " + str(err))
		return false
	
	return true

func _process_file(file_path: String) -> Dictionary:
	# Process single file for export, use "N/A" for non-text content
	var entry = {"path": file_path}
	var ext = file_path.get_extension().to_lower()
	
	# Skip reading for known non-text extensions
	if not ext in TEXT_EXTENSIONS:
		entry["content"] = "N/A"
		return entry
	
	# Attempt to read files with text extensions
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var content = file.get_as_text(true) # Permissive mode to attempt reading
		file.close()
		# Check if content is valid text
		if content.strip_edges() == "" or content.is_valid_identifier():
			entry["content"] = "N/A"
		else:
			entry["content"] = content
	else:
		var err = FileAccess.get_open_error()
		print("Failed to read " + file_path + ": " + str(err))
		entry["content"] = "N/A"
	return entry

func _to_text(output: Array) -> String:
	# Convert output to plain text format
	var result = ""
	for file in output:
		result += "File: " + file["path"] + "\n"
		result += file["content"] + "\n"
		result += "\n"
	return result

func _to_markdown(output: Array) -> String:
	# Convert output to Markdown format
	var result = "# Project Context\n\n"
	for file in output:
		result += "## File: " + file["path"] + "\n"
		result += "```\n" + file["content"] + "\n```\n"
		result += "\n"
	return result

func _show_error(message: String):
	# Show error dialog
	var dialog = AcceptDialog.new()
	dialog.dialog_text = message
	dialog.title = "Export Error"
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)

func _show_success_dialog(path: String):
	# Show success dialog and handle cleanup
	print("[Texter]: File generated at " + path)
	var dialog = AcceptDialog.new()
	dialog.dialog_text = "Export completed successfully!\nSaved to: " + path
	dialog.title = "Export Success"
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func(): dialog.queue_free(); _final_cleanup())
	dialog.canceled.connect(func(): dialog.queue_free(); _final_cleanup())

func _final_cleanup():
	# Close window
	queue_free()

func _on_export_finished(path: String):
	# Handle export completion
	is_exporting = false
	progress_bar.visible = false
	progress_label.visible = false
	
	if path:
		if is_quick_export:
			$MarginContainer/ScrollContainer.visible = true
			is_quick_export = false
		call_deferred("_show_success_dialog", path)
	else:
		_show_error("Export failed")

func _on_cancel_pressed():
	# Handle cancel button press
	is_exporting = false
	queue_free()

func _on_close_requested():
	# Handle window close
	is_exporting = false
	queue_free()
