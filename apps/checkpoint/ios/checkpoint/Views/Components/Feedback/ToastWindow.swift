//
//  ToastWindow.swift
//  checkpoint
//
//  Renders `ToastService`'s toast in its own window above the app's, so a toast
//  fired while a sheet is up is seen. It used to be an overlay on ContentView's
//  root, which every sheet covers — a save confirmation, or an Undo, raised
//  from inside a sheet played out underneath it.
//
//  The window passes every touch through except those landing on the toast
//  itself: `point(inside:)` answers only for the toast's frame, so UIKit falls
//  through to the app's window everywhere else. It never becomes key, so it
//  never takes the keyboard or first responder from the app.
//
//  Installed once per scene by `ToastWindowInstaller`, a zero-size view in
//  ContentView's background that hands over its `UIWindowScene`.
//

import SwiftUI
import UIKit

@MainActor
final class ToastWindowController {
    static let shared = ToastWindowController()

    private var window: PassthroughWindow?

    private init() {}

    func install(in scene: UIWindowScene) {
        guard window?.windowScene !== scene else { return }

        let window = PassthroughWindow(windowScene: scene)
        // Above the app's window and its sheets; below system alerts.
        window.windowLevel = .normal + 1
        window.backgroundColor = .clear

        let host = UIHostingController(rootView: ToastLayer(window: window))
        host.view.backgroundColor = .clear
        window.rootViewController = host
        window.isHidden = false
        self.window = window
    }
}

/// Hit-tests only inside `interactiveFrame` (window coordinates).
final class PassthroughWindow: UIWindow {
    var interactiveFrame: CGRect = .null

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        interactiveFrame.contains(point)
    }
}

/// The SwiftUI content of the toast window: the current toast, bottom-aligned
/// above the tab bar, reporting its frame so the window knows where to accept
/// touches.
private struct ToastLayer: View {
    let window: PassthroughWindow

    /// Clears the floating tab bar on the root screen. Over a sheet the toast
    /// simply sits a little higher than it needs to.
    private let tabBarClearance: CGFloat = 72

    var body: some View {
        let toast = ToastService.shared.currentToast

        VStack {
            Spacer()
            if let toast {
                ToastView(toast: toast)
                    .transition(.opacity)
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.bottom, tabBarClearance + Spacing.lg)
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame in
                        window.interactiveFrame = frame
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeOut(duration: Theme.animationMedium), value: toast?.id)
        .onChange(of: toast == nil) { _, isEmpty in
            if isEmpty { window.interactiveFrame = .null }
        }
    }
}

/// Zero-size view that installs the toast window into whichever scene it
/// lands in.
struct ToastWindowInstaller: UIViewRepresentable {
    func makeUIView(context: Context) -> SceneReportingView {
        SceneReportingView()
    }

    func updateUIView(_ uiView: SceneReportingView, context: Context) {}

    final class SceneReportingView: UIView {
        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard let scene = window?.windowScene else { return }
            ToastWindowController.shared.install(in: scene)
        }
    }
}
