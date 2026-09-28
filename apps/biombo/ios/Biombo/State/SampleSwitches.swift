import Observation

/// Sample-only switches (Ajustes › Muestra). Crisis mode still follows the
/// snapshot: this only asks the sample provider for its crisis variant.
@Observable
final class SampleSwitches {
    var isCrisis: Bool

    init(isCrisis: Bool = false) {
        self.isCrisis = isCrisis
    }
}
