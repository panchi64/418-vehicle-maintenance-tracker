@testable import Biombo
import CoreGraphics
import Foundation
import Testing

@Suite("Detail rules: confirm, hand-off, reliability, ages, map ground")
struct DetailRulesTests {
    let now = SampleData.now

    @Test("A changed price asks what changed; anything else is answered at once")
    func confirmSteps() {
        let price = ConfirmQuestion.price(FuelPrice(grade: .regular, centsPerLitre: 99))
        #expect(ConfirmStep.asking.replying(.changed, to: price) == .askingWhatChanged)
        #expect(ConfirmStep.askingWhatChanged.replying(.noGas, to: price) == .answered(.noGas))
        #expect(ConfirmStep.asking.replying(.changed, to: .outage(.power)) == .answered(.changed))
        #expect(ConfirmStep.asking.replying(.same, to: price) == .answered(.same))
        #expect(ConfirmStep.answered(.same).replying(.changed, to: price) == .answered(.same))
    }

    @Test("Official items are never voted on")
    func officialNoVote() {
        #expect(!VerificationLabel.official(.aaa).canBeVotedOn)
        #expect(VerificationLabel.unverified.canBeVotedOn)
        #expect(VerificationLabel.verifiedOwner.canBeVotedOn)
    }

    @Test("Abrir en… offers only installed apps, and opens Maps directly when alone")
    func handOff() {
        #expect(MapsHandOff(installed: []) == .open(.appleMaps))
        #expect(MapsHandOff(installed: [.waze]) == .choose([.appleMaps, .waze]))
        #expect(MapsHandOff(installed: [.waze, .googleMaps, .appleMaps]) == .choose([.appleMaps, .googleMaps, .waze]))
    }

    @Test("Hand-off URLs open driving directions to the place")
    func handOffURLs() {
        let point = GeoPoint(18.3747, -66.1197)
        #expect(MapsApp.appleMaps.directionsURL(to: point).absoluteString == "https://maps.apple.com/?daddr=18.3747,-66.1197&dirflg=d")
        #expect(MapsApp.googleMaps.directionsURL(to: point).absoluteString == "comgooglemaps://?daddr=18.3747,-66.1197&directionsmode=driving")
        #expect(MapsApp.waze.directionsURL(to: point).absoluteString == "waze://?ll=18.3747,-66.1197&navigate=yes")
        #expect(MapsApp.appleMaps.probeURL == nil)
    }

    @Test("Reliability shows only with 5 reports from 3 devices, in words")
    func reliability() {
        func tally(_ reports: Int, _ devices: Int, _ share: Double) -> ChargerTally {
            ChargerTally(placeID: "c", reports: reports, devices: devices, works: 0, weightedWorksShare: share)
        }
        #expect(ChargerReliability(nil) == .unknown)
        #expect(ChargerReliability(tally(4, 4, 1)) == .unknown)
        #expect(ChargerReliability(tally(9, 2, 1)) == .unknown)
        #expect(ChargerReliability(tally(5, 3, 0.8)) == .usuallyWorks)
        #expect(ChargerReliability(tally(5, 3, 0.6)) == .sometimesFails)
        #expect(ChargerReliability(tally(5, 3, 0.2)) == .oftenFails)
    }

    @Test("Coarse ages never give an exact time")
    func coarseAge() {
        let calendar = PuertoRico.calendar
        func at(_ hour: Int, daysAgo: Int = 0) -> Date {
            let day = calendar.date(byAdding: .day, value: -daysAgo, to: calendar.startOfDay(for: now))!
            return calendar.date(byAdding: .hour, value: hour, to: day)!
        }
        #expect(CoarseAge(at(9), now: now) == .thisMorning)
        #expect(CoarseAge(at(15), now: now) == .thisAfternoon)
        #expect(CoarseAge(at(17), now: now) == .thisAfternoon)
        #expect(CoarseAge(at(20, daysAgo: 1), now: now) == .yesterday)
        #expect(CoarseAge(at(20, daysAgo: 3), now: now) == .earlier)
    }

    @Test("The painted island fades from island zoom to nothing at street zoom")
    func paintedOpacity() {
        #expect(PaintedGround.opacity(latitudeDelta: 2, longitudeDelta: 1.2) == 1)
        #expect(abs(PaintedGround.opacity(latitudeDelta: 1, longitudeDelta: 0.6) - 0.6) < 0.001)
        #expect(PaintedGround.opacity(latitudeDelta: 0.1, longitudeDelta: 0.05) == 0)
        let spans = [0.9, 0.7, 0.5, 0.3, 0.2, 0.13, 0.1]
        let opacities = spans.map { PaintedGround.opacity(latitudeDelta: $0, longitudeDelta: $0) }
        #expect(opacities == opacities.sorted(by: >))
    }

    @Test("The painting's size follows the visible span")
    func paintedSize() {
        let map = CGSize(width: 400, height: 800)
        let wide = PaintedGround.size(centerLatitude: 18.2, latitudeDelta: 4, longitudeDelta: 2.2084, mapSize: map)
        #expect(abs(wide.width - 400) < 1)
        let closer = PaintedGround.size(centerLatitude: 18.2, latitudeDelta: 2, longitudeDelta: 1.1042, mapSize: map)
        #expect(abs(closer.width - 800) < 1)
        #expect(abs(closer.height / wide.height - 2) < 0.01)
        #expect(PaintedGround.size(centerLatitude: 18, latitudeDelta: 0, longitudeDelta: 0, mapSize: map) == .zero)
    }

    @Test("Crisis, Increase Contrast and Reduce Transparency force the plain map")
    func groundForced() {
        #expect(MapGround.painted.effective(isCrisis: false, increasedContrast: false, reduceTransparency: false) == .painted)
        #expect(MapGround.painted.effective(isCrisis: true, increasedContrast: false, reduceTransparency: false) == .plain)
        #expect(MapGround.painted.effective(isCrisis: false, increasedContrast: true, reduceTransparency: false) == .plain)
        #expect(MapGround.painted.effective(isCrisis: false, increasedContrast: false, reduceTransparency: true) == .plain)
        #expect(MapGround.plain.effective(isCrisis: false, increasedContrast: false, reduceTransparency: false) == .plain)
    }

    @Test("Units follow the region until the user picks: gallons only for the US mainland")
    func unitDefault() {
        #expect(PriceUnit.regionDefault(Locale.Region("PR")) == .litre)
        #expect(PriceUnit.regionDefault(.unitedStates) == .gallon)
        #expect(PriceUnit.regionDefault(nil) == .litre)
    }

    @Test("-vantage lat,lon moves where cerca is measured from; junk is ignored")
    func vantageArgument() {
        #expect(LaunchArguments.vantage(in: ["app", "-vantage", "18.3755,-66.1190"]) == GeoPoint(18.3755, -66.1190))
        #expect(LaunchArguments.vantage(in: ["app", "-vantage", "north"]) == nil)
        #expect(LaunchArguments.vantage(in: ["app", "-vantage"]) == nil)
        #expect(LaunchArguments.vantage(in: ["app"]) == nil)
    }
}
