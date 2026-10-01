# Fork notes — local agents edition

This fork turns Coucou into a **pure local coding-agent monitor** and adds **Codex CLI**
support. It is macOS-only.

## Goals

1. **Zero API keys, zero outbound network.** The upstream app polled seven third-party
   clouds (Stripe, Vercel, GitHub, Resend, Notion, Cal.com, n8n) and ran a built-in
   Anthropic chat, all keyed through the macOS Keychain. All of that is removed. The app
   now only talks to coding agents running locally, over a per-user Unix socket.
2. **Watch Codex too.** Codex CLI joins Claude Code, Gemini CLI and Antigravity as a
   first-class monitored agent, including approve/deny from the notch.
3. **macOS only.** The upstream Windows (Tauri) app is dropped.

## What was removed

| Area | Files / symbols |
|---|---|
| Pollers | `VercelPoller`, `ResendPoller`, `GithubPoller`, `StripePoller`, `CalcomPoller`, `NotionPoller`, `N8nPoller` |
| Chat + key store | `ClaudeService.swift` (held the Anthropic chat **and** `KeychainStore`) |
| State | `AppState`: all integration/poller data holders, `claudeModel`, `activeIntegrations`, filters, `chatHistory`, `searchResult`, and the 7 integration pills (only the Claude Code pill remains) |
| Views | `IslandViewContent`: `IntegrationCardView` and every per-service card/detail view, the chat (`PromptView`/`ChatBubble`/`TypingDotsView`) and the search views (`SearchingView`/`ResultView`) |
| Settings | the Anthropic API section, the Integrations key section and the Active-pills toggles |
| Platform | the whole `windows/` app and `.github/workflows/windows.yml` |

Secondary features that depended on the removed pieces were reduced, not deleted:
the file-drop "send by email" flow now uses **Mail.app only** (the Resend path is gone),
and the dead `.prompt` / `.searching` / `.result` views render nothing.

## How Codex monitoring works

Codex's hook system is modelled on Claude Code's, which is why this needed almost no new
plumbing:

```
Codex CLI ──(hook event JSON on stdin)──▶ nb-hook  --agent codex
                                             │   (the SAME relay Claude Code uses)
                                             ▼
                 ~/Library/Application Support/NotchBuddy/nb.sock
                                             │
                                             ▼
                        HookServer ──▶ agent_codex pill in the notch
```

- **Config:** `~/.codex/hooks.json`, same shape as `~/.claude/settings.json`'s `hooks`.
  Written by *Settings → Codex CLI Hooks → Install* (preview + backup + merge, like the
  other installers). `HookServer.buildCodexHooksData()` registers `SessionStart`,
  `SessionEnd`, `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `PermissionRequest`,
  `Stop`, `SubagentStart`, `SubagentStop`, each calling `nb-hook --agent codex <Event>`.
- **Payload:** Codex sends `session_id`, `cwd`, `hook_event_name`, `tool_name`,
  `tool_input`, `prompt` — exactly the field names the relay and `HookServer` already read,
  so no translation is needed.
- **Permissions:** Codex's `PermissionRequest` stdout contract is identical to Claude
  Code's (`{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"allow"}}}`),
  which the relay already emits. The relay gives `PermissionRequest` a 120 s timeout so the
  notch has time to collect your click.
- **Trust:** Codex runs a hook only once its hash is trusted. After installing, run `/hooks`
  inside Codex to trust the Coucou hooks (or `codex exec --dangerously-bypass-hook-trust`
  for a one-off test).

The `nb-hook` relay was already generic over `--agent <name>` (Gemini and Antigravity use
it), so Codex reuses it unchanged. The dynamic `agent_codex` pill is created automatically
by `HookServer` the first time an event arrives — no app-side allowlist.

## Pre-existing upstream behaviours (not changed by this fork)

- A Claude Code session only shows if its terminal reports as VS Code
  (`TERM_PROGRAM`/bundle id contains `vscode`); external agents (Codex, Gemini, …) bypass
  that filter and always show.
- An external-agent pill is removed on every `Stop`. Codex fires `Stop` at the end of each
  turn, so its pill clears between turns.
- All concurrent Codex sessions share one `agent_codex` pill.

## Verification

- `NotchBuddy` and `CoucouAppStore` schemes both build clean (Debug, XcodeGen-generated).
- `scripts/test-safe-links.sh` (15 cases) and `scripts/test-screen-geometry.sh` (13 cases) pass.
- End-to-end: synthetic Codex `SessionStart` / `PreToolUse` payloads piped through the real
  `nb-hook --agent codex` reached the running app as `agent_codex`; a `PermissionRequest`
  round-trip returned the exact allow and deny JSON Codex expects.
