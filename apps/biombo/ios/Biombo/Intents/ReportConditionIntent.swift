import AppIntents
import Foundation
import SwiftUI

/// "Reporta en Biombo que no hay luz" (PRODUCT.md §11). Where is where you
/// stand, or a place you watch. It always asks first with a card (open
/// decision 15), then joins the outbox, which the app files like any report.
/// Works on every device tier: nothing here needs Apple Intelligence.
struct ReportConditionIntent: AppIntent {
    static let title: LocalizedStringResource = "Reportar en Biombo"
    static let description = IntentDescription("Avisa a tus vecinos qué pasa donde estás: luz, agua, señal, carreteras o gasolina.")

    @Parameter(title: "Qué pasa", requestValueDialog: "¿Qué quieres reportar?")
    var condition: ReportCondition

    @Parameter(title: "Lugar vigilado", description: "Déjalo vacío para reportar donde estás.")
    var place: WatchedPlaceEntity?

    @Dependency var context: IntentContext

    static var parameterSummary: some ParameterSummary {
        Summary("Reportar que \(\.$condition)") {
            \.$place
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let locale = Locale.current
        guard let voice = await Self.draft(condition.kind, from: place?.id, in: context) else {
            throw VoiceReportError.nothingInReach
        }
        try await requestConfirmation(
            actionName: .send,
            dialog: IntentDialog(stringLiteral: voice.question(locale: locale).string(in: locale)),
            snippetIntent: VoiceReportSnippetIntent(what: voice.kind.word.string(in: locale), place: voice.whereWords.string(in: locale))
        )
        context.queue(voice)
        let official = await Self.officialLine(for: voice, in: context, locale: locale)
        let done = voice.done(locale: locale).string(in: locale)
        return .result(dialog: IntentDialog(stringLiteral: done), view: VoiceReportSentCard(done: done, official: official))
    }

    /// The report the card shows, about a watched place or where you stand.
    /// Kept apart from `perform()` so tests can run it without Siri.
    @MainActor
    static func draft(_ kind: ReportKind, from placeID: UUID?, in context: IntentContext) async -> VoiceReport? {
        guard let snapshot = await context.snapshot() else { return nil }
        let point = placeID.flatMap { id in context.watches.places.first { $0.id == id }?.location } ?? snapshot.vantage
        let areas = AnswerResolver().areaStatuses(snapshot.outageAreas, isCrisis: snapshot.crisis.isActive, now: snapshot.generatedAt)
        return VoiceReport.make(kind, at: point, snapshot: snapshot, areas: areas)
    }

    /// "LUMA ya reporta sin luz en partes de Caguas desde las 3:10 p. m."
    @MainActor
    private static func officialLine(for voice: VoiceReport, in context: IntentContext, locale: Locale) async -> String? {
        let layer = voice.kind.layer
        guard layer.aggregatesIntoAreas, let digest = await context.digest() else { return nil }
        let municipio = voice.target.place.municipio
        return ConditionAnswer.make(service: layer, municipio: municipio, areas: digest.areas)
            .officialLine(service: layer, municipio: municipio, locale: locale)?
            .string(in: locale)
    }
}

/// Said by Siri when a voice report can't be placed.
enum VoiceReportError: Error, CustomLocalizedStringResourceConvertible {
    /// Nothing of that kind is near enough to report on.
    case nothingInReach

    var localizedStringResource: LocalizedStringResource {
        LocalizedStringResource("No encontré dónde reportarlo. Abre Biombo y escoge el lugar en Reportar.", comment: "Siri: nothing of that kind is in reach to report on")
    }
}
