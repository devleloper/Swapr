import os

/// Diagnostics for Console.app / `log stream --predicate 'subsystem == "io.github.devleloper.Swapr"'`.
/// Logs state changes only (permissions, registrations, failures), never keys or text.
enum Log {
    static let hotkeys = Logger(subsystem: "io.github.devleloper.Swapr", category: "hotkeys")
    static let switching = Logger(subsystem: "io.github.devleloper.Swapr", category: "switching")
}
