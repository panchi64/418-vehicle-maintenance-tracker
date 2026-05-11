import Foundation

/// Pure text-manipulation helpers behind the rich notes editor toolbar.
/// Storage stays plain markdown — the toolbar inserts the same syntax
/// users would type by hand.
enum MarkdownNotesEditing {

    struct EditResult: Equatable {
        let text: String
        let selection: NSRange
    }

    static func applyBold(to text: String, selection: NSRange) -> EditResult {
        let nsText = text as NSString
        guard selection.location <= nsText.length else { return EditResult(text: text, selection: selection) }
        let safeRange = NSRange(location: selection.location, length: min(selection.length, nsText.length - selection.location))

        if safeRange.length == 0 {
            let newText = nsText.replacingCharacters(in: safeRange, with: "****")
            return EditResult(text: newText, selection: NSRange(location: safeRange.location + 2, length: 0))
        }

        let substring = nsText.substring(with: safeRange)
        let newText = nsText.replacingCharacters(in: safeRange, with: "**\(substring)**")
        return EditResult(text: newText, selection: NSRange(location: safeRange.location + 2, length: substring.count))
    }

    static func applyBulletList(to text: String, selection: NSRange) -> EditResult {
        applyLinePrefix(to: text, selection: selection, prefix: "- ", isItem: isBulletLine)
    }

    static func applyNumberedList(to text: String, selection: NSRange) -> EditResult {
        applyLinePrefix(to: text, selection: selection, prefix: "1. ", isItem: isNumberedLine)
    }

    private static func applyLinePrefix(
        to text: String,
        selection: NSRange,
        prefix: String,
        isItem: (String) -> Bool
    ) -> EditResult {
        let nsText = text as NSString
        guard selection.location <= nsText.length else { return EditResult(text: text, selection: selection) }
        let safeRange = NSRange(location: selection.location, length: min(selection.length, nsText.length - selection.location))

        let lineRange = nsText.lineRange(for: safeRange)
        let lines = nsText.substring(with: lineRange).components(separatedBy: "\n")

        var workingLines = lines
        let endedWithNewline = workingLines.last?.isEmpty == true && lines.count > 1
        if endedWithNewline { workingLines.removeLast() }

        let prefixed = workingLines.map { line -> String in
            if line.isEmpty || isItem(line) { return line }
            return prefix + line
        }

        let joined = prefixed.joined(separator: "\n") + (endedWithNewline ? "\n" : "")
        let newText = nsText.replacingCharacters(in: lineRange, with: joined)
        return EditResult(text: newText, selection: NSRange(location: lineRange.location, length: joined.count))
    }

    private static func isBulletLine(_ line: String) -> Bool {
        line.hasPrefix("- ") || line.hasPrefix("* ")
    }

    private static func isNumberedLine(_ line: String) -> Bool {
        var seenDigit = false
        for char in line {
            if char.isNumber { seenDigit = true; continue }
            if seenDigit, char == "." { return true }
            return false
        }
        return false
    }
}

// MARK: - Markdown rendering

/// Cache for parsed markdown so display sites don't re-parse on every body
/// recomputation. Bounded to avoid unbounded growth on large note corpora.
private final class MarkdownAttributedCache: @unchecked Sendable {
    static let shared = MarkdownAttributedCache()
    private let cache = NSCache<NSString, NSAttributedString>()
    init() { cache.countLimit = 256 }

    func attributed(for source: String) -> AttributedString {
        let key = source as NSString
        if let cached = cache.object(forKey: key) {
            return AttributedString(cached)
        }
        var options = AttributedString.MarkdownParsingOptions()
        options.interpretedSyntax = .inlineOnlyPreservingWhitespace
        let parsed = (try? AttributedString(markdown: source, options: options)) ?? AttributedString(source)
        cache.setObject(NSAttributedString(parsed), forKey: key)
        return parsed
    }
}

extension String {
    /// Best-effort inline markdown rendering with parse-result memoization.
    var brutalistMarkdownAttributed: AttributedString {
        MarkdownAttributedCache.shared.attributed(for: self)
    }
}
