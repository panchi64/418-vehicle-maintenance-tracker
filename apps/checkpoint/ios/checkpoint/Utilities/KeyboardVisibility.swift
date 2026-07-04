import SwiftUI
import UIKit

/// Tracks system keyboard visibility so bottom action bars can hide while a
/// number pad or keyboard would otherwise overlap them (G3). There is only
/// ever one keyboard, so a single shared observer is sufficient for every form.
@Observable
@MainActor
final class KeyboardVisibility {
    static let shared = KeyboardVisibility()

    var isVisible = false

    private var showObserver: NSObjectProtocol?
    private var hideObserver: NSObjectProtocol?

    private init() {
        // queue: .main guarantees these closures run on the main thread, but
        // the compiler can't prove it — assumeIsolated makes it explicit.
        showObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.isVisible = true
            }
        }
        hideObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.isVisible = false
            }
        }
    }
}
