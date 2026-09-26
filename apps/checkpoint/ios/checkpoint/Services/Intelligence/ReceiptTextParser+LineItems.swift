//
//  ReceiptTextParser+LineItems.swift
//  checkpoint
//
//  The rule-based reader's line items: priced lines that aren't totals or
//  payments, each labelled and given a kind by keyword (EN and ES). Also the
//  total and payment line tests the rest of the parser skips lines with.
//

import Foundation

nonisolated extension ReceiptTextParser {

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
}
