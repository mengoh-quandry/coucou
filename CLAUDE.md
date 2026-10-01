# Coucou — guide for AI coding agents

Coucou is a native macOS app: Mochi, a small animated character living in the MacBook notch, shows Claude Code sessions and a few integrations, and lets the user approve, answer, chat and drop files from the notch.

## Where things are
- `NotchBuddy/Sources/App/` — all Swift code. `NotchBuddy/Resources/sounds/` — the 28 WAV sounds. `NotchBuddy/project.yml` — XcodeGen project (never edit the `.xcodeproj` by hand).
- `docs/SPEC.md`, `docs/INTEGRATIONS.md` — behaviour, views, states, integrations (in French).
- `design/prototype/notch-buddy.html` — original prototype, the visual source of truth. `design/captures/` — target screenshots.
- `docs/*.html` — the GitHub Pages site (privacy, terms, support, legal notice).

## Build
```
cd NotchBuddy && xcodegen && xcodebuild -scheme NotchBuddy -configuration Debug build
```

## Rules
- Swift 6, SwiftUI + AppKit. No third-party dependencies unless truly unavoidable. The character is drawn in code (`Canvas` + `TimelineView`), no Rive/Lottie/images.
- This fork is a pure local coding-agent monitor: no API keys, no secrets, no telemetry, and **no outbound network calls** — keep it that way (the cloud integrations and chat were removed; see `docs/FORK-NOTES.md`).
- Never block an agent: if the app doesn't answer, the hook relay exits immediately.
- Never overwrite `~/.claude/settings.json` or `~/.codex/hooks.json`: dated backup, merge, show the diff, write only after the user confirms.
- Never send an email or approve a permission request without an explicit click.
- Performance: 0 % CPU when the island is hidden.
- Bundle identifier is `com.mengohlabs.NotchLee`. The hook relay and socket live at a fixed path (`~/Library/Application Support/NotchBuddy/`), independent of the app name — do not derive it from the bundle id, or installed hooks break.
- Monitored agents: Claude Code, Codex CLI, Gemini CLI, Antigravity — all through the one `nb-hook` relay, tagged with `--agent <name>` for anything but Claude Code.
- Visual changes must match the prototype and the screenshots in `design/captures/`.
