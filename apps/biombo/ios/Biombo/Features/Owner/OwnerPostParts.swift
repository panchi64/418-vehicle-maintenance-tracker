import SwiftUI

/// "Evento": a title and when, off until the owner adds one (§6.8). Events
/// leave the map at their end.
struct OwnerEventSection: View {
    @Binding var draft: OwnerPostDraft

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Toggle(isOn: $draft.hasEvent) {
                Text("Añadir un evento", comment: "Owner post: add an event")
                    .textRole(.headline)
            }
            .frame(minHeight: Size.target)
            if draft.hasEvent {
                VStack(alignment: .leading, spacing: 0) {
                    TextField(text: $draft.eventTitle, prompt: Text("Noche de bomba y plena", comment: "Owner post: example event title")) {
                        Text("Qué", comment: "Owner post: the event's title")
                    }
                    .textRole(.body)
                    .frame(minHeight: Size.target)
                    if let term = draft.eventBlockedTerm {
                        BlockedTermLine(term: term)
                            .padding(.bottom, Spacing.s2)
                            .id(BlockedTermLine.Field.event)
                    }
                    RowDivider(isInset: false)
                    DatePicker(selection: $draft.eventStart, displayedComponents: [.date, .hourAndMinute]) {
                        Text("Empieza", comment: "Owner post: when the event starts")
                    }
                    .frame(minHeight: Size.target)
                    RowDivider(isInset: false)
                    DatePicker(selection: $draft.eventEnd, in: draft.eventStart..., displayedComponents: [.date, .hourAndMinute]) {
                        Text("Termina", comment: "Owner post: when the event ends")
                    }
                    .frame(minHeight: Size.target)
                }
                .textRole(.body)
                .insetGroup()
                .environment(\.timeZone, PuertoRico.timeZone)
            }
        }
    }
}

/// Under the field that has it: a word owners can't publish (§5).
struct BlockedTermLine: View {
    /// The owner's free-text fields, as scroll targets.
    enum Field: Hashable {
        case product
        case event
    }

    let term: String

    var body: some View {
        Label {
            Text("Quita “\(term)”: lo que publicas no puede nombrar agencias ni sonar a aviso oficial.", comment: "Owner post: a blocked word must be removed")
        } icon: {
            Image(systemName: "exclamationmark.circle").accessibilityHidden(true)
        }
        .textRole(.footnote)
        .foregroundStyle(Color(.statusCritical))
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// "Así lo verán tus vecinos": the place row as the map will show it, with
/// the owner's seal.
struct OwnerPostPreview: View {
    let place: Place
    let draft: OwnerPostDraft

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            SectionHeader(title: LocalizedStringResource("Así lo verán tus vecinos", comment: "Owner post: preview of how neighbours will see it"))
            HStack(spacing: Spacing.s3) {
                LayerPin(layer: .businesses, glyph: draft.status.kind.glyph)
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: place.name)
                        .textRole(.body)
                        .foregroundStyle(Color(.ink))
                    VerificationBadge(label: .verifiedOwner)
                }
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: Spacing.s2)
                Text(draft.status.kind.verbForOwner)
                    .textRole(.value)
                    .foregroundStyle(Color(.ink))
                    .multilineTextAlignment(.trailing)
            }
            .padding(.vertical, Spacing.s2)
            .frame(minHeight: Size.target)
            .insetGroup()
            .accessibilityElement(children: .combine)
        }
    }
}
