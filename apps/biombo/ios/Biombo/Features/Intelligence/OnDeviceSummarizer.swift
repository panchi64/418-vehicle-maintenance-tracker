import Foundation
import FoundationModels

/// Apple's on-device language model, for the labelled "Resumen automático"
/// only (PRODUCT.md §11). On device, never Private Cloud Compute; the input
/// is the app's own template sentences, so the model rephrases facts and
/// never adds any. Any failure is a nil, and the screen shows what it
/// always shows.
enum OnDeviceSummarizer {
    /// Read fresh each time: the model finishes downloading, or the user
    /// turns Apple Intelligence off, while the app runs. The model must also
    /// speak the language the summary is in.
    static func isAvailable(for locale: Locale) -> Bool {
        let model = SystemLanguageModel.default
        return model.isAvailable && model.supportsLocale(locale)
    }

    static func summarize(_ facts: [String], locale: Locale) async -> String? {
        guard isAvailable(for: locale), !facts.isEmpty else { return nil }
        let session = LanguageModelSession(instructions: instructions(for: locale))
        let prompt = facts.map { "- \($0)" }.joined(separator: "\n")
        guard let response = try? await session.respond(to: prompt) else { return nil }
        let summary = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        return summary.isEmpty ? nil : summary
    }

    /// Not shown to anyone: the model's brief, in the language it should answer in.
    private static func instructions(for locale: Locale) -> String {
        if locale.language.languageCode == .english {
            return "Summarize these changes at places someone watches in one short, calm sentence in English. Use only the facts given. Keep every place name, time and source. Add no advice and no new facts."
        }
        return "Resume estos cambios en lugares que alguien vigila en una sola oración corta y tranquila, en español de Puerto Rico. Usa solo los datos dados. Conserva cada lugar, hora y fuente. No des consejos ni añadas datos."
    }
}
