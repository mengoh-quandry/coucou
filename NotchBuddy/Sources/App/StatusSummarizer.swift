import Foundation
import FoundationModels

/// Turns a raw coding-agent tool action into a short, plain-English status line
/// using Apple's on-device Foundation model. Fully local — no network, no keys.
///
/// If Apple Intelligence is unavailable (not enabled, still downloading, or the
/// device doesn't support it) or the model errors, it returns nil and the caller
/// keeps the raw step, so the feature degrades silently.
enum StatusSummarizer {

    static var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    /// A 3–6 word, present-tense status describing what the agent is doing, or nil.
    static func summarize(tool: String, detail: String) async -> String? {
        guard case .available = SystemLanguageModel.default.availability else { return nil }

        let prompt = """
        You write one short status line for a menu-bar status display, describing \
        what a coding agent is doing right now. Reply with 3 to 6 words, present \
        tense, no quotes and no trailing period.

        Tool: \(tool)
        Detail: \(detail)
        Status:
        """

        do {
            let session = LanguageModelSession()
            let response = try await session.respond(to: prompt)
            var text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            // Strip wrapping quotes / stray punctuation the model sometimes adds.
            text = text.trimmingCharacters(in: CharacterSet(charactersIn: "\"'`.…"))
                       .trimmingCharacters(in: .whitespaces)
            guard !text.isEmpty else { return nil }
            return String(text.prefix(52))
        } catch {
            return nil
        }
    }
}
