//
//  ReceiptTextParser+Values.swift
//  checkpoint
//
//  The rule-based reader's value parsers: money as printed (US and European
//  separators, two decimals, never a percentage) and dates (ISO, numeric
//  month-first unless the first number can't be a month, and EN/ES month
//  names), plus which printed date is the service date.
//

import Foundation

nonisolated extension ReceiptTextParser {

    // MARK: - Amounts

    /// Money amounts on a line, as printed (positive), left to right.
    static func amounts(in line: String) -> [Decimal] {
        moneyMatches(in: line).map(\.amount)
    }

    static func amountIsNegative(in line: String) -> Bool {
        moneyMatches(in: line).last?.isNegative ?? false
    }

    private static func moneyMatches(in line: String) -> [(amount: Decimal, isNegative: Bool)] {
        // US "1,234.56" or European "1.234,56"; two decimals, never a
        // percentage; optional $, minus sign or accounting parentheses.
        let pattern = #"(?<![\w.,])(\()?(-)?\$?\s?((?:\d{1,3}(?:,\d{3})+|\d+)\.\d{2}|(?:\d{1,3}(?:\.\d{3})+|\d+),\d{2})(\))?(-)?(?![\d%]|\s?%|[.,]\d)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        return regex.matches(in: line, range: NSRange(line.startIndex..., in: line)).compactMap { match in
            guard let r = Range(match.range(at: 3), in: line), let amount = decimal(from: String(line[r])) else { return nil }
            let negative = [1, 2, 4, 5].contains { match.range(at: $0).location != NSNotFound }
            return (amount, negative)
        }
    }

    /// "1,234.56", "1.234,56" and "45,00" as a Decimal.
    static func decimal(from printed: String) -> Decimal? {
        var text = printed
        if let comma = text.lastIndex(of: ","), text.distance(from: comma, to: text.endIndex) == 3 {
            text = text.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
        } else {
            text = text.replacingOccurrences(of: ",", with: "")
        }
        return Decimal(string: text, locale: Locale(identifier: "en_US_POSIX"))
    }

    // MARK: - Dates

    /// The service date and whether a date label named it.
    static func date(in scan: ReceiptScan, context: ReceiptContext) -> (Date, Bool)? {
        let lines = scan.lines
        func isPlausible(_ date: Date) -> Bool { ReceiptDraftValidator.isPlausible(date, context: context) }
        func isDateLabel(_ index: Int?) -> Bool {
            guard let index, index < lines.count else { return false }
            let text = ServiceNameMatcher.normalize(lines[index])
            return ["date", "fecha", "dated"].contains { ServiceNameMatcher.contains(text, phrase: $0) }
        }
        func isUsable(_ index: Int?) -> Bool {
            guard let index, index < lines.count else { return true }
            return !isForwardLooking(ServiceNameMatcher.normalize(lines[index]))
        }

        var candidates: [(date: Date, line: Int?)] = scan.detected.compactMap {
            if case .date(let date, let line) = $0 { return (date, line) }
            return nil
        }
        for (index, line) in lines.enumerated() {
            if let date = date(in: line, calendar: context.calendar) { candidates.append((date, index)) }
        }
        let usable = candidates.filter { isPlausible($0.date) && isUsable($0.line) }
        if let labelled = usable.first(where: { isDateLabel($0.line) }) {
            return (labelled.date, true)
        }
        return usable.first.map { ($0.date, false) }
    }

    /// The first date printed on `line`, at noon (a receipt date has no time
    /// that matters, and noon survives a time-zone shift).
    static func date(in line: String, calendar: Calendar) -> Date? {
        let text = ServiceNameMatcher.normalize(line)
        var components: (year: Int, month: Int, day: Int)?

        func firstMatch(_ pattern: String, in string: String) -> [String]? {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
                  let match = regex.firstMatch(in: string, range: NSRange(string.startIndex..., in: string))
            else { return nil }
            return (1..<match.numberOfRanges).map { i in
                Range(match.range(at: i), in: string).map { String(string[$0]) } ?? ""
            }
        }

        if let g = firstMatch(#"(?<!\d)(\d{4})-(\d{1,2})-(\d{1,2})(?!\d)"#, in: line),
           let y = Int(g[0]), let m = Int(g[1]), let d = Int(g[2]) {
            components = (y, m, d)
        } else if let g = firstMatch(#"(?<![\d.])(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4}|\d{2})(?![\d])"#, in: line),
                  let a = Int(g[0]), let b = Int(g[1]), var y = Int(g[2]) {
            if y < 100 { y += 2000 }
            components = a > 12 ? (y, b, a) : (y, a, b)
        } else if let g = firstMatch(#"\b([a-z]{3,10})\s+(\d{1,2})\s+(\d{4})\b"#, in: text),
                  let m = month(named: g[0]), let d = Int(g[1]), let y = Int(g[2]) {
            components = (y, m, d)
        } else if let g = firstMatch(#"\b(\d{1,2})\s+(?:de\s+)?([a-z]{3,10})\s+(?:de\s+|del\s+)?(\d{4})\b"#, in: text),
                  let d = Int(g[0]), let m = month(named: g[1]), let y = Int(g[2]) {
            components = (y, m, d)
        }

        guard let c = components, (1...12).contains(c.month), (1...31).contains(c.day) else { return nil }
        var parts = DateComponents(year: c.year, month: c.month, day: c.day, hour: 12)
        parts.calendar = calendar
        guard let date = calendar.date(from: parts),
              calendar.component(.day, from: date) == c.day
        else { return nil }
        return date
    }

    /// January is 1. English and Spanish, full or abbreviated.
    static func month(named name: String) -> Int? {
        let months: [[String]] = [
            ["jan", "january", "ene", "enero"],
            ["feb", "february", "febrero"],
            ["mar", "march", "marzo"],
            ["apr", "april", "abr", "abril"],
            ["may", "mayo"],
            ["jun", "june", "junio"],
            ["jul", "july", "julio"],
            ["aug", "august", "ago", "agosto"],
            ["sep", "sept", "september", "septiembre", "setiembre"],
            ["oct", "october", "octubre"],
            ["nov", "november", "noviembre"],
            ["dec", "december", "dic", "diciembre"],
        ]
        let key = name.lowercased()
        return months.firstIndex { $0.contains(key) }.map { $0 + 1 }
    }
}
