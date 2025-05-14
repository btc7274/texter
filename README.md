Texter Plugin for Godot
A lightweight Godot editor plugin to export project files as JSON, Markdown, or Text files, with customizable presets for file exports.
Features

Project Export: Export all project files with custom presets:
All Files: Includes all files.
Scripts Only: Includes only GDScript files (.gd).
Scenes Only: Includes only scene files (.tscn, .scn).
Core Project: Includes scripts, scenes, and project settings (.gd, .tscn, .scn, .godot).


Quick Context: Export with last used settings and directory using a single click or shortcut (Ctrl+Shift+E).
Custom Presets: Save and manage export settings for quick reuse.
Localization: Supports English UI text, with extensible translation support.
Editor Integration: Access via Tools > Export Context or Tools > Quick Context menu.
Error Handling: Detailed error messages for file access or export issues.
Lightweight: Minimal footprint with no custom styles, using default Godot UI.

Installation

Copy the addons/texter folder to your project's res://addons/ directory.
Enable the plugin in Project > Project Settings > Plugins.
Access via Tools > Export Context or Tools > Quick Context in the Godot editor.

Usage
Export Context

Open Tools > Export Context.
Select a preset or create a custom one by specifying exclusions in the tabs:
Extensions: Exclude specific file extensions.
Folders: Exclude specific folders.
Scenes: Exclude specific scene files.


Choose an output format (JSON, Markdown, Text).
Click Export to open the native system file dialog and choose a location to save the output file (any file extension is allowed).

Quick Context

Open Tools > Quick Context or press Ctrl+Shift+E.
The plugin exports using the last used preset and directory, showing a progress bar and success dialog.
Output is saved to the last used directory with a timestamped filename.

Notes:

The plugin exports all files, including text-based files (e.g., .gd, .tscn, .txt, .json) and non-text files (e.g., .png, .jpg). Non-text files or files that cannot be read as text have their content marked as "N/A" in the output.
Text files are identified by common extensions (e.g., .gd, .tscn, .txt, .json, .md, .cfg, .godot, .ini, .csv). Other files are assumed to be non-text to avoid parsing errors.
The export file dialog uses the native system dialog (e.g., Windows Explorer, Finder) and allows any file extension for the output file.
A log message is printed to the Godot console when the export completes, indicating the file path (e.g., [Texter]: File generated at res://proj_2025-05-14_13-41.json).
For large projects (e.g., thousands of files), the export process may temporarily freeze the editor as it runs synchronously. This cannot be canceled once started.

Configuration

Presets: Save custom presets in res://addons/texter/presets.cfg.
Localization: Add translations to res://addons/texter/translations/ (English included by default).

Compatibility

Godot 4.x

Contributing
See CONTRIBUTING.md for guidelines on reporting issues, submitting pull requests, and coding standards.
License
MIT License. See LICENSE for details.
