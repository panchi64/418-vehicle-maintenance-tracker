//
//  LogReceiptIntent.swift
//  checkpoint
//
//  "Log this receipt in Checkpoint." A photo or PDF of a shop receipt — from
//  Siri with the receipt on screen, the Share Sheet (through Shortcuts), or a
//  shortcut — read by `ReceiptExtractionService` (the on-device model where
//  available, else the rules), shown back as the same confirmation snippet
//  Mark Done and Log Service use, and written by the same path
//  (`ServiceLogging` → `LoggedServiceWriter` / `ServiceVisitWriter`). The
//  receipt is attached to the entry; its total is the cost, its lines the
//  visit's breakdown.
//
//  Free, like all receipt reading.
//

import AppIntents
import SwiftData
import UIKit
import UniformTypeIdentifiers

struct LogReceiptIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Receipt"
    static let description = IntentDescription("Read a shop receipt and log the services on it, with its date, mileage, total and shop. Checkpoint shows what it read and asks before saving.")

    @Dependency var container: ModelContainer

    @Parameter(
        title: "Receipt",
        description: "A photo or PDF of the receipt",
        supportedContentTypes: [.image, .pdf],
        requestValueDialog: "Which receipt?"
    )
    var receipt: IntentFile

    @Parameter(title: "Vehicle", description: "Leave empty for the vehicle Checkpoint is showing.")
    var vehicle: VehicleEntity?

    /// When the receipt doesn't name the work, or names it differently.
    @Parameter(title: "Services", description: "What was done, when the receipt doesn't say")
    var services: [String]?

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$receipt) on \(\.$vehicle)") {
            \.$services
        }
    }

    init() {}

    init(receipt: IntentFile, vehicle: VehicleEntity? = nil) {
        self.receipt = receipt
        self.vehicle = vehicle
    }

    /// The reader `perform()` uses. Tests substitute one over a transcript.
    @MainActor static var makeExtractor: () -> ReceiptExtractionService = { ReceiptExtractionService() }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[ServiceLogEntity]> & ProvidesDialog {
        let context = container.mainContext
        let vehicle = try IntentStore.vehicle(for: self.vehicle, in: context)
        let reading = try await Self.read(receipt.contents, for: vehicle)

        let spoken = (services ?? []).isEmpty ? reading.draft.serviceNames : (services ?? [])
        let names = ServiceLogging.names(in: spoken, knownNames: ServiceLogging.knownNames(on: vehicle))
        guard !names.isEmpty else {
            throw $services.needsValueError("Which services does this receipt cover?")
        }

        let occasion = reading.occasion
        try await requestConfirmation(
            actionName: .log,
            dialog: IntentDialog(stringLiteral: L10n.siriReceiptConfirm(
                services: SpokenValue.list(names),
                vehicle: vehicle.displayName
            )),
            snippetIntent: ServiceRecordSnippetIntent(
                serviceNames: names,
                vehicleName: vehicle.displayName,
                occasion: occasion,
                vehicle: vehicle
            )
        )

        let logs = try Self.record(names, on: vehicle, occasion: occasion, in: context)
        return .result(
            value: logs.map { ServiceLogEntity(model: $0) },
            dialog: IntentDialog(stringLiteral: L10n.siriReceiptSaved(
                services: SpokenValue.list(logs.compactMap { $0.service?.name }),
                vehicle: vehicle.displayName
            ))
        )
    }

    // MARK: - Steps (static, so tests can run them without Siri)

    /// What a receipt file says, as the draft and the occasion it would log.
    struct Reading {
        let draft: ServiceReceiptDraft
        let occasion: ServiceLogging.Occasion
    }

    /// Read the file. Throws `IntentError.receiptUnreadable` when it isn't
    /// an image or PDF, or nothing useful can be read from it.
    @MainActor
    static func read(_ data: Data, for vehicle: Vehicle) async throws -> Reading {
        guard let image = DocumentImport.image(from: data) else { throw IntentError.receiptUnreadable }
        let result: ReceiptExtractionService.Result
        do {
            result = try await makeExtractor().extract(from: image, context: ReceiptExtractionService.context(for: vehicle))
        } catch {
            throw IntentError.receiptUnreadable
        }
        guard !result.draft.isEmpty else { throw IntentError.receiptUnreadable }
        return Reading(draft: result.draft, occasion: occasion(for: result, image: image))
    }

    /// The occasion a draft logs: the date, the odometer (stored miles), the
    /// total, the shop and lines, and the receipt attached with its text.
    @MainActor
    static func occasion(for result: ReceiptExtractionService.Result, image: UIImage) -> ServiceLogging.Occasion {
        let draft = result.draft
        return ServiceLogging.Occasion(
            date: draft.date,
            mileage: draft.odometer,
            totalCost: draft.total,
            shop: draft.shopName,
            lineItems: draft.lineItems,
            attachments: AttachmentPicker.AttachmentData
                .scannedReceipt(image, page: 1, extractedText: result.scan.transcript)
                .map { [$0] } ?? []
        )
    }

    /// The write, once confirmed.
    @MainActor
    @discardableResult
    static func record(
        _ names: [String],
        on vehicle: Vehicle,
        occasion: ServiceLogging.Occasion,
        in context: ModelContext
    ) throws -> [ServiceLog] {
        let logs = ServiceLogging.log(names, on: vehicle, occasion: occasion, in: context)
        try IntentStore.commit(vehicle, in: context)
        return logs
    }
}
