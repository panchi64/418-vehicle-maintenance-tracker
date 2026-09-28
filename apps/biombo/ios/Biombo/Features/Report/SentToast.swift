import SwiftUI

/// The sent state over the map, after Quick Report closes (PRODUCT.md §4.2,
/// V2-QuickReport): one sentence, Deshacer for 5 seconds and Añadir detalle.
/// Luz and agua add that the utility isn't told, with a way to tell it;
/// hazards add the 911 line. No art (direction §1.1). Announced to
/// VoiceOver; it leaves on its own only when it carries nothing to act on
/// and VoiceOver is off.
struct SentToast: View {
    let receipt: ReportReceipt
    let onUndo: () -> Void
    let onAddDetail: () -> Void
    let onClose: () -> Void

    /// Deshacer's window is open. Starts from the receipt, so a receipt with
    /// nothing to undo never flashes it.
    @State private var canUndo: Bool
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.priceUnit) private var unit
    @Environment(\.locale) private var locale

    private var sentence: LocalizedStringResource { receipt.sentence(unit: unit, locale: locale) }

    /// How long a plain receipt stays (*proposed*).
    static let lifetime: Duration = .seconds(8)

    init(receipt: ReportReceipt, onUndo: @escaping () -> Void, onAddDetail: @escaping () -> Void, onClose: @escaping () -> Void) {
        self.receipt = receipt
        self.onUndo = onUndo
        self.onAddDetail = onAddDetail
        self.onClose = onClose
        _canUndo = State(initialValue: receipt.canUndo)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            HStack(alignment: .top, spacing: Spacing.s2) {
                Image(systemName: receipt.delivery == .queued ? "tray.and.arrow.up" : "checkmark.circle.fill")
                    .foregroundStyle(Color(receipt.delivery == .queued ? .ink2 : .statusOk))
                    .accessibilityHidden(true)
                Text(sentence)
                    .textRole(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(.ink))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                CloseButton(action: onClose)
            }
            if receipt.isAloneForNow {
                Text("Parece que es solo tu casa o tu calle. Si más vecinos lo reportan, se marca el área.", comment: "Report sent: a lone outage report isn't an area until neighbours agree")
                    .textRole(.footnote)
                    .foregroundStyle(Color(.ink2))
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let agency = receipt.handOff {
                handOff(agency)
            }
            if receipt.showsSafetyLine {
                SafetyLine(kind: .hazard)
            }
            actions
        }
        .padding(Spacing.s3)
        .background {
            if contrast == .increased {
                RoundedRectangle(cornerRadius: Radius.plate)
                    .fill(Color(.paperSheet))
                    .overlay(RoundedRectangle(cornerRadius: Radius.plate).strokeBorder(Color(.borderStrong), lineWidth: 1))
            }
        }
        .glassEffect(contrast == .increased ? .identity : .regular, in: .rect(cornerRadius: Radius.plate))
        .accessibilityElement(children: .contain)
        .task(id: receipt) {
            AccessibilityNotification.Announcement(String(localized: sentence)).post()
            canUndo = receipt.canUndo
            try? await Task.sleep(for: ContributionRules.undoWindow)
            canUndo = false
            guard !receipt.staysUntilClosed, !voiceOver else { return }
            try? await Task.sleep(for: Self.lifetime - ContributionRules.undoWindow)
            onClose()
        }
    }

    /// "Esto no avisa a LUMA · Reportar a LUMA", or "Llamar a AAA" where the
    /// way to tell it is a phone call.
    private func handOff(_ agency: Agency) -> some View {
        HStack(spacing: Spacing.s2) {
            Text("Esto no avisa a \(agency.displayName).", comment: "Report sent: Biombo does not notify the utility")
                .textRole(.footnote)
                .foregroundStyle(Color(.ink2))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Spacing.s2)
            if let url = agency.reportURL {
                Link(destination: url) {
                    Text(agency.reportsByPhone
                         ? LocalizedStringResource("Llamar a \(agency.displayName)", comment: "Report sent: call the utility to tell it directly")
                         : LocalizedStringResource("Reportar a \(agency.displayName)", comment: "Report sent: tell the utility directly"))
                        .textRole(.footnote)
                        .fontWeight(.semibold)
                        .frame(minHeight: Size.target)
                }
                .foregroundStyle(.tint)
            }
        }
    }

    /// Both slots keep their place for the toast's whole life: when the
    /// window closes, Deshacer fades out where it was, so a late tap on it
    /// lands on nothing instead of on a stretched Añadir detalle.
    @ViewBuilder
    private var actions: some View {
        let hasDetail = receipt.detail != nil
        if hasDetail || receipt.canUndo {
            HStack(spacing: Spacing.s2) {
                if hasDetail {
                    toastButton(LocalizedStringResource("Añadir detalle", comment: "Add an optional detail to a report just sent"), action: onAddDetail)
                }
                if receipt.canUndo {
                    toastButton(LocalizedStringResource("Deshacer", comment: "Undo the reply just sent"), action: onUndo)
                        .opacity(canUndo ? 1 : 0)
                        .disabled(!canUndo)
                        .accessibilityHidden(!canUndo)
                        .animation(.easeOut(duration: 0.2), value: canUndo)
                }
            }
        }
    }

    private func toastButton(_ title: LocalizedStringResource, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .textRole(.subheadline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, minHeight: Size.target)
                .background(Color(.paperRaised), in: .rect(cornerRadius: Radius.medium))
                .contrastEdge(always: true)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.tint)
    }
}
