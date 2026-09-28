import SwiftUI

/// Quick Report (PRODUCT.md §4.2, V2-QuickReport), in the home sheet: the
/// title with Atrás and Cerrar, then the step. No art, all SF (direction
/// §1.3). One tap sends; the sent state shows over the map with Deshacer.
struct QuickReportView: View {
    let flow: ReportFlow
    let context: ReportContext
    let candidates: (Layer) -> [ReportTarget]
    /// Send one kind, with an optional value and photo, to a target.
    let onSend: (ReportKind, ReportValue?, ReportTarget, Data?) -> Void
    let onDetail: (ReportValue, ReportReceipt) -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            header
            switch flow.step {
            case .menu:
                QuickReportMenu(context: context, hasChoices: hasChoices, onPick: pick, onChange: change, onOther: { flow.show(.layers) })
                SiriTip(intent: ReportConditionIntent(), storageKey: Preferences.quickReportSiriTip)
            case .layers:
                ReportLayerList(context: context) { flow.show(.layer($0)) }
            case .layer(let layer):
                ReportLayerPage(layer: layer, context: context, canChange: candidates(layer).count > 1, onPick: pick, onChange: { flow.show(.place(layer)) })
            case .price(let placeID):
                if let target = context.targets.values.first(where: { $0.place.id == placeID }) {
                    PriceReportView(target: target) { price, photo in
                        onSend(.price, .price(price), target, photo)
                    }
                }
            case .place(let layer):
                ReportPlacePicker(targets: candidates(layer), chosen: context.target(for: layer)?.place.id) { flow.choose($0, for: layer) }
            case .detail(let receipt):
                ReportDetailView(receipt: receipt) { value in
                    onDetail(value, receipt)
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: Spacing.s2) {
            if flow.canGoBack {
                BackButton(action: flow.back)
            }
            Text(title)
                .textRole(.answer)
                .foregroundStyle(Color(.ink))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
            CloseButton(action: onClose)
        }
    }

    private var title: LocalizedStringResource {
        switch flow.step {
        case .layers: LocalizedStringResource("¿Sobre qué quieres avisar?", comment: "Quick Report: pick what the report is about")
        case .layer(let layer): layer.title
        case .price: LocalizedStringResource("¿A cuánto está?", comment: "Price report title: what does gas cost here")
        case .place: LocalizedStringResource("¿Dónde?", comment: "Quick Report: pick another place in reach")
        case .detail: LocalizedStringResource("Añadir detalle", comment: "Add an optional detail to a report just sent")
        case .menu: context.title
        }
    }

    /// Cambiar shows only when another place of the lead's kind is in reach.
    private var hasChoices: Bool {
        guard context.focus == .whereYouAre, let layer = context.layer else { return false }
        return candidates(layer).count > 1
    }

    private func change() {
        if let layer = context.layer { flow.show(.place(layer)) }
    }

    /// A price needs typing; everything else is one tap.
    private func pick(_ kind: ReportKind) {
        guard let target = context.target(for: kind), target.isInReach else { return }
        if kind.needsTyping {
            flow.show(.price(target.place.id))
        } else {
            onSend(kind, nil, target, nil)
        }
    }
}
