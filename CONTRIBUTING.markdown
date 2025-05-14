# Contributing to Texter Plugin

Thank you for your interest in contributing to the Texter Plugin for Godot! We welcome contributions to enhance this lightweight tool for exporting project files.

## How to Contribute

- **Report Issues**: Use the GitHub Issues page to report bugs or suggest features. Provide detailed steps to reproduce bugs and context for feature requests.
- **Submit Pull Requests**:
  - Fork the repository and create a branch for your changes (`git checkout -b feature/my-feature`).
  - Follow the coding standards below.
  - Test your changes thoroughly.
  - Submit a pull request with a clear description of the changes and their purpose.
- **Join Discussions**: Participate in discussions on GitHub or contact the maintainer (TBD).

## Coding Standards

- **Language**: Use GDScript for all scripts.
- **Formatting**: Follow Godot’s GDScript style guide (4-space indentation, `snake_case` for variables/functions).
- **Comments**: Add clear comments for complex logic and docstrings for public functions.
- **File Structure**:
  - *Scripts*: `res://addons/texter/scripts/` (e.g., `export_context.gd`, `plugin.gd`).
  - *Scenes*: `res://addons/texter/scenes/` (e.g., `export_context.tscn`).
  - *Translations*: `res://addons/texter/translations/` (e.g., `en.csv`).
  - *Configs*: `res://addons/texter/` (e.g., `presets.cfg`, `quick_export.cfg`).
- **Error Handling**: Use proper error checks for file operations and user inputs.
- **Localization**: Use `tr()` for all UI strings and add translations to `res://addons/texter/translations/`.

## Development Setup

1. Clone the repository: `git clone https://github.com/your-repo/texter.git`.
2. Add the `addons/texter` folder to a Godot project’s `res://addons/` directory.
3. Enable the plugin in `Project > Project Settings > Plugins`.
4. Test your changes in the Godot editor.

## Testing

- Test with small and large projects (e.g., 10,000+ files).
- Verify edge cases like special characters in filenames, file access errors, and large file exports.
- Ensure compatibility with Godot 4.x.
- Confirm that exports include full content for text-based files (.gd, .tscn, .godot, etc.) with "N/A" for non-text files, and respect presets/exclusions.

## Questions?

Reach out via GitHub Issues or contact the maintainer (TBD).

Thank you for helping improve the Texter Plugin!