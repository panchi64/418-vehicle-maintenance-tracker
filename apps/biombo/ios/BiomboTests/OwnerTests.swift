@testable import Biombo
import Foundation
import Testing

@Suite("Owners: claiming a business and posting as its owner")
struct OwnerTests {
    private let now = SampleData.now

    @Test("A claim starts only at the place, asks for an account once, and a right code verifies for a year")
    func phoneClaim() throws {
        var far = OwnerClaimFlow(placeID: "p", isPresent: false)
        far.start()
        #expect(far.step == .intro)

        var flow = OwnerClaimFlow(placeID: "p", isPresent: true)
        flow.start()
        #expect(flow.step == .account)
        flow.signedIn()
        #expect(flow.step == .method)
        flow.requestCall()
        #expect(flow.step == .code(attemptsLeft: ContributionRules.ownerCodeAttempts))
        flow.entered(codeIsCorrect: false, now: now)
        #expect(flow.step == .code(attemptsLeft: ContributionRules.ownerCodeAttempts - 1))
        flow.entered(codeIsCorrect: true, now: now)
        guard case .verified(let until) = flow.step else {
            Issue.record("Expected verified")
            return
        }
        #expect(until == now.addingTimeInterval(ContributionRules.ownerVerificationLength))
    }

    @Test("Signed in already, a claim goes straight to choosing how; wrong codes lock until another call")
    func lockout() {
        var flow = OwnerClaimFlow(placeID: "p", isPresent: true, isSignedIn: true)
        flow.start()
        #expect(flow.step == .method)
        flow.requestCall()
        for _ in 0..<ContributionRules.ownerCodeAttempts { flow.entered(codeIsCorrect: false, now: now) }
        #expect(flow.step == .locked)
        flow.entered(codeIsCorrect: true, now: now)
        #expect(flow.step == .locked)
        flow.callAgain()
        #expect(flow.step == .code(attemptsLeft: ContributionRules.ownerCodeAttempts))
    }

    @Test("A document goes to review; back steps return to the choice")
    func document() {
        var flow = OwnerClaimFlow(placeID: "p", isPresent: true, isSignedIn: true)
        flow.start()
        flow.requestCall()
        flow.back()
        #expect(flow.step == .method)
        flow.submittedDocument()
        #expect(flow.step == .inReview)
    }

    @Test("Owner text can't name an agency or sound like an alert, in any case or accent", arguments: [
        ("Hay hielo y agua", nil as String?),
        ("Pan sobao", nil),
        ("Luz de LUMA volvió", "LUMA"),
        ("hierve el agua antes de tomar", "hierve el agua"),
        ("REFUGIO aquí", "refugio"),
        ("Evacuacion", "evacuación"),
        ("Plaaaan", nil),
        ("Productos de salud natural", nil),
        ("Aviso del Departamento de Salud", "Departamento de Salud"),
    ])
    func filter(text: String, blocked: String?) {
        #expect(OwnerTextFilter.blockedTerm(in: text) == blocked)
    }

    @Test("A post is today's status until midnight, plus a product and an event")
    func postReports() throws {
        var draft = OwnerPostDraft(now: now)
        draft.status = .onGenerator
        draft.product = "  Hielo "
        draft.hasEvent = true
        draft.eventTitle = "Noche de bomba y plena"
        #expect(draft.canPublish)
        let reports = draft.reports(for: "b", now: now)
        #expect(reports.map(\.kind) == [.businessOnGenerator, .productAvailable, .event])
        #expect(reports.allSatisfy { $0.source == .owner })
        let status = try #require(reports.first)
        let end = try #require(status.statedEnd)
        #expect(PuertoRico.calendar.isDate(end, inSameDayAs: now))
        #expect(end > now)
        #expect(reports[1].value == .ownerText("Hielo"))
    }

    @Test("A blocked word or an untitled event keeps Publicar off; closed posts no product")
    func postGating() {
        var draft = OwnerPostDraft(now: now)
        draft.product = "Aviso oficial de AAA"
        #expect(!draft.canPublish)
        draft.product = ""
        draft.hasEvent = true
        #expect(!draft.canPublish)
        draft.eventTitle = "Bingo"
        #expect(draft.canPublish)
        draft.status = .closedToday
        draft.product = "Pan"
        #expect(!draft.reports(for: "b", now: now).contains { $0.kind == .productAvailable })
    }

    @Test("Closed for the day, a blocked word left in the hidden product doesn't keep Publicar off")
    func closedDayIgnoresProduct() {
        var draft = OwnerPostDraft(now: now)
        draft.product = "Refugio"
        #expect(draft.productBlockedTerm == "refugio" && !draft.canPublish)
        draft.status = .closedToday
        #expect(draft.productBlockedTerm == nil)
        #expect(draft.canPublish)
        draft.hasEvent = true
        draft.eventTitle = "Alerta de ofertas"
        #expect(draft.eventBlockedTerm == "alerta" && !draft.canPublish)
    }
}
