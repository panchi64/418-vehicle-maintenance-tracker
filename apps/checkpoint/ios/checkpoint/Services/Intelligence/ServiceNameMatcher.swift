//
//  ServiceNameMatcher.swift
//  checkpoint
//
//  Turns what a receipt calls a job ("LOF", "Cambio de aceite y filtro",
//  "ROTACION DE GOMAS") into the name Checkpoint already uses for it — the
//  vehicle's own service when it has one, else the preset. Matching to an
//  existing name is what lets a receipt COMPLETE a tracked service instead of
//  creating a duplicate beside it.
//
//  Used by both readers: the rule-based parser directly, and the on-device
//  model through `ServiceNameTool`.
//

import Foundation

nonisolated struct ServiceNameMatcher: Sendable {
    /// The vehicle's service names first, then the preset catalog.
    let candidates: [String]
    /// The candidates longest first, each with its normalized form. Built
    /// once: every line of a receipt is matched against all of them.
    private let byLength: [(name: String, normalized: String)]

    init(candidates: [String]) {
        self.candidates = candidates
        byLength = candidates
            .sorted { $0.count > $1.count }
            .map { (name: $0, normalized: Self.normalize($0)) }
    }

    /// The Checkpoint name for `text`, or nil when nothing fits.
    func match(_ text: String) -> String? {
        let normalized = Self.normalize(text)
        guard !normalized.isEmpty else { return nil }

        // 1. A known name printed as is. Longest first, so "Cabin Air Filter"
        //    wins over "Air Filter".
        if let direct = byLength.first(where: { Self.contains(normalized, phrase: $0.normalized) }) {
            return direct.name
        }

        // 2. A shop's wording for a catalog service, EN or ES.
        guard let canonical = Self.canonicalService(in: normalized) else { return nil }
        return bestCandidate(for: canonical) ?? canonical
    }

    /// Every distinct service named across `lines`, in reading order.
    func matches(in lines: [String]) -> [String] {
        var seen = Set<String>()
        return lines.compactMap { line in
            guard let name = match(line), seen.insert(name.lowercased()).inserted else { return nil }
            return name
        }
    }

    /// The vehicle's own name for a catalog service ("Oil & Filter Change" for
    /// "Oil Change"), by word overlap. Candidates keep their order, so the
    /// vehicle's services beat presets on a tie.
    private func bestCandidate(for canonical: String) -> String? {
        let wanted = Self.words(canonical)
        var best: (name: String, score: Double)?
        for candidate in candidates {
            let have = Self.words(candidate)
            guard !have.isEmpty else { continue }
            let score = Double(wanted.intersection(have).count) / Double(wanted.count)
            if score >= 1, best.map({ score > $0.score }) ?? true {
                best = (candidate, score)
            }
        }
        return best?.name
    }

    // MARK: - Vocabulary

    /// Shop wording → the preset it means. Longest phrases are tried first.
    /// Spanish covers Puerto Rico's usage ("gomas" for tires, "plumas" for
    /// wipers) as well as the general forms.
    static let synonyms: [(phrase: String, service: String)] = [
        ("cabin air filter", "Cabin Air Filter"),
        ("cabin filter", "Cabin Air Filter"),
        ("filtro de cabina", "Cabin Air Filter"),
        ("filtro de aire de cabina", "Cabin Air Filter"),
        ("engine air filter", "Air Filter"),
        ("air filter", "Air Filter"),
        ("filtro de aire", "Air Filter"),
        ("oil change", "Oil Change"),
        ("oil and filter", "Oil Change"),
        ("oil filter", "Oil Change"),
        ("lube oil filter", "Oil Change"),
        ("lof", "Oil Change"),
        ("synthetic oil", "Oil Change"),
        ("motor oil", "Oil Change"),
        ("cambio de aceite", "Oil Change"),
        ("cambio aceite", "Oil Change"),
        ("aceite y filtro", "Oil Change"),
        ("filtro de aceite", "Oil Change"),
        ("aceite sintetico", "Oil Change"),
        ("aceite de motor", "Oil Change"),
        ("tire rotation", "Tire Rotation"),
        ("rotate tires", "Tire Rotation"),
        ("rotacion de gomas", "Tire Rotation"),
        ("rotacion de neumaticos", "Tire Rotation"),
        ("rotacion de llantas", "Tire Rotation"),
        ("brake inspection", "Brake Inspection"),
        ("brake check", "Brake Inspection"),
        ("inspeccion de frenos", "Brake Inspection"),
        ("transmission fluid", "Transmission Fluid"),
        ("trans fluid", "Transmission Fluid"),
        ("atf", "Transmission Fluid"),
        ("aceite de transmision", "Transmission Fluid"),
        ("fluido de transmision", "Transmission Fluid"),
        ("coolant", "Coolant Flush"),
        ("antifreeze", "Coolant Flush"),
        ("refrigerante", "Coolant Flush"),
        ("anticongelante", "Coolant Flush"),
        ("spark plug", "Spark Plugs"),
        ("bujia", "Spark Plugs"),
        ("battery", "Battery Check"),
        ("bateria", "Battery Check"),
        ("wiper", "Wiper Blades"),
        ("plumas", "Wiper Blades"),
        ("limpiaparabrisas", "Wiper Blades"),
        ("escobillas", "Wiper Blades"),
    ].sorted { $0.phrase.count > $1.phrase.count }

    static func canonicalService(in normalized: String) -> String? {
        synonyms.first { contains(normalized, phrase: $0.phrase) }?.service
    }

    // MARK: - Text

    /// Lowercased, accents folded, punctuation to spaces, "&" to "and",
    /// single-spaced.
    static func normalize(_ text: String) -> String {
        let folded = text
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .replacingOccurrences(of: "&", with: " and ")
        let spaced = folded.unicodeScalars.map { CharacterSet.alphanumerics.contains($0) ? Character($0) : " " }
        return String(spaced).split(separator: " ").joined(separator: " ")
    }

    /// Whole-word containment: "lof" must not match inside "gloves".
    static func contains(_ normalized: String, phrase: String) -> Bool {
        guard !phrase.isEmpty else { return false }
        return " \(normalized) ".contains(" \(phrase) ")
    }

    static func words(_ text: String) -> Set<String> {
        let stop: Set<String> = ["and", "de", "y", "the", "service", "servicio"]
        return Set(normalize(text).split(separator: " ").map(String.init).filter { !stop.contains($0) })
    }
}
