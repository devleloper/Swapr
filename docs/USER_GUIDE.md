# User Guide

## First launch

On first launch Swapr shows a short welcome screen. You can turn on **Launch Swapr at login** there, then click **Set Up Shortcuts** to open Settings. The welcome screen appears only once.

Swapr lives in the menu bar and has no Dock icon.

## Shortcut types

Swapr supports two kinds of shortcuts. You can mix them freely.

### Modifier taps

Press and release modifier keys **without pressing any other key**:

| You press | Recorded as | Triggers on |
| --- | --- | --- |
| Right ⌘ alone | `Right ⌘` | Right ⌘ only (Left ⌘ is different) |
| Left ⌥ alone | `Left ⌥` | Left ⌥ only |
| ⇧ and ⌘ together | `⇧⌘` | ⇧ and ⌘ on either side |

Rules:

- A **single** modifier is side-specific, so Right ⌘ and Left ⌘ can switch to different layouts.
- A **chord** of modifiers works with either side, so ⇧⌘ can be pressed with any ⇧ and any ⌘.
- The tap fires when the last modifier is **released**, only if no other key, click or scroll happened meanwhile and the whole gesture took less than a second. So ⇧⌘S, ⌘-click and ⌘-scroll keep working as usual.
- Modifier taps need the **Input Monitoring** permission ([why](PERMISSIONS.md)).

### Key combinations

A regular key together with modifiers, for example ⌃⌥1, ⌘⇧Space or F13. These need no permissions.

Swapr refuses combinations that would get in the way:

- **No modifier** (for example just `A`): this would block typing. Function keys F1–F20 are the exception.
- **Only ⌥ and/or ⇧** (for example ⌥E): these produce characters, and macOS 15+ restricts such global shortcuts.
- **Used by macOS:** a shortcut enabled in **System Settings › Keyboard › Keyboard Shortcuts**, such as ⌘Space (Spotlight) or ⌃Space (Select the previous input source). Disable it there first if you want Swapr to use it.
- **Already used in Swapr** for another layout or for the cycle.

If another app has registered the same shortcut, Swapr shows *Couldn't register this shortcut* under the field.

## Settings

Open Settings from the menu bar item (**Settings…**, or ⌘, while the menu is open). If you hid the menu bar item, launch Swapr again from Applications or Spotlight.

### Layouts

Every layout enabled in **System Settings › Keyboard › Text Input › Input Sources** is listed with its code (EN, RU, …); the active one is highlighted. Click a field to record a shortcut:

- press a combination, or tap modifiers;
- **⌫** removes the shortcut, **Esc** cancels, clicking elsewhere stops recording;
- the **ⓧ** button next to a field also removes the shortcut.

When you add or remove a layout in System Settings, the list updates immediately. Shortcuts for removed layouts are kept and start working again if you re-enable the layout.

### Cycle

**Switch to next layout** moves through your layouts in the order macOS lists them. With three or more layouts you can uncheck layouts to skip them. New layouts are included automatically.

### General

- **Launch at login:** starts Swapr when you log in. macOS may ask you to approve it in **Login Items**.
- **Show in menu bar:** the current layout code, a keyboard icon, or nothing.
- **Quit Swapr.**

## Menu bar menu

- The list of layouts, with a checkmark on the active one; choose one to switch.
- **Shortcuts Need Attention…** appears when a shortcut can't work (missing permission, registration failed).
- **Settings…** and **Quit Swapr**.

## Uninstalling

1. Quit Swapr from its menu.
2. Delete **Swapr.app**.
3. Optionally remove settings: `defaults delete io.github.devleloper.Swapr`.
4. Optionally remove Swapr from **System Settings › Privacy & Security › Input Monitoring** and **General › Login Items**.
