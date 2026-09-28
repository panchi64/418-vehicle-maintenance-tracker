import SwiftUI

/// The services behind the app's seams, injected by `BiomboApp` so no view
/// builds a sample one itself. nil means the service isn't there: no owner
/// verification, or no reading of price signs yet.
extension EnvironmentValues {
    @Entry var ownerVerifier: (any OwnerVerifying)?
    @Entry var priceSignReader: (any PriceSignReading)?
}
