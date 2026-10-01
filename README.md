<div align="center">

<img src="NotchBuddy/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" width="96" alt="Coucou icon">

# Coucou — local agents fork

**A tiny friend that lives in your Mac's notch and keeps an eye on your coding-agent sessions — Claude Code, Codex, Gemini CLI and Antigravity.**

Approve permissions and watch your agents work, all without leaving what you're doing. **No API keys, no cloud integrations, no telemetry — it only ever talks to agents running on your own machine.**

![macOS 15+](https://img.shields.io/badge/macOS-15%2B-black?logo=apple)
![Swift 6](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)
![SwiftUI](https://img.shields.io/badge/SwiftUI-native-0A84FF)
![License: MIT](https://img.shields.io/badge/license-MIT-green)

</div>

---

## About this fork

This is a fork of [Louis-CFM/coucou](https://github.com/Louis-CFM/coucou), trimmed down to a **pure local coding-agent monitor**:

- **Removed** everything that needed an API key or talked to a third-party cloud: the Stripe / Vercel / GitHub / Resend / Notion / Cal.com / n8n integration pills and their pollers, the built-in Anthropic chat, and all Keychain key storage. The app now makes **no outbound network connections**.
- **Added Codex CLI** as a first-class monitored agent, alongside Claude Code, Gemini CLI and Antigravity.
- **macOS only.** The upstream Windows (Tauri) app has been dropped from this fork.

See [`docs/FORK-NOTES.md`](docs/FORK-NOTES.md) for the full design and the Codex wiring.

## What it does

Meet **Mochi**: a soft little squircle with big eyes that pops out of your notch, waves hello, follows your cursor, and tells you the moment one of your coding agents needs you.

- 🤖 **Claude Code, Codex, Gemini CLI and Antigravity, live** — see every session in your notch: what it reads, edits and runs, step by step. Finished? Mochi does a happy little jump.
- ✅ **Approve from the notch** — permission requests show up with **Allow / Deny**. One click, back to work. Works for Claude Code and Codex.
- 🧑‍💻 **Jump to the right terminal** — open the terminal window of a session.
- 📎 **Drop a file on the notch** — Mochi turns into a box and swallows it, then send it by email via Mail.app.
- 🪟 **Drag Mochi onto any window** — attach that window as context.
- 🎭 **A real character** — idle breathing, blinks, eyes on a sphere that follow your mouse, emotes, 28 handcrafted sounds, a greeting on launch.
- 🫥 **Invisible when idle** — hides away when nothing is running, peeks out when you hover the notch.
- 🖥️ **Any Mac, notch or not** — on an iMac, Mac mini, or a closed-lid MacBook on an external display, Mochi sits in a small bar at the top of the screen.
- 🔒 **Private by design, for real** — no telemetry, no account, no API keys, no outbound connections. Everything stays between the app and the agents on your Mac.

## Build from source

Requirements: macOS 15+, Xcode 16+, [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen
git clone https://github.com/mengoh-quandry/coucou.git
cd coucou/NotchBuddy
xcodegen
open NotchBuddy.xcodeproj   # then ⌘R
```

## Setup

Click the Coucou icon in the menu bar → **Settings…**, then install hooks for the agents you use. Each installer backs up the target file and shows you the exact diff before writing anything.

| Agent | What to do | What it writes |
|---|---|---|
| **Claude Code** | Settings → **Claude Code Hooks → Install** | merges into `~/.claude/settings.json` |
| **Codex CLI** | Settings → **Codex CLI Hooks → Install**, then run `/hooks` inside Codex to **trust** them | merges into `~/.codex/hooks.json` |
| **Gemini CLI** | Settings → **Gemini CLI Hooks → Install** | merges into `~/.gemini/settings.json` |
| **Antigravity** | Settings → **Antigravity Hooks → Install** | merges into `~/.gemini/config/hooks.json` |

> **Codex trust step:** Codex only runs a hook once its hash is trusted. After installing, open Codex and run `/hooks` to review and trust the Coucou hooks, then restart Codex. (For a one-off test you can run `codex exec --dangerously-bypass-hook-trust "..."`.)

If Coucou isn't running, every hook exits immediately: **your agent is never blocked.**

## How it works

- **Island**: a borderless `NSPanel` hugging the notch, driven by a small state machine.
- **Character**: drawn in SwiftUI `Canvas` + `TimelineView` at 60 fps — squircle body, eyes projected on a sphere, spring animations. No Rive, no Lottie, no images.
- **Agents**: a tiny `nb-hook` relay receives hook events from each agent and forwards them over a per-user Unix socket to the app, dropping the large/sensitive fields (`tool_response`, transcript paths) and capping field sizes. For approvals it waits for your click, then answers the hook. Claude Code, Codex, Gemini and Antigravity all share this one relay — Codex works because its hook format, event names and PermissionRequest contract match Claude Code's.
- **Sounds**: 28 short WAVs played through preloaded `AVAudioPlayer`s.

Native Swift 6 / SwiftUI / AppKit with **zero third-party dependencies**.

## Credits

Original app built by [Louis Raillé](https://louisraille.fr). This local-agents fork keeps the upstream MIT code; the Mochi character, name, icon, sounds and media remain © Louis Raillé (see [LICENSE-ASSETS.md](LICENSE-ASSETS.md)) — if you redistribute a fork publicly, give it your own name and character.

## License

- **Code:** [MIT](LICENSE).
- **Name, Mochi character, icon, sounds and media:** © Louis Raillé, all rights reserved — see [LICENSE-ASSETS.md](LICENSE-ASSETS.md).
