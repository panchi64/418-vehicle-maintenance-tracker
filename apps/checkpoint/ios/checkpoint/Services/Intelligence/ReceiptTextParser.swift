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
//  This file holds the draft and the shop, total, tax and odometer rules.
//  Line items are in `+LineItems`; money and date parsing in `+Values`.
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
}
