//
//  CameraPermissionGate.swift
//  checkpoint
//
//  Shows its content only once camera access is granted. A capture session
//  started without permission renders a black viewfinder with a live CAPTURE
//  button — a screen that looks broken and says nothing about why. Denied users
//  get the reason and the one step that fixes it instead.
//

import SwiftUI
import AVFoundation

struct CameraPermissionGate<Content: View>: View {
    let onCancel: () -> Void
    @ViewBuilder let content: Content

    @State private var status = AVCaptureDevice.authorizationStatus(for: .video)
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            switch status {
            case .authorized:
                content
            case .notDetermined:
                // Brief: the system prompt is already on screen over this.
                Theme.backgroundPrimary
                    .ignoresSafeArea()
                    .task {
                        _ = await AVCaptureDevice.requestAccess(for: .video)
                        status = AVCaptureDevice.authorizationStatus(for: .video)
                    }
            default:
                deniedState
            }
        }
        // Returning from Settings with access granted should just work.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                status = AVCaptureDevice.authorizationStatus(for: .video)
            }
        }
    }

    private var deniedState: some View {
        ZStack {
            AtmosphericBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Image(systemName: "camera.fill")
                        .font(.largeTitle)
                        .foregroundStyle(Theme.textTertiary)
                        .accessibilityHidden(true)

                    Text(L10n.cameraAccessDeniedTitle)
                        .font(.brutalistHeading)
                        .foregroundStyle(Theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)

                    Text(L10n.cameraAccessDeniedMessage)
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(spacing: Spacing.sm) {
                        Button(L10n.cameraAccessOpenSettings) {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                openURL(url)
                            }
                        }
                        .buttonStyle(.primary)

                        Button(L10n.commonCancel, action: onCancel)
                            .buttonStyle(.secondary)
                    }
                    .padding(.top, Spacing.sm)
                }
                .padding(Spacing.screenHorizontal)
                .padding(.top, Spacing.xxl)
            }
        }
    }
}
