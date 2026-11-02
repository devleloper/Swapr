# Contributing to Swapr

Thanks for your interest! Swapr is intentionally small, so please read the scope section before writing code.

## Scope

Swapr switches keyboard layouts with global shortcuts and does nothing else. Contributions that make that more reliable, correct, accessible or efficient are very welcome. Features outside that scope (auto-correction of mistyped text, text conversion, statistics, sounds, clipboard tools) will be declined to keep the app focused and trustworthy. When in doubt, open an issue first.

Hard rules:

- No networking code of any kind.
- Never read, log or store typed characters or key codes of regular keys.
- No new permissions without a strong case discussed in an issue.
- No third-party dependencies without prior discussion.

## Getting started

1. Fork and clone the repository.
2. Open `Swapr.xcodeproj` in Xcode 16+ (Xcode 26+ recommended).
3. Run the tests: ⌘U, or `swift test --package-path Packages/SwaprCore`.
4. Read [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Branching

The project uses a simplified Git Flow:

| Branch | Purpose |
| --- | --- |
| `main` | Released code only. Every commit on `main` is a tagged release. |
| `develop` | Integration branch. Pull requests target `develop`. |
| `feature/<short-name>` | New functionality, branched from `develop`. |
| `fix/<short-name>` | Bug fixes, branched from `develop`. |
| `hotfix/<short-name>` | Urgent fixes, branched from `main`, merged into `main` and `develop`. |

## Commit messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<optional scope>): <description>

[optional body]

[optional footer, e.g. "Fixes #12"]
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`. Scopes in use: `core`, `app`, `ui`, `hotkeys`, `docs`, `ci`, `release`.

Examples:

```
feat(hotkeys): support Fn as a modifier tap
fix(app): stop recording when the settings window loses focus
docs: explain Input Monitoring reset after rebuilding
```

Use `!` after the type or a `BREAKING CHANGE:` footer for breaking changes (for example, an incompatible settings format).

## Code style

- Swift 6 language mode, strict concurrency; no warnings.
- Follow the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/) and the style of the surrounding code.
- Keep domain logic in `SwaprCore` (Foundation only) and cover it with tests. Keep macOS adapters in `Swapr/Services` thin.
- Prefer simple, concrete code over abstractions that have a single implementation.
- Comments explain *why*, not *what*.
- UI text is in English, uses macOS terminology (System Settings, Input Monitoring) and the standard modifier symbols (⌃⌥⇧⌘).

## Pull requests

1. Create a branch from `develop`.
2. Make focused changes with tests where applicable.
3. Make sure `swift test --package-path Packages/SwaprCore` and the Xcode build pass without warnings.
4. Update `CHANGELOG.md` under **Unreleased** and the docs if behaviour changes.
5. Open a pull request against `develop` and fill in the template. For UI changes, include light and dark screenshots (`Swapr --snapshot <dir>` in Debug builds helps).

CI must be green before merge. Pull requests are squash-merged with a Conventional Commit title.

## Reporting bugs and requesting features

Use the [issue templates](https://github.com/devleloper/Swapr/issues/new/choose). For security or privacy issues, follow [SECURITY.md](SECURITY.md) instead of opening a public issue.

## Code of Conduct

By participating you agree to the [Code of Conduct](CODE_OF_CONDUCT.md).
