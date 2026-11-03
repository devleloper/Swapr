# Troubleshooting

## A modifier tap (Right ⌘, ⇧⌘, …) does nothing

1. **Check the permission.** Open Swapr Settings. If you see **Input Monitoring access required**, follow [Granting access](PERMISSIONS.md#granting-access).
2. **Switch is on, but Swapr still asks for access?** This is the most common case. macOS grants Input Monitoring to one exact build of an ad-hoc signed app. After an update or rebuild, or when you run a different copy (for example a Debug build next to the one in Applications), the switch in System Settings still looks on but belongs to the other copy. Fix: quit Swapr, select Swapr in **System Settings › Privacy & Security › Input Monitoring**, remove it with **–**, launch Swapr and grant access again. Keep a single copy of Swapr in `/Applications`.
3. **Restart after granting.** If Settings says **Restart required**, click **Restart Swapr**.
4. **Release cleanly.** The tap fires only when *all* modifiers are released, with no other key, click or scroll in between, within one second. Holding a modifier longer, for example while thinking, cancels the tap.
5. **Password fields.** Taps are ignored while Secure Input is active (password fields, some terminals with *Secure Keyboard Entry*). Check **Terminal › Secure Keyboard Entry** or the equivalent setting in your terminal app.
6. **Remappers.** Tools such as Karabiner-Elements can change which physical key macOS sees as Right ⌘. Record the shortcut again with the remapper active.

## A key combination does nothing

- If the field shows **Couldn't register this shortcut**, another app has claimed it. Pick a different combination or change the other app.
- Some apps capture shortcuts while they are frontmost (games, remote desktop and virtual machine apps). Try in another app.
- Shortcuts with only ⌥/⇧ are refused by design. See the [User Guide](USER_GUIDE.md#key-combinations).

## "Used by macOS" when recording

The shortcut is enabled in **System Settings › Keyboard › Keyboard Shortcuts…**. A common one is ⌃Space (**Input Sources › Select the previous input source**). Disable it there if you want Swapr to use it, then record the shortcut again.

## A layout is missing from Settings

Swapr lists the input sources enabled in **System Settings › Keyboard › Text Input › Input Sources › Edit…**. Add the layout there; Swapr updates its list immediately.

## The menu bar shows the layout, but typing uses the old one

This is a long-standing macOS issue with `TISSelectInputSource` and some complex input methods (Chinese, Japanese, Korean, Vietnamese). The system switches, but the frontmost app picks up the change only after focus moves. Switching between regular keyboard layouts (English, Russian, German, …) is not affected. Workaround: use the system shortcut (⌃Space) for CJKV input methods.

## Launch at login doesn't work

- Make sure Swapr is enabled in **System Settings › General › Login Items › Open at Login / Allow in the Background**.
- Keep Swapr.app in `/Applications`. Login items registered from a temporary location (Downloads, a build folder) may stop working when the app moves.

## The menu bar item disappeared

Either you chose **Show in menu bar › Nothing**, or the menu bar is too crowded (on MacBooks with a notch, items can be hidden behind it). Launch Swapr again from Applications or Spotlight to open Settings.

## "Swapr can't be opened because Apple cannot check it"

Release builds are not notarized. Control-click the app and choose **Open**, or use **System Settings › Privacy & Security › Open Anyway**. Alternatively, [build it yourself](BUILDING.md).

## Resetting everything

```bash
killall Swapr
defaults delete io.github.devleloper.Swapr
tccutil reset ListenEvent io.github.devleloper.Swapr
```

Then launch Swapr again. The welcome screen appears as on first launch.

## Diagnostic logs

Swapr logs state changes (permission status, event tap, registration and switching failures), never keys or text:

```bash
log stream --level info --predicate 'subsystem == "io.github.devleloper.Swapr"'
```

Or open **Console.app** and search for `io.github.devleloper.Swapr`. For example, `Modifier tap monitor: needsPermission` means macOS does not consider this copy of Swapr authorized; see step 2 above.

## Reporting a bug

Open an [issue](https://github.com/devleloper/Swapr/issues/new/choose) with your macOS version, Swapr version (Settings › General › Version), your layouts, the shortcut that fails and the diagnostic log output.
