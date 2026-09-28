@testable import Biombo
import Foundation
import Testing

@MainActor
@Suite("Quick Report's steps: Atrás, Cambiar, the detail and the receipt")
struct ReportFlowTests {
    private func receipt(_ kind: ReportKind = .queue) -> ReportReceipt {
        ReportReceipt(reportID: UUID(), kind: kind, placeName: "Gulf", delivery: .sent)
    }

    @Test("Atrás goes up one level: a layer to the list, the list to the menu")
    func backThroughLayers() {
        let flow = ReportFlow()
        flow.begin()
        #expect(!flow.canGoBack)
        flow.show(.layers)
        flow.show(.layer(.water))
        flow.back()
        #expect(flow.step == .layers)
        flow.back()
        #expect(flow.step == .menu)
    }

    @Test("Cambiar and a price return to where they were opened from")
    func cambiarReturns() {
        let flow = ReportFlow()
        flow.begin()
        flow.show(.layers)
        flow.show(.layer(.gas))
        flow.show(.place(.gas))
        flow.choose(SampleData.ID.gulfBairoa, for: .gas)
        #expect(flow.step == .layer(.gas))
        #expect(flow.chosen[.gas] == SampleData.ID.gulfBairoa)
        flow.show(.price(SampleData.ID.gulfBairoa))
        flow.back()
        #expect(flow.step == .layer(.gas))
    }

    @Test("Añadir detalle has no Atrás: going back never starts a new report")
    func detailHasNoBack() {
        let flow = ReportFlow()
        flow.sent(receipt())
        flow.addDetail()
        #expect(flow.receipt == nil)
        guard case .detail = flow.step else {
            Issue.record("Añadir detalle should open the detail step")
            return
        }
        #expect(!flow.canGoBack)
        flow.back()
        guard case .detail = flow.step else {
            Issue.record("Atrás should do nothing on the detail step")
            return
        }
    }

    @Test("A new Quick Report clears the receipt still over the map, and what was picked")
    func beginClearsReceipt() {
        let flow = ReportFlow()
        flow.show(.place(.gas))
        flow.choose(SampleData.ID.gulfBairoa, for: .gas)
        flow.sent(receipt(.flooded))
        #expect(flow.receipt != nil)
        flow.begin()
        #expect(flow.receipt == nil)
        #expect(flow.chosen.isEmpty)
        #expect(flow.step == .menu)
    }
}
