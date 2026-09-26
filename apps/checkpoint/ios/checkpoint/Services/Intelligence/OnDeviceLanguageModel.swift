//
//  OnDeviceLanguageModel.swift
//  checkpoint
//
//  `LanguageModelSessioning` backed by Apple's on-device model
//  (`SystemLanguageModel.default`). Never Private Cloud Compute.
//
//  Receipts use guided generation (`@Generable`) over Vision's transcript,
//  with `ServiceNameTool` to name services the way the vehicle does. On
//  iOS 27 the photo goes in too, as an `Attachment`, alongside Vision's
//  `OCRTool` so the model can re-read a region the transcript garbled. The
//  prompt is measured against the model's context before it is sent
//  (`tokenCount(for:)`, iOS 26.4+; a character estimate before that), and a
//  long transcript loses middle lines first — the shop sits at the top and
//  the totals at the bottom.
//
//  A fresh session per request: a receipt is one question, and a reused
//  session would carry the last receipt's transcript into the next.
//

import CoreGraphics
import Foundation
import FoundationModels
import Vision  // with FoundationModels, brings in the overlay that declares OCRTool

final class OnDeviceLanguageModel: LanguageModelSessioning {

    /// Tokens kept free for the answer.
    static let answerReserve = 900

    private let model: SystemLanguageModel

    init(model: SystemLanguageModel = .default) {
        self.model = model
    }

    /// The live model when it is ready; nil otherwise, so callers go straight
    /// to the rules.
    static func ifAvailable() -> OnDeviceLanguageModel? {
        IntelligenceAvailability.current.isAvailable ? OnDeviceLanguageModel() : nil
    }

    // MARK: - Receipts

    func readReceipt(_ request: ReceiptModelRequest) async throws -> ModelReceiptReading {
        let matcher = ServiceNameMatcher(candidates: request.knownServiceNames)
        var tools: [any Tool] = [ServiceNameTool(matcher: matcher)]
        var image: CGImage?
        if #available(iOS 27, *), let photo = request.image {
            // `OCRTool` lives in the Vision × FoundationModels overlay, which
            // the Simulator SDK doesn't ship ("isn't available in Simulator").
            #if canImport(_Vision_FoundationModels)
            tools.append(OCRTool(description: "Reads the text in a region of the receipt photo when the transcript is unclear."))
            #endif
            image = photo
        }
        let instructions = Self.receiptInstructions
        let text = await fittedPrompt(for: request.scan, instructions: instructions, tools: tools)
        let session = LanguageModelSession(model: model, tools: tools, instructions: instructions)

        let response: LanguageModelSession.Response<GeneratedReceipt>
        if #available(iOS 27, *), let image {
            response = try await session.respond(generating: GeneratedReceipt.self) {
                "The receipt photo, then Vision's transcript of it."
                Attachment(image, orientation: request.imageOrientation).label("receipt")
                text
            }
        } else {
            response = try await session.respond(to: text, generating: GeneratedReceipt.self)
        }
        return response.content.reading
    }

    static let receiptInstructions = """
        You read car maintenance and repair receipts and invoices, in English or Spanish, \
        from the United States and Puerto Rico. Report only what is printed; leave a field \
        empty when the receipt doesn't show it. Amounts are plain numbers without currency \
        symbols. The total is the final amount paid, tax included (Puerto Rico's tax is IVU). \
        The odometer is the vehicle's mileage when it came in, never a "next service" mileage. \
        For every service or repair performed, call findService with the receipt's wording \
        and use the name it gives.
        """

    /// The user prompt: the transcript (and tables), trimmed from the middle
    /// until prompt, instructions, tools and answer fit the model's context.
    private func fittedPrompt(for scan: ReceiptScan, instructions: String, tools: [any Tool]) async -> String {
        var lines = scan.lines
        let size = model.contextSize

        func compose() -> String {
            var text = "Receipt transcript, top to bottom:\n" + lines.joined(separator: "\n")
            if !scan.tableRows.isEmpty {
                text += "\n\nTables, one row per line, cells separated by \" | \":\n"
                text += scan.tableRows.map { $0.joined(separator: " | ") }.joined(separator: "\n")
            }
            return text
        }

        for _ in 0..<8 {
            let prompt = compose()
            let used = await tokens(prompt: prompt, instructions: instructions, tools: tools)
            if used + Self.answerReserve <= size || lines.count <= 12 { return prompt }
            // Keep the head (shop, date) and the tail (totals); drop the middle.
            let dropCount = max(1, lines.count / 5)
            let start = min(6, lines.count - dropCount)
            lines.removeSubrange(start..<(start + dropCount))
        }
        return compose()
    }

    private func tokens(prompt: String, instructions: String, tools: [any Tool]) async -> Int {
        if #available(iOS 26.4, *) {
            do {
                return try await model.tokenCount(for: prompt)
                    + model.tokenCount(for: Instructions(instructions))
                    + model.tokenCount(for: tools)
                    + model.tokenCount(for: GeneratedReceipt.generationSchema)
            } catch {
                // Fall through to the estimate.
            }
        }
        // About three characters a token, plus the schema and tool definitions.
        return (prompt.count + instructions.count) / 3 + 600
    }

    // MARK: - Documents

    func classifyDocument(text: String) async throws -> DocumentType? {
        let session = LanguageModelSession(
            model: SystemLanguageModel(useCase: .contentTagging),
            instructions: """
                You sort vehicle paperwork. Pick the one kind that fits the document's text. \
                Answer other when none fits or the text is too short to tell.
                """
        )
        let excerpt = String(text.prefix(2_000))
        let response = try await session.respond(to: excerpt, generating: GeneratedDocumentKind.self)
        return response.content.documentType
    }
}

// MARK: - Generated types

/// The model's answer for a receipt. Plain values only; `reading` converts.
@Generable(description: "The fields printed on a car service receipt")
nonisolated struct GeneratedReceipt {
    @Guide(description: "The shop, dealer or garage name printed at the top")
    var shopName: String?

    @Guide(description: "The date of service as YYYY-MM-DD")
    var date: String?

    @Guide(description: "The final amount paid, tax included")
    var total: Decimal?

    @Guide(description: "The sales tax amount (IVU in Puerto Rico); the sum when printed on several lines")
    var tax: Decimal?

    @Guide(description: "The odometer reading when the vehicle came in, digits only")
    var odometer: Int?

    @Guide(description: "Each priced line on the receipt, including tax lines")
    var lineItems: [GeneratedLineItem]

    @Guide(description: "The services performed, named as findService returned them")
    var services: [String]

    var reading: ModelReceiptReading {
        ModelReceiptReading(
            shopName: shopName?.trimmedNonEmpty,
            date: date.flatMap(Self.parseDate),
            total: total,
            tax: tax,
            odometer: odometer,
            lineItems: lineItems.map {
                ReceiptLineItem(label: $0.label, kind: $0.kind.lineItemKind, amount: $0.amount < 0 ? -$0.amount : $0.amount)
            },
            serviceNames: services.compactMap(\.trimmedNonEmpty)
        )
    }

    static func parseDate(_ text: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.date(from: text.trimmingCharacters(in: .whitespaces) + " 12:00")
    }
}

@Generable
nonisolated struct GeneratedLineItem {
    @Guide(description: "The line's description as printed")
    var label: String
    var kind: GeneratedLineItemKind
    @Guide(description: "The line's amount, positive, as printed")
    var amount: Decimal
}

@Generable
nonisolated enum GeneratedLineItemKind {
    case parts, labor, supplies, fees, tax, tip, discount, other

    var lineItemKind: VisitLineItemKind {
        switch self {
        case .parts: return .parts
        case .labor: return .labor
        case .supplies: return .supplies
        case .fees: return .fees
        case .tax: return .tax
        case .tip: return .tip
        case .discount: return .discount
        case .other: return .other
        }
    }
}

@Generable(description: "The kind of vehicle document")
nonisolated enum GeneratedDocumentKind {
    case registration, insurance, title, inspection, warranty, manual, receipt, other

    var documentType: DocumentType? {
        switch self {
        case .registration: return .registration
        case .insurance: return .insurance
        case .title: return .title
        case .inspection: return .inspection
        case .warranty: return .warranty
        case .manual: return .manual
        case .receipt: return .receipt
        case .other: return nil
        }
    }
}

private extension String {
    nonisolated var trimmedNonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
