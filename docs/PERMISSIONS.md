# Permissions

Swapr asks for as little as possible. Each permission is tied to one feature, and nothing is requested unless you use that feature.

| Feature | macOS API | Permission |
| --- | --- | --- |
| Switching layouts | Text Input Sources (`TISSelectInputSource`) | None |
| Key-combination shortcuts | Carbon `RegisterEventHotKey` | None |
| Modifier-tap shortcuts | Listen-only `CGEventTap` | **Input Monitoring** |
| Launch at login | `SMAppService.mainApp` | Your approval in Login Items |
| Conflict detection | Carbon `CopySymbolicHotKeys` | None |

Swapr does **not** use Accessibility, Screen Recording, Automation, Full Disk Access or the network.

## Input Monitoring

### Why it's needed

macOS offers no API for "tell me when Right ⌘ is tapped". The only way to see modifier keys system-wide is an event tap, and macOS requires Input Monitoring for any tap that observes the keyboard.

### What Swapr does with it

The tap is created with `kCGEventTapOptionListenOnly`, so it is passive: it cannot modify, inject or block events. It observes:

- **modifier changes** (`flagsChanged`): which modifier keys are currently held;
- **key presses** (`keyDown`), **clicks** and **scrolls**: only the event *type* is used, to cancel a tap in progress (so ⇧⌘S does not count as a ⇧⌘ tap). Swapr does not read the key code or characters of key presses.

Nothing is logged, stored or transmitted. Swapr contains no networking code. You can verify all of this in [`ModifierTapMonitor.swift`](../Swapr/Services/ModifierTapMonitor.swift); it is under 100 lines.

The tap exists only while at least one modifier-tap shortcut is configured. Remove all modifier taps and the tap is removed too.

While **Secure Input** is active (for example in password fields), macOS hides key presses from event taps. Swapr ignores modifier taps during Secure Input, so pressing ⌘V in a password field cannot switch your layout by mistake.

### Granting access

1. Record a modifier-tap shortcut. Settings shows **Input Monitoring access required**.
2. Click **Open Privacy Settings…**. On first use macOS shows its own prompt, which also links to System Settings.
3. In **System Settings › Privacy & Security › Input Monitoring**, turn on **Swapr**.
4. Return to Swapr. Swapr checks every two seconds while access is missing, so shortcuts start working as soon as you flip the switch.

If Settings then says **Restart required**, click **Restart Swapr**. Some macOS versions apply new access only to newly started processes.

### Revoking access

Turn Swapr off in the same pane. Modifier taps stop working; key-combination shortcuts keep working.

## Launch at login

Swapr registers itself with `SMAppService.mainApp`, the modern replacement for login helper apps. macOS may notify you that a login item was added, or ask for approval in **System Settings › General › Login Items**. Swapr shows a shortcut to that pane when approval is pending.

## Why no App Sandbox?

The App Sandbox blocks reading the system shortcut list that Swapr uses for conflict detection, and makes the behaviour of input source switching and event taps harder to predict across macOS versions. Swapr is built with the **Hardened Runtime** instead and has no entitlements at all. Offline operation is guaranteed by the code itself, which contains no networking APIs.
