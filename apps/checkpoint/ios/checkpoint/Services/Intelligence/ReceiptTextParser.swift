//
//  ReceiptTextParser.swift
//  checkpoint
//
//  The rule-based receipt reader. It is the whole reader on devices without
//  Apple Intelligence (and iOS 26 without it), and the cross-check the
//  on-device model's answer is scored against everywhere else.
//
//  Rules, in the order a person reads a receipt:
//    - shop     the first line near the top that reads like a name
//    - date     a date on a "Date/Fecha" line, else the first plausible one;
//               "next service due" lines never count
//    - total    the amount on the strongest total line ("AMOUNT DUE" >
//               "TOTAL"; never SUBTOTAL, TOTAL ITEMS or TOTAL SAVINGS), else
//               the largest plausible amount, at low confidence
//    - tax      TAX / IVU / IMPUESTO lines, summed (Puerto Rico prints the
//               state and municipal IVU on separate lines)
//    - odometer a number on an ODOMETER / MILEAGE IN / MILLAJE line
//    - items    priced lines that aren't totals or payments, kind by keyword
//    - services item labels matched to Checkpoint's names (`ServiceNameMatcher`)
//
//  Amounts need two decimals, so odometers ("45,210"), phone numbers and
//  percentages ("IVU 11.5%") are never read as money. US and European
//  separators are both read. Numeric dates are month-first (US and Puerto
//  Rico) unless the first number can't be a month.
//

import Foundation

nonisolated enum ReceiptTextParser {

    /// The biggest amount the fallback will take as a total. Above it, a
    /// number is a part number or a phone number that happens to have two
    /// decimals.
    static let largestPlausibleTotal: Decimal = 25_000

    static func parse(_ scan: ReceiptScan, context: ReceiptContext) -> ServiceReceiptDraft {
        let lines = scan.lines
        var draft = ServiceReceiptDraft(source: .rules)

        draft.shopName = shopName(in: lines)
        draft.confidence.shop = .medium

        if let (date, labelled) = date(in: scan, context: context) {
            draft.date = date
            draft.confidence.date = labelled ? .high : .medium
        }

        if let (total, labelled) = total(in: lines, detected: scan.detected) {
            draft.total = total
            draft.confidence.total = labelled ? .high : .low
        }

        draft.tax = tax(in: lines)

        if let odometer = odometer(in: lines) {
            draft.odometer = odometer
            draft.confidence.odometer = .medium
        }

        // A detected table keeps each description beside its price, which
        // loose lines often split apart.
        let rows = scan.tableRows.map { $0.joined(separator: "  ") }
        let fromTable = lineItems(in: rows)
        draft.lineItems = fromTable.isEmpty ? lineItems(in: lines) : fromTable

        let matcher = ServiceNameMatcher(candidates: context.knownServiceNames)
        let itemLabels = draft.lineItems.filter { $0.kind != .tax }.map(\.label)
        var services = matcher.matches(in: itemLabels)
        if services.isEmpty {
            services = matcher.matches(in: lines.filter { !isTotalOrPayment($0) })
        }
        draft.serviceNames = services
        draft.confidence.services = .medium
        return draft
    }

    // MARK: - Shop

    static func shopName(in lines: [String]) -> String? {
        let skipWords = ["receipt", "invoice", "factura", "recibo", "welcome", "bienvenido", "bienvenidos",
                         "customer copy", "copia", "tel", "phone", "telefono", "date", "fecha", "order", "orden",
                         "ticket", "cashier", "cajero", "work order", "estimate", "estimado", "cotizacion",
                         "thank you", "thanks", "gracias"]
        let skipMarks = ["www", "http", ".com", "@"]
        for line in lines.prefix(5) {
            let normalized = ServiceNameMatcher.normalize(line)
            let letters = line.unicodeScalars.filter { CharacterSet.letters.contains($0) }.count
            guard letters >= 3,
                  Double(letters) / Double(max(line.count, 1)) >= 0.5,
                  line.first?.isNumber != true,
                  amounts(in: line).isEmpty,
                  !skipWords.contains(where: { ServiceNameMatcher.contains(normalized, phrase: $0) }),
                  !skipMarks.contains(where: { line.lowercased().contains($0) })
            else { continue }
            return line.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        }
        return nil
    }

    // MARK: - Total and tax

    /// The total and whether a total line named it (false: the fallback's
    /// largest-amount guess).
    static func total(in lines: [String], detected: [ReceiptScan.DetectedValue]) -> (Decimal, Bool)? {
        var best: (amount: Decimal, score: Int)?
        for (index, line) in lines.enumerated() {
            let score = totalScore(line)
            guard score > 0 else { continue }
            let amount = amounts(in: line).last ?? nextLineAmount(after: index, in: lines)
            guard let amount, amount > 0 else { continue }
            // Later lines win ties: the total follows the subtotal and tax.
            if best == nil || score >= best!.score {
                best = (amount, score)
            }
        }
        if let best { return (best.amount, true) }

        let printed = lines.filter { !isPaymentLine($0) }.flatMap { amounts(in: $0) }
        let found = detected.compactMap { value -> Decimal? in
            if case .money(let amount, _) = value { return amount }
            return nil
        }
        let largest = (printed + found).filter { $0 > 0 && $0 <= largestPlausibleTotal }.max()
        return largest.map { ($0, false) }
    }

    /// 3 for "amount due"-style lines, 2 for a bare TOTAL, 0 for lines that
    /// only look like totals.
    static func totalScore(_ line: String) -> Int {
        let text = ServiceNameMatcher.normalize(line)
        let words = Set(text.split(separator: " ").map(String.init))
        let notATotal = ["subtotal", "sub", "items", "item", "articulos", "qty", "cantidad", "savings",
                         "ahorro", "ahorros", "points", "puntos", "tax", "ivu", "impuesto", "iva", "discount", "descuento"]
        if notATotal.contains(where: words.contains) { return 0 }
        let strong = ["grand total", "total due", "amount due", "balance due", "total a pagar", "invoice total",
                      "total factura", "gran total", "importe total", "monto total", "total general", "total amount"]
        if strong.contains(where: { ServiceNameMatcher.contains(text, phrase: $0) }) { return 3 }
        return words.contains("total") ? 2 : 0
    }

    /// Tax lines summed, or the one "total tax" line when there is one.
    static func tax(in lines: [String]) -> Decimal? {
        var taxes: [Decimal] = []
        for line in lines where isTaxLine(line) {
            guard let amount = amounts(in: line).last else { continue }
            let words = Set(ServiceNameMatcher.normalize(line).split(separator: " ").map(String.init))
            if words.contains("total") { return amount }
            taxes.append(amount)
        }
        return taxes.isEmpty ? nil : taxes.reduce(0, +)
    }

    static func isTaxLine(_ line: String) -> Bool {
        let text = ServiceNameMatcher.normalize(line)
        let words = Set(text.split(separator: " ").map(String.init))
        if words.contains("subtotal") || words.contains("exempt") || words.contains("exento") { return false }
        return ["tax", "ivu", "impuesto", "iva"].contains(where: words.contains)
            || ServiceNameMatcher.contains(text, phrase: "i v u")
    }

    private static func nextLineAmount(after index: Int, in lines: [String]) -> Decimal? {
        let next = index + 1
        guard next < lines.count else { return nil }
        let line = lines[next]
        let letters = line.unicodeScalars.filter { CharacterSet.letters.contains($0) }.count
        return letters <= 3 ? amounts(in: line).last : nil
    }

    // MARK: - Odometer

    /// Stored miles, from an odometer line. A reading printed in kilometres
    /// is converted.
    static func odometer(in lines: [String]) -> Int? {
        let keywords = ["odometer", "odo", "mileage", "milage", "miles in", "mi in", "millaje", "odometro",
                        "kilometraje", "millas", "mileage in", "in mileage", "km in"]
        for (index, line) in lines.enumerated() {
            let text = ServiceNameMatcher.normalize(line)
            guard keywords.contains(where: { ServiceNameMatcher.contains(text, phrase: $0) }),
                  !isForwardLooking(text)
            else { continue }
            let candidates = [line] + (index + 1 < lines.count ? [lines[index + 1]] : [])
            for candidate in candidates {
                guard let reading = odometerNumber(in: candidate) else { continue }
                let isKilometres = ServiceNameMatcher.contains(ServiceNameMatcher.normalize(candidate), phrase: "km")
                    || ServiceNameMatcher.contains(text, phrase: "kilometraje")
                return isKilometres ? Int((Double(reading) * 0.621371).rounded()) : reading
            }
        }
        return nil
    }

    /// A whole number of three or more digits that isn't money.
    static func odometerNumber(in line: String) -> Int? {
        let pattern = #"(?<![\d.,$])(\d{1,3}(?:,\d{3})+|\d{3,7})(?![\d]|[.,]\d)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(line.startIndex..., in: line)
        for match in regex.matches(in: line, range: range) {
            guard let r = Range(match.range(at: 1), in: line) else { continue }
            if let value = Int(line[r].replacingOccurrences(of: ",", with: "")) { return value }
        }
        return nil
    }

    /// "Next service at 50,000", "próximo cambio" — a target, not a reading.
    static func isForwardLooking(_ normalized: String) -> Bool {
        ["next", "proximo", "proxima", "due", "vence", "recommended", "recomendado"]
            .contains { ServiceNameMatcher.contains(normalized, phrase: $0) }
    }

    // MARK: - Line items

    static func lineItems(in lines: [String]) -> [ReceiptLineItem] {
        var items: [ReceiptLineItem] = []
        for (index, line) in lines.enumerated() {
            guard let amount = amounts(in: line).last, !isTotalOrPayment(line) else { continue }
            var text = label(of: line)
            // A price printed under its description: borrow the line above.
            if text.count < 2, index > 0 {
                let above = lines[index - 1]
                if amounts(in: above).isEmpty, !isTotalOrPayment(above) { text = label(of: above) }
            }
            guard text.count >= 2 else { continue }
            var itemKind = kind(of: text)
            if amountIsNegative(in: line), itemKind != .discount { itemKind = .discount }
            items.append(ReceiptLineItem(label: text, kind: itemKind, amount: amount))
        }
        return items
    }

    static func kind(of label: String) -> VisitLineItemKind {
        let text = ServiceNameMatcher.normalize(label)
        func has(_ phrases: [String]) -> Bool { phrases.contains { ServiceNameMatcher.contains(text, phrase: $0) } }
        if isTaxLine(label) { return .tax }
        if has(["discount", "descuento", "coupon", "cupon", "savings", "ahorro", "rebate", "promo"]) { return .discount }
        if has(["tip", "propina", "gratuity"]) { return .tip }
        if has(["shop supplies", "shop supply", "supplies", "suministros", "materiales", "materials"]) { return .supplies }
        if has(["fee", "fees", "cargo", "cargos", "disposal", "environmental", "recargo", "cuota", "hazmat", "haz mat"]) { return .fees }
        if has(["labor", "labour", "mano de obra", "service charge", "diagnostic", "diagnostico", "inspection",
                "inspeccion", "rotation", "rotacion", "alignment", "alineacion", "balance", "balanceo", "install",
                "instalacion", "lof", "oil change", "cambio de aceite"]) { return .labor }
        if has(["filter", "filtro", "oil", "aceite", "part", "parts", "pieza", "piezas", "pad", "pads", "pastilla",
                "pastillas", "rotor", "rotors", "battery", "bateria", "tire", "tires", "goma", "gomas", "llanta",
                "llantas", "wiper", "plumas", "bulb", "bombilla", "belt", "correa", "plug", "bujia", "fluid",
                "fluido", "coolant", "refrigerante", "qt", "quart", "cuarto", "gal"]) { return .parts }
        return .other
    }

    /// The line's words, without its amounts, quantities and unit prices.
    static func label(of line: String) -> String {
        let pattern = #"(\(?-?\$?\s?(?:\d{1,3}(?:[,.]\d{3})+|\d+)[.,]\d{2}\)?-?)|(\b\d+\s?[@xX]\s?)|(\s{2,})"#
        let stripped = (try? NSRegularExpression(pattern: pattern))
            .map { $0.stringByReplacingMatches(in: line, range: NSRange(line.startIndex..., in: line), withTemplate: " ") }
            ?? line
        return stripped
            .split(separator: " ")
            .joined(separator: " ")
            .trimmingCharacters(in: CharacterSet(charactersIn: " :-*#.$@"))
    }

    static func isTotalOrPayment(_ line: String) -> Bool {
        let text = ServiceNameMatcher.normalize(line)
        let words = Set(text.split(separator: " ").map(String.init))
        if words.contains("subtotal") || ServiceNameMatcher.contains(text, phrase: "sub total") { return true }
        if totalScore(line) > 0 { return true }
        return isPaymentLine(line)
    }

    static func isPaymentLine(_ line: String) -> Bool {
        let text = ServiceNameMatcher.normalize(line)
        // Not "change" alone: "Oil change" is a service.
        let payment = ["visa", "mastercard", "master card", "amex", "american express", "discover", "debit", "debito",
                       "credit", "credito", "cash", "efectivo", "change due", "cambio", "tender", "tendered", "paid",
                       "pagado", "pago", "ath", "ath movil", "card", "tarjeta", "approved", "aprobado", "auth",
                       "balance", "saldo"]
        // "Cambio de aceite" is an oil change, not change given back.
        if ServiceNameMatcher.contains(text, phrase: "cambio de") { return false }
        if ServiceNameMatcher.contains(text, phrase: "wheel balance") || ServiceNameMatcher.contains(text, phrase: "tire balance") { return false }
        return payment.contains { ServiceNameMatcher.contains(text, phrase: $0) }
    }

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
