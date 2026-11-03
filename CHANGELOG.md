# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-11-02

### Added

- Global shortcut per keyboard layout.
- Modifier-tap shortcuts: single side-specific modifiers (Right ⌘, Left ⌥, …) and modifier chords (⇧⌘, ⌃⌥, …).
- Key-combination shortcuts (⌃⌥1, F13, …) that need no permissions.
- "Switch to next layout" shortcut with per-layout opt-out.
- Validation against shortcuts without modifiers, ⌥/⇧-only shortcuts, enabled macOS shortcuts and duplicates.
- Menu bar item showing the current layout code, an icon, or nothing.
- Launch at login via `SMAppService`.
- Input Monitoring permission flow with automatic detection of newly granted access.
- Welcome screen on first launch.
- Diagnostic logging of permission, event tap and registration state (no keys or text).
- Light and Dark Mode; Liquid Glass styling on macOS 26 and later.

[Unreleased]: https://github.com/devleloper/Swapr/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/devleloper/Swapr/releases/tag/v1.0.0
