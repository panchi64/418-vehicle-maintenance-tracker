import AppIntents
import SwiftUI

/// What a voice report shows before it is sent (Contribute-VoiceSiri): Qué,
/// Dónde and Cuándo, so a misheard place is caught on screen. Speech has no
/// form to read back; this is it. Siri adds Cancelar and Reportar.
struct VoiceReportSnippetIntent: SnippetIntent {
    static let title: LocalizedStringResource = "Reporte por voz"
    static let isDiscoverable = false

    @Parameter(title: "Qué")
    var what: String

    @Parameter(title: "Dónde")
    var place: String

    init() {}

    init(what: String, place: String) {
        self.what = what
        self.place = place
    }

    @MainActor
    func perform() async throws -> some IntentResult & ShowsSnippetView {
        .result(view: VoiceReportCard(what: what, place: place))
    }
}

/// The card: the report is the one primary; where and when follow as
/// label and value rows.
struct VoiceReportCard: View {
    let what: String
    let place: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            row(LocalizedStringResource("Qué", comment: "Voice report card: what is reported"), value: Text(verbatim: what), isPrimary: true)
            row(LocalizedStringResource("Dónde", comment: "Voice report card: where"), value: Text(verbatim: place))
            row(LocalizedStringResource("Cuándo", comment: "Voice report card: when"), value: Text("Ahora", comment: "Voice report card: the report is about right now"))
        }
        .padding(Spacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func row(_ label: LocalizedStringResource, value: Text, isPrimary: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .textRole(.footnote)
                .foregroundStyle(.secondary)
            value
                .textRole(isPrimary ? .answer : .body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

/// After sending: the done sentence, then what the agency already says there.
struct VoiceReportSentCard: View {
    let done: String
    let official: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Label {
                Text(verbatim: done)
                    .textRole(.headline)
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "checkmark.circle.fill").accessibilityHidden(true)
            }
            if let official {
                Label {
                    Text(verbatim: official)
                        .textRole(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "building.columns").accessibilityHidden(true)
                }
            }
        }
        .padding(Spacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
