import SwiftUI

/// The one compact confirm question (PRODUCT.md §4.3), never a section:
/// "¿Sigue a $0.99?" · Sigue igual / Ya no. A changed price asks what
/// changed; the sent state is one sentence with Deshacer for 5 seconds.
/// Coming back to a place you voted on shows what you said, with Cambiar
/// while the one change is left.
/// Far from the place, the replies are disabled and a line says why; the
/// question itself stays in full ink, since it is information.
struct ConfirmRow: View {
    let question: ConfirmQuestion
    let step: ConfirmStep
    let canConfirm: Bool
    let onReply: (ConfirmReply) -> Void
    let onUndo: () -> Void
    /// "Cambiar" on a vote from an earlier visit.
    var onRevise: () -> Void = {}

    @State private var canUndo = true
    @Environment(\.locale) private var locale
    @Environment(\.priceUnit) private var unit
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            switch step {
            case .asking:
                ask(question.text(unit: unit, locale: locale), (LocalizedStringResource("Sigue igual", comment: "Confirm reply: still the same"), .same),
                    (LocalizedStringResource("Ya no", comment: "Confirm reply: no longer so"), .changed))
            case .askingWhatChanged:
                ask(LocalizedStringResource("¿Qué cambió?", comment: "Confirm follow-up after 'Ya no' on a price"),
                    (LocalizedStringResource("Otro precio", comment: "Confirm follow-up: the price is different"), .otherPrice),
                    (question.noLongerReply, .noGas))
            case .answered(let reply):
                said(reply.thanks, action: canUndo ? (LocalizedStringResource("Deshacer", comment: "Undo the reply just sent"), onUndo) : nil)
            case .standing(let agrees, let canChange):
                said(
                    agrees
                        ? LocalizedStringResource("Dijiste que sigue igual.", comment: "Confirm row on a later visit: you said it was still the same")
                        : LocalizedStringResource("Dijiste que ya no.", comment: "Confirm row on a later visit: you said it no longer was"),
                    action: canChange ? (LocalizedStringResource("Cambiar", comment: "Change a vote given earlier, once"), onRevise) : nil
                )
            }
        }
        .padding(.vertical, Spacing.s1)
        .frame(maxWidth: .infinity, minHeight: Size.target, alignment: .leading)
        .insetGroup()
        .task(id: step) {
            canUndo = true
            guard case .answered = step else { return }
            try? await Task.sleep(for: ContributionRules.undoWindow)
            canUndo = false
        }
    }

    private func ask(_ title: LocalizedStringResource, _ first: (LocalizedStringResource, ConfirmReply), _ second: (LocalizedStringResource, ConfirmReply)) -> some View {
        let question = Text(title).textRole(.headline).foregroundStyle(Color(.ink))
        let isStacked = dynamicTypeSize.isAccessibilitySize
        let replies = (isStacked ? AnyLayout(VStackLayout(spacing: Spacing.s2)) : AnyLayout(HStackLayout(spacing: Spacing.s2))) {
            replyButton(first.0, isStacked: isStacked) { onReply(first.1) }
            replyButton(second.0, isStacked: isStacked) { onReply(second.1) }
        }
        .disabled(!canConfirm)
        return VStack(alignment: .leading, spacing: Spacing.s2) {
            if isStacked {
                // At accessibility sizes the replies stack full width and wrap.
                question.fixedSize(horizontal: false, vertical: true)
                replies
            } else {
                // One line when the question and both replies fit; otherwise the replies go under it.
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Spacing.s2) {
                        question.fixedSize()
                        Spacer(minLength: 0)
                        replies
                    }
                    VStack(alignment: .leading, spacing: Spacing.s2) {
                        question.fixedSize(horizontal: false, vertical: true)
                        replies
                    }
                }
            }
            if !canConfirm {
                Label {
                    Text("Solo quien está cerca puede confirmar", comment: "Confirm row, far away: only people nearby can confirm")
                } icon: {
                    Image(systemName: "location.slash").accessibilityHidden(true)
                }
                .textRole(.footnote)
                .foregroundStyle(Color(.ink2))
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    /// A capsule reply. Disabled, it drops the tint and draws a dashed edge,
    /// so it reads as unavailable without dimming the question beside it.
    private func replyButton(_ title: LocalizedStringResource, isStacked: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .textRole(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(isStacked ? nil : 1)
                .fixedSize(horizontal: !isStacked, vertical: true)
                .padding(.horizontal, Spacing.s3)
                .padding(.vertical, isStacked ? Spacing.s2 : 0)
                .frame(maxWidth: isStacked ? .infinity : nil, minHeight: Size.target, alignment: .leading)
                .overlay {
                    shape(isStacked).stroke(Color(canConfirm ? .borderStrong : .ink3), style: StrokeStyle(lineWidth: 1, dash: canConfirm ? [] : [4, 3]))
                }
                .contentShape(shape(isStacked))
        }
        .buttonStyle(.plain)
        .foregroundStyle(canConfirm ? AnyShapeStyle(.tint) : AnyShapeStyle(Color(.ink2)))
    }

    /// A capsule on one line; stacked full-width rows use the card radius so tall text isn't cut by the curve.
    private func shape(_ isStacked: Bool) -> AnyShape {
        isStacked ? AnyShape(RoundedRectangle(cornerRadius: Radius.medium)) : AnyShape(Capsule())
    }

    /// What was said, with Deshacer (fresh) or Cambiar (from an earlier visit).
    private func said(_ text: LocalizedStringResource, action: (title: LocalizedStringResource, run: () -> Void)?) -> some View {
        HStack(spacing: Spacing.s3) {
            Label {
                Text(text)
            } icon: {
                Image(systemName: "checkmark").foregroundStyle(Color(.statusOk)).accessibilityHidden(true)
            }
            .textRole(.subheadline)
            .foregroundStyle(Color(.ink))
            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            if let action {
                Button(action: action.run) {
                    Text(action.title)
                        .textRole(.subheadline)
                        .frame(minHeight: Size.target)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tint)
            }
        }
        .accessibilityElement(children: .contain)
    }
}
