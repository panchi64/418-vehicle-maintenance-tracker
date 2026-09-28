@testable import Biombo
import Foundation
import Testing

@MainActor
@Suite("First run: steps, the layer choice, and what the map draws after")
struct OnboardingTests {
    @Test("Three steps forward and back; Continuar needs at least one layer")
    func steps() {
        var flow = OnboardingFlow()
        #expect(flow.step == .welcome)
        #expect(flow.number == 1)
        #expect(!flow.canGoBack)
        flow.back()
        #expect(flow.step == .welcome)

        flow.advance()
        #expect(flow.step == .layers)
        #expect(flow.number == 2)
        for layer in flow.layers { flow.toggle(layer) }
        #expect(flow.layers.isEmpty)
        #expect(!flow.canContinue)
        flow.advance()
        #expect(flow.step == .layers, "An empty map answers nothing, so it can't go on")

        flow.toggle(.chargers)
        flow.advance()
        #expect(flow.step == .location)
        #expect(flow.isLast)
        #expect(flow.number == OnboardingFlow.stepCount)
        flow.advance()
        #expect(flow.step == .location)
        flow.back()
        #expect(flow.step == .layers)
    }

    @Test("It starts with the usual layers and hands back the choice and the watch wish")
    func result() {
        var flow = OnboardingFlow()
        #expect(flow.layers == Layer.defaultVisible(inCrisis: false))
        flow.toggle(.businesses)
        flow.toggle(.gas)
        flow.wantsToWatch = true
        let result = flow.result
        #expect(result.layers.contains(.businesses))
        #expect(!result.layers.contains(.gas))
        #expect(result.wantsToWatch)
    }

    @Test("A layer choice keeps between launches, in Capas order, skipping names it doesn't know")
    func layerChoice() throws {
        let choice = LayerChoice([.gas, .power, .businesses])
        #expect(choice.rawValue == "power,gas,businesses")
        #expect(LayerChoice(rawValue: choice.rawValue) == choice)
        let later = try #require(LayerChoice(rawValue: "water,ferries,roads"))
        #expect(later.layers == [.water, .roads])
        #expect(LayerChoice(rawValue: "")?.layers == [])
    }

    @Test("The map opens on the choice on an ordinary day, and on every service in crisis")
    func initialLayers() {
        let chosen: Set<Layer> = [.chargers, .signal]
        #expect(Layer.initiallyVisible(inCrisis: false, chosen: chosen) == chosen)
        #expect(Layer.initiallyVisible(inCrisis: false, chosen: nil) == Layer.defaultVisible(inCrisis: false))
        #expect(Layer.initiallyVisible(inCrisis: true, chosen: chosen) == Layer.defaultVisible(inCrisis: true))

        let store = HomeStore(isCrisis: false, chosen: chosen)
        #expect(store.visibleLayers == chosen)
        store.applyCrisis(true, chosen: chosen)
        #expect(store.visibleLayers == Layer.defaultVisible(inCrisis: true))
        store.applyCrisis(false, chosen: chosen)
        #expect(store.visibleLayers == chosen, "After crisis the user's own choice comes back")
    }

    @Test("Launch flags skip or replay the first run")
    func launchFlags() throws {
        let defaults = try #require(UserDefaults(suiteName: "biombo.tests.onboarding"))
        defaults.removePersistentDomain(forName: "biombo.tests.onboarding")
        LaunchArguments.applyOnboarding(["-skipOnboarding"], to: defaults)
        #expect(defaults.bool(forKey: Preferences.hasOnboarded))
        LaunchArguments.applyOnboarding(["-onboarding"], to: defaults)
        #expect(!defaults.bool(forKey: Preferences.hasOnboarded))
    }
}
