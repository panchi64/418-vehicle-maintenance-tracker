//
//  DocumentClassifier.swift
//  checkpoint
//
//  Types a scanned or imported document (registration, insurance, receipt…)
//  from what it SAYS, not only what its file is called. Vision's text goes
//  to the on-device model when it's available; otherwise, or when the model
//  isn't sure, a keyword reading of the text; and last, the filename
//  heuristic the Documents picker always used.
//
//  A suggestion only: the add flow still shows the type and the user can
//  change it.
//

import Foundation
import os

private let classifierLogger = Logger(category: "DocumentClassifier")

final class DocumentClassifier {

    /// Below this much text there's nothing for the model to judge; the
    /// keywords and filename decide.
    static let minimumTextForModel = 40

    private let session: LanguageModelSessioning?

    init(session: LanguageModelSessioning? = OnDeviceLanguageModel.ifAvailable()) {
        self.session = session
    }

    func classify(text: String?, fileName: String) async -> DocumentType {
        let text = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if text.count >= Self.minimumTextForModel, let session {
            do {
                if let type = try await session.classifyDocument(text: text) { return type }
            } catch {
                classifierLogger.info("On-device model couldn't type the document, using keywords: \(error.localizedDescription)")
            }
        }
        return Self.keywordType(for: text, fileName: fileName)
    }

    /// The rule-based answer: keywords in the text, then in the filename.
    nonisolated static func keywordType(for text: String, fileName: String) -> DocumentType {
        if let type = type(inText: text) { return type }
        return DocumentType.suggestedType(forFileName: fileName)
    }

    /// The type whose keywords the text mentions most, EN and ES (Puerto
    /// Rico's marbete, DTOP and ACAA included). Nil when nothing matches.
    nonisolated static func type(inText text: String) -> DocumentType? {
        let normalized = ServiceNameMatcher.normalize(text)
        guard !normalized.isEmpty else { return nil }
        let keywords: [(DocumentType, [String])] = [
            (.insurance, ["insurance", "policy", "policy number", "insured", "premium", "coverage", "declarations",
                          "liability", "seguro", "poliza", "asegurado", "prima", "cubierta", "acaa"]),
            (.registration, ["registration", "vehicle registration", "registered owner", "license plate", "tag",
                             "marbete", "registro", "licencia del vehiculo", "dtop", "cesco", "tablilla", "dmv"]),
            (.title, ["certificate of title", "title number", "lienholder", "lien", "titulo", "certificado de titulo",
                      "gravamen", "odometer disclosure"]),
            (.inspection, ["inspection", "emissions", "smog", "safety inspection", "inspeccion", "emisiones",
                           "certificado de inspeccion"]),
            (.warranty, ["warranty", "extended warranty", "service contract", "garantia", "contrato de servicio",
                         "coverage term"]),
            (.manual, ["owner s manual", "owners manual", "manual del propietario", "table of contents", "chapter",
                       "maintenance schedule", "capitulo"]),
            (.receipt, ["receipt", "invoice", "subtotal", "total", "amount due", "labor", "parts", "factura", "recibo",
                        "mano de obra", "ivu", "tax", "paid", "pagado"]),
        ]
        var best: (type: DocumentType, hits: Int)?
        for (type, words) in keywords {
            let hits = words.filter { ServiceNameMatcher.contains(normalized, phrase: $0) }.count
            if hits > 0, hits > (best?.hits ?? 0) {
                best = (type, hits)
            }
        }
        return best?.type
    }
}
