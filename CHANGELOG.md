# Changelog

## Fork: local agents edition (mengoh-quandry)

- **Codex CLI support** — install hooks from Settings → Codex CLI Hooks; Codex sessions show up in the notch with approve/deny, alongside Claude Code, Gemini CLI and Antigravity. Codex reuses the existing `nb-hook` relay via `~/.codex/hooks.json`. Run `/hooks` in Codex to trust the hooks after installing.
- **Removed all cloud integrations and the built-in chat** — the Stripe / Vercel / GitHub / Resend / Notion / Cal.com / n8n pills and pollers, the Anthropic chat, and all Keychain API-key storage are gone. The app makes no outbound network connections; it only watches local coding agents. File-drop email now uses Mail.app only.
- **macOS only** — the upstream Windows (Tauri) app has been removed from this fork.
- See `docs/FORK-NOTES.md`.

## Unreleased (upstream)

- Compact island on screens without a notch (#22) — thanks @Kamasoutra
- Only web links (http/https) open from the notch; other kinds of links from Claude or integrations are ignored (#16) — thanks @Cris1670
- Hook socket limited to your own user account, with size and time limits; logs no longer keep commands, n8n data or full URLs, and stay under 1 MB (#16) — thanks @Cris1670 and @Vignesh-Thangamariappan
- The island always reopens after folding, and Settings opens below it, resizable — thanks @rouderz
- Choose the Claude model for the chat in Settings; the list comes from your Anthropic account, and Claude Sonnet 4.6 stays the default — thanks @rouderz
- Windows build artifacts are now downloadable from a manual CI run — thanks @MysJofR
- Any agent can talk to Mochi: tag a hook payload with `coucou_agent` (e.g. `nb-hook --agent my-agent`) and it gets its own pill in the island (#7, #9) — thanks @lacatu5
- Gemini CLI and Antigravity (agy) hook support on macOS: install from Settings and their sessions show up in the island — thanks @corefusiion
