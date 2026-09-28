import Foundation

/// The seam for owner verification (PRODUCT.md §5, open decision 22): the
/// account, the call to the place's public phone and the code heard on it,
/// and a document for staff review. The backend lands behind it; the app
/// injects it through the environment.
nonisolated protocol OwnerVerifying: Sendable {
    /// Sign in with Apple; owners need an account (§13).
    func signIn() async -> Bool
    /// Places the call that reads out a code.
    func call(_ placeID: Place.ID) async
    func check(code: String, for placeID: Place.ID) async -> Bool
    /// Sends the Registro de Comerciante for staff to review.
    func submit(document: Data, for placeID: Place.ID) async
    /// A pretend call's code, which sample builds show on screen; nil for a real call.
    var sampleCode: String? { get }
}

extension OwnerVerifying {
    nonisolated var sampleCode: String? { nil }
}

/// SAMPLE: nothing leaves the device. Signing in always succeeds and the
/// "call" reads out `code`, which the debug build shows on screen.
nonisolated struct SampleOwnerVerifier: OwnerVerifying {
    nonisolated static let code = "2468"

    func signIn() async -> Bool { true }
    func call(_ placeID: Place.ID) async {}
    func check(code: String, for placeID: Place.ID) async -> Bool { code == Self.code }
    func submit(document: Data, for placeID: Place.ID) async {}
    var sampleCode: String? { Self.code }
}
