# Architecture

Swapr is deliberately small. The design goal is a codebase a reviewer can read in one sitting and trust with keyboard input.

## Layers

```
┌───────────────────────────────────────────────────────────────┐
│ Swapr (app target)                                            │
│                                                               │
│  UI/        SwiftUI views, menu bar, window presentation      │
│     │                                                         │
│  App/       AppModel: state + use cases, composition root     │
│     │                                                         │
│  Services/  Adapters to macOS: TIS, Carbon hotkeys,           │
│             CGEventTap, SMAppService, TCC, system shortcuts   │
└──────┬────────────────────────────────────────────────────────┘
       │ depends on
┌──────▼────────────────────────────────────────────────────────┐
│ SwaprCore (local Swift package, Foundation only)              │
│                                                               │
│  Models/       InputSource, Hotkey, Settings                  │
│  Hotkeys/      ModifierTapDetector, HotkeyRecorder,           │
│                HotkeyValidator, HotkeyFormatter, KeyCodes     │
│  Switching/    LayoutCycler                                   │
│  Persistence/  SettingsStore (versioned JSON in UserDefaults) │
└───────────────────────────────────────────────────────────────┘
```

- **SwaprCore** has the domain logic and nothing platform-specific beyond Foundation: no AppKit, Carbon or CoreGraphics. Everything in it is pure or value-typed and covered by unit tests ([`Packages/SwaprCore/Tests`](../Packages/SwaprCore/Tests)).
- **Services** are thin adapters, each wrapping one macOS API. They translate between system types and Core types and hold no business rules.
- **AppModel** is the single `@Observable` source of truth. It loads and saves settings, validates shortcuts, turns settings into hotkey registrations and routes triggers to layout switching.
- **UI** renders `AppModel` state and calls its methods. Views own no business logic.

Protocols and dependency injection are used only where they pay for themselves. The adapters are concrete because each has exactly one implementation and the logic worth testing lives in Core.

## Data flow

```
Settings change (UI) ──► AppModel.update ──► SettingsStore.save
                                       └──► applyHotkeys()
                                              ├─► KeyComboHotkeys.register(combos)
                                              └─► ModifierTapMonitor.start/stop

Key combination ──► Carbon hotkey event ──► KeyComboHotkeys.onTrigger ─┐
Modifier tap    ──► CGEventTap ──► ModifierTapDetector ──► onTap ──────┤
Menu item       ───────────────────────────────────────────────────────┤
                                                                       ▼
                                     AppModel.perform(action) ──► InputSourceService.select
                                                                       │
              Distributed notification (selected source changed) ◄─────┘
                         └─► InputSourceService.currentID ──► menu bar label
```

`applyHotkeys()` is idempotent and cheap. It runs on every relevant change: settings, enabled layouts, permission state, recording state, app activation. This keeps the system registration state in sync without incremental bookkeeping.

## Key decisions

### Two hotkey mechanisms

| | Key combinations | Modifier taps |
| --- | --- | --- |
| API | Carbon `RegisterEventHotKey` | Listen-only `CGEventTap` |
| Permission | none | Input Monitoring |
| Consumes the key event | yes | no (passive) |

`RegisterEventHotKey` is old, but it is still the only public API for system-wide shortcuts without permissions, and it is what the system and most shortcut libraries use. It cannot express "a modifier alone", so modifier taps need an event tap. The tap is installed only when a modifier tap is configured.

### Modifier tap recognition

[`ModifierTapDetector`](../Packages/SwaprCore/Sources/SwaprCore/Hotkeys/ModifierTapDetector.swift) is a pure state machine:

1. The first modifier press starts a gesture.
2. Every modifier change adds to the gesture's *peak* set.
3. Any other input (key press, click, scroll, Caps Lock, Fn) marks the gesture as interrupted.
4. When the last modifier is released, the peak set is reported if the gesture wasn't interrupted and took at most one second.

Which modifiers are held is decoded from the device-dependent bits of the event flags (`NX_DEVICE*KEYMASK`) on every event, not tracked incrementally. So a missed event cannot leave a key "stuck".

### Input source switching

`TISSelectInputSource` is the only public API for switching. Swapr lists enabled, selectable keyboard sources (`kTISTypeKeyboardLayout`, `kTISTypeKeyboardInputMode`, `kTISTypeKeyboardInputMethodWithoutModes`) and observes `kTISNotifySelectedKeyboardInputSourceChanged` and `kTISNotifyEnabledKeyboardInputSourcesChanged`. It never polls.

### Settings

Settings are a single `Codable` struct, stored as versioned JSON (`{"version": 1, "settings": {...}}`) under one `UserDefaults` key. Decoding tolerates missing and unknown fields, so settings survive upgrades and downgrades. Launch at login is deliberately not stored: `SMAppService` is the source of truth.

Shortcuts are keyed by input source ID. Bindings for layouts that are currently disabled are kept and become active again when the layout is re-enabled.

### Validation

[`HotkeyValidator`](../Packages/SwaprCore/Sources/SwaprCore/Hotkeys/HotkeyValidator.swift) rejects shortcuts that would silently fail or break typing: no modifier, ⌥/⇧ only, enabled macOS shortcuts (read via `CopySymbolicHotKeys`), and duplicates. Conflicts with other apps can only be detected when registration fails; that is reported per field.

### Windows

The app is an `LSUIElement` agent with a SwiftUI `MenuBarExtra`. The Welcome and Settings screens share one `NSWindow` created on demand by [`WindowPresenter`](../Swapr/UI/WindowPresenter.swift) and released on close. AppKit window management is used instead of SwiftUI `Window`/`Settings` scenes because opening and focusing those from an agent app is unreliable on macOS 14.

### Concurrency

The app target builds in Swift 6 language mode with complete concurrency checking. Everything stateful is `@MainActor`. Carbon and event-tap callbacks are C function pointers that macOS calls on the main run loop, and they enter the main actor with `MainActor.assumeIsolated`.

### Memory and CPU

- No timers while idle. The one timer polls Input Monitoring status every 2 s, and only while a modifier tap is configured but access is missing.
- The event tap callback does a few set operations and returns.
- The window and its view hierarchy are deallocated when closed.
- Long-lived C callbacks (`InstallEventHandler`, `CGEventTap`) hold unretained pointers to objects owned by `AppModel` for the whole app lifetime. The event tap is invalidated whenever it is no longer needed.

## Project layout

```
Swapr/
├── Swapr.xcodeproj           Xcode project (file-system synchronized groups)
├── Swapr/                    App target sources
│   ├── App/                  Entry point, AppDelegate, AppModel, debug snapshots
│   ├── Services/             macOS adapters
│   ├── UI/                   SwiftUI views and window presenter
│   └── Resources/            Asset catalog (app icon)
├── Packages/SwaprCore/       Domain logic + tests (Swift Testing)
├── scripts/                  build-release.sh, make-icon.swift
├── docs/                     Documentation and images
└── .github/                  CI, issue and PR templates
```

The project uses Xcode 16+ *file-system synchronized groups*, so adding a file to `Swapr/` adds it to the target with no project file changes and fewer merge conflicts.
