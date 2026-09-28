import Foundation

/// What the home sheet needs to show Quick Report, derived once by
/// `HomeView`: the flow, the context for the current focus, Cambiar's
/// choices, the doors that open it and the two that send.
struct QuickReportInput {
    let flow: ReportFlow
    let context: ReportContext
    let candidates: (Layer) -> [ReportTarget]
    /// "Reportar aquí": about where you stand.
    let reportHere: () -> Void
    /// Reportar under a detail: about the selection.
    let reportOnSelection: () -> Void
    /// "Otro precio" under a station: straight to "¿A cuánto está?" there.
    let reportPrice: (Place.ID) -> Void
    let onSend: (ReportKind, ReportValue?, ReportTarget, Data?) -> Void
    let onDetail: (ReportValue, ReportReceipt) -> Void
}
