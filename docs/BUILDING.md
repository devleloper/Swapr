# Building and Releasing

## Requirements

- macOS 14 or later
- Xcode 16 or later. Use Xcode 26 or later to build the Liquid Glass styling; the project uses `glassEffect` APIs from the macOS 26 SDK behind `#available` checks.

If `xcodebuild` reports that the active developer directory is the Command Line Tools, either select Xcode:

```bash
sudo xcode-select -s /Applications/Xcode.app
```

or prefix commands with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.

## Xcode

Open `Swapr.xcodeproj` and run the **Swapr** scheme (⌘R). ⌘U runs the SwaprCore unit tests.

No signing team is needed: the project signs ad hoc ("Sign to Run Locally") with the Hardened Runtime.

## Command line

```bash
# Unit tests (fast, no app build)
swift test --package-path Packages/SwaprCore

# Debug build
xcodebuild -project Swapr.xcodeproj -scheme Swapr -configuration Debug -derivedDataPath build/DerivedData build

# Tests through the Xcode scheme
xcodebuild -project Swapr.xcodeproj -scheme Swapr -derivedDataPath build/DerivedData test

# Release build + zip
./scripts/build-release.sh
```

## UI snapshots

Debug builds can render their windows to PNG in light and dark appearance, without Screen Recording permission:

```bash
build/DerivedData/Build/Products/Debug/Swapr.app/Contents/MacOS/Swapr --snapshot /tmp/swapr-shots
```

The snapshots use your current Swapr settings. Liquid Glass effects are composited by the window server and do not appear in these offscreen renders.

## App icon

The icon is generated from code. After editing [`scripts/make-icon.swift`](../scripts/make-icon.swift), run:

```bash
swift scripts/make-icon.swift
```

## Permissions during development

macOS ties Input Monitoring access to the app's code signature. An ad-hoc signature is a hash of the binary, so **every rebuild, and every Debug/Release copy, is a different app to macOS**. The switch in **Privacy & Security › Input Monitoring** may look on while it belongs to another build; Swapr then keeps showing *Input Monitoring access required*. Key-combination shortcuts are unaffected. After rebuilding, reset and grant again:

```bash
tccutil reset ListenEvent io.github.devleloper.Swapr
```

To keep the permission across rebuilds, sign with a stable certificate instead of ad hoc: an Apple Development certificate (free Apple ID in Xcode › Settings › Accounts), or a self-signed code signing certificate made in Keychain Access › Certificate Assistant › Create a Certificate (type *Code Signing*). Then build with, for example:

```bash
xcodebuild -project Swapr.xcodeproj -scheme Swapr -configuration Debug -derivedDataPath build/DerivedData \
  CODE_SIGN_IDENTITY="<certificate name>" build
```

macOS then identifies Swapr by bundle ID and certificate, so the grant survives rebuilds.

## Versioning

Swapr follows [Semantic Versioning](https://semver.org). The version lives in the target's build settings:

- `MARKETING_VERSION`: user-facing version (`1.2.0`)
- `CURRENT_PROJECT_VERSION`: build number, incremented for every release

## Releasing

1. Update `CHANGELOG.md`: move entries from *Unreleased* to the new version.
2. Bump `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`.
3. Commit (`chore(release): 1.2.0`), merge into `main`, then tag and push:

   ```bash
   git tag v1.2.0
   git push origin v1.2.0
   ```

4. The **Release** workflow builds the app, zips it and creates a draft GitHub Release with the archive attached. Review the notes and publish.

### Developer ID signing and notarization (optional)

Downloads that are notarized open without warnings. This requires a paid Apple Developer account:

```bash
xcodebuild -project Swapr.xcodeproj -scheme Swapr -configuration Release \
  -derivedDataPath build/DerivedData \
  CODE_SIGN_IDENTITY="Developer ID Application" CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM=<TEAM_ID> \
  OTHER_CODE_SIGN_FLAGS=--timestamp build

ditto -c -k --keepParent build/DerivedData/Build/Products/Release/Swapr.app Swapr.zip
xcrun notarytool submit Swapr.zip --keychain-profile <profile> --wait
xcrun stapler staple build/DerivedData/Build/Products/Release/Swapr.app
```

The Hardened Runtime is already enabled, and Swapr needs no entitlements.
