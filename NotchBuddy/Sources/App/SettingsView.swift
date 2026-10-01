import SwiftUI
import ServiceManagement
import AppKit

struct SettingsView: View {
    @ObservedObject private var state = AppState.shared

    @State private var launchAtStartup: Bool = (SMAppService.mainApp.status == .enabled)
    @State private var statusMessage: String = ""
    @State private var showDiff: Bool = false
    @State private var pendingHookJSON: String = ""
    @State private var hookNeedsUpdate: Bool = HookServer.hooksNeedUpdate()

    #if !APPSTORE
    @State private var geminiHooksInstalled: Bool = HookServer.geminiHooksInstalled()
    @State private var showGeminiDiff: Bool = false
    @State private var pendingGeminiJSON: String = ""
    @State private var geminiPendingInstall: Bool = true

    @State private var agyHooksInstalled: Bool = HookServer.agyHooksInstalled()
    @State private var showAgyDiff: Bool = false
    @State private var pendingAgyJSON: String = ""
    @State private var agyPendingInstall: Bool = true

    @State private var codexHooksInstalled: Bool = HookServer.codexHooksInstalled()
    @State private var showCodexDiff: Bool = false
    @State private var pendingCodexJSON: String = ""
    @State private var codexPendingInstall: Bool = true
    #endif

    // Hotkey
    @State private var hotkeyFlags: UInt    = AppState.shared.hotkeyFlags
    @State private var hotkeyCode: UInt16   = AppState.shared.hotkeyCode

    // Bindings in minutes for the absence field
    private var absenceMinutes: Binding<Double> {
        Binding(
            get: { state.absenceInterval / 60 },
            set: { state.absenceInterval = max(1, $0) * 60 }
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {

                // MARK: Hooks
                GroupBox("Claude Code Hooks") {
                    VStack(alignment: .leading, spacing: 10) {
                        if hookNeedsUpdate {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Hook timeout outdated — update to fix approvals")
                                    .font(.system(size: 11))
                                    .foregroundColor(.orange)
                            }
                            #if APPSTORE
                            Button("Update hooks") { installHooksAppStore() }
                            #else
                            Button("Update hooks") { installHooks() }
                            #endif
                        }
                        #if APPSTORE
                        Text("~/.claude/coucou/nb-hook")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                        HStack(spacing: 10) {
                            Button("Install hooks") { installHooksAppStore() }
                                .buttonStyle(.borderedProminent)
                            Button("Uninstall") { uninstallHooksAppStore() }
                                .buttonStyle(.bordered)
                        }
                        #else
                        Text("nb-hook : \(HookServer.hookScriptPath)")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                        HStack(spacing: 10) {
                            Button("Install hooks") { installHooks() }
                                .buttonStyle(.borderedProminent)
                            Button("Uninstall") { uninstallHooks() }
                                .buttonStyle(.bordered)
                        }
                        #endif

                        #if !APPSTORE
                        if showDiff {
                            ScrollView {
                                Text(pendingHookJSON)
                                    .font(.system(size: 10, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(height: 140)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(6)

                            HStack {
                                Button("Confirm & write") { confirmInstall() }
                                    .buttonStyle(.borderedProminent)
                                Button("Cancel") { showDiff = false; pendingHookJSON = "" }
                                    .buttonStyle(.bordered)
                            }
                        }
                        #endif
                    }
                    .padding(6)
                }

                // MARK: Codex CLI / Gemini CLI / Antigravity Hooks
                #if !APPSTORE
                GroupBox("Codex CLI Hooks") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(codexHooksInstalled
                             ? "Hooks installed — run /hooks in Codex to trust them, then restart Codex"
                             : "~/.codex/hooks.json")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                        HStack(spacing: 10) {
                            Button("Install hooks") { triggerCodexPreview(install: true) }
                                .buttonStyle(.borderedProminent)
                            Button("Uninstall") { triggerCodexPreview(install: false) }
                                .buttonStyle(.bordered)
                        }
                        if showCodexDiff {
                            ScrollView {
                                Text(pendingCodexJSON)
                                    .font(.system(size: 10, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(height: 140)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(6)
                            HStack {
                                Button("Confirm & write") { confirmCodexOp() }
                                    .buttonStyle(.borderedProminent)
                                Button("Cancel") { showCodexDiff = false; pendingCodexJSON = "" }
                                    .buttonStyle(.bordered)
                            }
                        }
                        Text("After installing, open Codex and run /hooks to review and trust the Coucou hooks.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .padding(6)
                }

                GroupBox("Gemini CLI Hooks") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(geminiHooksInstalled
                             ? "Hooks installed — restart Gemini CLI to activate"
                             : "~/.gemini/settings.json")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                        HStack(spacing: 10) {
                            Button("Install hooks") { triggerGeminiPreview(install: true) }
                                .buttonStyle(.borderedProminent)
                            Button("Uninstall") { triggerGeminiPreview(install: false) }
                                .buttonStyle(.bordered)
                        }
                        if showGeminiDiff {
                            ScrollView {
                                Text(pendingGeminiJSON)
                                    .font(.system(size: 10, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(height: 140)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(6)
                            HStack {
                                Button("Confirm & write") { confirmGeminiOp() }
                                    .buttonStyle(.borderedProminent)
                                Button("Cancel") { showGeminiDiff = false; pendingGeminiJSON = "" }
                                    .buttonStyle(.bordered)
                            }
                        }
                    }
                    .padding(6)
                }

                GroupBox("Antigravity Hooks") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(agyHooksInstalled
                             ? "Hooks installed — restart Antigravity to activate"
                             : "~/.gemini/config/hooks.json")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                        HStack(spacing: 10) {
                            Button("Install hooks") { triggerAgyPreview(install: true) }
                                .buttonStyle(.borderedProminent)
                            Button("Uninstall") { triggerAgyPreview(install: false) }
                                .buttonStyle(.bordered)
                        }
                        if showAgyDiff {
                            ScrollView {
                                Text(pendingAgyJSON)
                                    .font(.system(size: 10, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(height: 140)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(6)
                            HStack {
                                Button("Confirm & write") { confirmAgyOp() }
                                    .buttonStyle(.borderedProminent)
                                Button("Cancel") { showAgyDiff = false; pendingAgyJSON = "" }
                                    .buttonStyle(.bordered)
                            }
                        }
                    }
                    .padding(6)
                }
                #endif

                // MARK: Son
                GroupBox("Sound") {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Enable sounds", isOn: $state.soundEnabled)
                        HStack(spacing: 8) {
                            Text("Volume")
                                .frame(width: 56, alignment: .leading)
                            Slider(value: $state.soundVolume, in: 0...0.2)
                                .disabled(!state.soundEnabled)
                            Text("\(Int(state.soundVolume / 0.2 * 100)) %")
                                .frame(width: 36, alignment: .trailing)
                                .monospacedDigit()
                        }
                    }
                    .padding(6)
                }

                // MARK: Timings
                GroupBox("Behavior") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Text("Close after")
                            TextField("60", value: $state.autoCloseInterval, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 64)
                            Text("s inactive")
                        }
                        HStack(spacing: 8) {
                            Text("Hide after")
                            TextField("3", value: absenceMinutes, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 48)
                            Text("min without movement")
                        }
                    }
                    .padding(6)
                }

                // MARK: Island appearance & behavior
                GroupBox("Island") {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Liquid Glass", isOn: $state.liquidGlass)
                        Toggle("Expand on hover (not just peek)", isOn: $state.expandOnHover)
                        HStack(spacing: 8) {
                            Text("Position")
                                .frame(width: 64, alignment: .leading)
                            Slider(value: $state.islandXOffset, in: -400...400, step: 1)
                            Button("Center") { state.islandXOffset = 0 }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                        }
                        Text("Horizontal offset from the notch (0 = centered). Best as a nudge; the physical notch stays centered.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .padding(6)
                }

                // MARK: Hotkey
                GroupBox("Hotkey") {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Show island with shortcut", isOn: $state.hotkeyEnabled)
                        if state.hotkeyEnabled {
                            HStack(spacing: 8) {
                                Text("Shortcut")
                                    .frame(width: 70, alignment: .leading)
                                ShortcutRecorderButton(flags: $hotkeyFlags, code: $hotkeyCode)
                                    .onChange(of: hotkeyFlags) { _, v in state.hotkeyFlags = v }
                                    .onChange(of: hotkeyCode)  { _, v in state.hotkeyCode  = v }
                                Text("presses this → island opens")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(6)
                }

                // MARK: Startup
                GroupBox("Startup") {
                    Toggle("Launch at Mac startup", isOn: $launchAtStartup)
                        .onChange(of: launchAtStartup) { _, on in toggleStartup(on) }
                        .padding(6)
                }

                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(.system(size: 12))
                        .foregroundColor(statusMessage.hasPrefix("❌") ? .red : .secondary)
                        .padding(.horizontal, 2)
                }

                Spacer(minLength: 0)
            }
            .padding(20)
        }
        .frame(minWidth: 420, maxWidth: .infinity, minHeight: 320, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func toggleStartup(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() }
            else  { try SMAppService.mainApp.unregister() }
        } catch {
            statusMessage = "❌ Startup: \(error.localizedDescription)"
            launchAtStartup = !on
        }
    }

    // MARK: - App Store: hooks via NSOpenPanel + security-scoped bookmark

    #if APPSTORE
    /// Opens NSOpenPanel to select ~/.claude, then writes hooks directly.
    /// NSOpenPanel grants sandbox access immediately — no security-scoped bookmark needed.
    private func pickClaudeFolder(prompt: String) -> URL? {
        let panel = NSOpenPanel()
        panel.message = "Select your .claude folder (press ⇧⌘. to show hidden files)"
        panel.prompt = prompt
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.showsHiddenFiles = true
        // getpwuid bypasses CFFIXED_USER_HOME and always returns the real user home
        let realHomePath = getpwuid(getuid()).flatMap { String(cString: $0.pointee.pw_dir, encoding: .utf8) }
            ?? "/Users/\(NSUserName())"
        panel.directoryURL = URL(fileURLWithPath: realHomePath)
        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        guard url.lastPathComponent == ".claude" else {
            statusMessage = "❌ Select the .claude folder (hidden, in your Home directory)."
            return nil
        }
        return url
    }

    private func installHooksAppStore() {
        guard let claudeURL = pickClaudeFolder(prompt: "Select") else { return }
        let alert = NSAlert()
        alert.messageText = "Install Coucou hooks in ~/.claude?"
        alert.informativeText = "Will write:\n• ~/.claude/coucou/nb-hook\n• ~/.claude/settings.json (backup created first)"
        alert.addButton(withTitle: "Install")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .informational
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        do {
            try HookServer.shared.installAndWriteClaudeHooksAppStore(claudeURL: claudeURL)
            hookNeedsUpdate = false
            statusMessage = "✓ Hooks installed — restart VS Code to activate."
        } catch {
            statusMessage = "❌ \(error.localizedDescription)"
        }
    }

    private func uninstallHooksAppStore() {
        guard let claudeURL = pickClaudeFolder(prompt: "Select") else { return }
        do {
            try HookServer.shared.uninstallClaudeHooksAppStore(claudeURL: claudeURL)
            statusMessage = "✓ Hooks removed."
        } catch {
            statusMessage = "❌ \(error.localizedDescription)"
        }
    }
    #endif

    private func installHooks() {
        do {
            pendingHookJSON = try HookServer.shared.previewClaudeHooks()
            showDiff = true
            statusMessage = "Review the JSON below before confirming."
        } catch {
            statusMessage = "❌ \(error.localizedDescription)"
        }
    }

    private func confirmInstall() {
        do {
            try HookServer.shared.writeClaudeHooks()
            showDiff = false
            statusMessage = "✓ Hooks installed in ~/.claude/settings.json"
            pendingHookJSON = ""
            hookNeedsUpdate = false
        } catch {
            statusMessage = "❌ Write error: \(error.localizedDescription)"
        }
    }

    private func uninstallHooks() {
        do {
            try HookServer.shared.uninstallClaudeHooks()
            statusMessage = "✓ Hooks removed."
        } catch {
            statusMessage = "❌ \(error.localizedDescription)"
        }
    }

    #if !APPSTORE
    private func triggerCodexPreview(install: Bool) {
        do {
            codexPendingInstall = install
            pendingCodexJSON = try HookServer.shared.previewCodexHooks(install: install)
            showCodexDiff = true
            statusMessage = "Review the JSON below before confirming."
        } catch let e as NSError where e.domain == "CoucouNoop" {
            statusMessage = e.localizedDescription
        } catch {
            statusMessage = "❌ \(error.localizedDescription)"
        }
    }

    private func confirmCodexOp() {
        do {
            try HookServer.shared.writeCodexHooks()
            showCodexDiff = false
            pendingCodexJSON = ""
            codexHooksInstalled = codexPendingInstall
            statusMessage = codexPendingInstall
                ? "✓ Codex hooks installed in ~/.codex/hooks.json — run /hooks in Codex to trust them."
                : "✓ Codex hooks removed."
        } catch {
            statusMessage = "❌ \(error.localizedDescription)"
        }
    }

    private func triggerGeminiPreview(install: Bool) {
        do {
            geminiPendingInstall = install
            pendingGeminiJSON = try HookServer.shared.previewGeminiHooks(install: install)
            showGeminiDiff = true
            statusMessage = "Review the JSON below before confirming."
        } catch let e as NSError where e.domain == "CoucouNoop" {
            statusMessage = e.localizedDescription
        } catch {
            statusMessage = "❌ \(error.localizedDescription)"
        }
    }

    private func confirmGeminiOp() {
        do {
            try HookServer.shared.writeGeminiHooks()
            showGeminiDiff = false
            pendingGeminiJSON = ""
            geminiHooksInstalled = geminiPendingInstall
            statusMessage = geminiPendingInstall
                ? "✓ Gemini CLI hooks installed in ~/.gemini/settings.json"
                : "✓ Gemini CLI hooks removed."
        } catch {
            statusMessage = "❌ \(error.localizedDescription)"
        }
    }

    private func triggerAgyPreview(install: Bool) {
        do {
            agyPendingInstall = install
            pendingAgyJSON = try HookServer.shared.previewAgyHooks(install: install)
            showAgyDiff = true
            statusMessage = "Review the JSON below before confirming."
        } catch let e as NSError where e.domain == "CoucouNoop" {
            statusMessage = e.localizedDescription
        } catch {
            statusMessage = "❌ \(error.localizedDescription)"
        }
    }

    private func confirmAgyOp() {
        do {
            try HookServer.shared.writeAgyHooks()
            showAgyDiff = false
            pendingAgyJSON = ""
            agyHooksInstalled = agyPendingInstall
            statusMessage = agyPendingInstall
                ? "✓ Antigravity hooks installed in ~/.gemini/config/hooks.json"
                : "✓ Antigravity hooks removed."
        } catch {
            statusMessage = "❌ \(error.localizedDescription)"
        }
    }
    #endif
}

// MARK: - Shortcut recorder button

struct ShortcutRecorderButton: View {
    @Binding var flags: UInt
    @Binding var code: UInt16
    @State private var isRecording = false

    var body: some View {
        Button {
            guard !isRecording else { return }
            isRecording = true
            var token: Any?
            token = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                let mods = event.modifierFlags.intersection([.command, .control, .option, .shift])
                guard !mods.isEmpty else { return event }
                DispatchQueue.main.async {
                    self.flags = mods.rawValue
                    self.code = event.keyCode
                    self.isRecording = false
                    if let t = token { NSEvent.removeMonitor(t) }
                }
                return nil
            }
        } label: {
            Text(isRecording ? "Press keys…" : shortcutLabel)
                .font(.system(size: 11, design: .monospaced))
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(isRecording ? Color.accentColor.opacity(0.12) : Color(NSColor.controlBackgroundColor))
                .cornerRadius(5)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var shortcutLabel: String {
        let f = NSEvent.ModifierFlags(rawValue: flags)
        var s = ""
        if f.contains(.control) { s += "⌃" }
        if f.contains(.option)  { s += "⌥" }
        if f.contains(.shift)   { s += "⇧" }
        if f.contains(.command) { s += "⌘" }
        s += keyChar(code)
        return s.isEmpty ? "None" : s
    }

    private func keyChar(_ c: UInt16) -> String {
        let map: [UInt16: String] = [
            0:"A", 1:"S", 2:"D", 3:"F", 4:"H", 5:"G", 6:"Z", 7:"X", 8:"C", 9:"V",
            11:"B", 12:"Q", 13:"W", 14:"E", 15:"R", 16:"Y", 17:"T", 31:"O", 32:"U",
            34:"I", 37:"L", 38:"J", 40:"K", 45:"N", 46:"M", 49:"Space", 50:"`", 27:"-"
        ]
        return map[c] ?? "·"
    }
}
