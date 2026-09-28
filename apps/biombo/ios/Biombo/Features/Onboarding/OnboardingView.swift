import SwiftUI

/// The first run, in three steps (Flows-Onboarding1–3): what Biombo is, what
/// to see, and why it asks for location. Each page answers first; the step
/// count and the one filled button sit at the bottom, in reach of a thumb.
/// Nothing is required: "Ahora no" still opens the map, and viewing and
/// watching work without location (§13).
struct OnboardingView: View {
    let onFinish: (OnboardingResult) -> Void

    @State private var flow = OnboardingFlow()
    @State private var location = LocationPermission()
    @State private var isAsking = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                page
                    .padding(.horizontal, Spacing.gutter)
                    .padding(.vertical, Spacing.s4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .id(flow.step)
                    .transition(reduceMotion ? .opacity : .move(edge: .trailing).combined(with: .opacity))
            }
            .scrollBounceBehavior(.basedOnSize)
            footer
        }
        .background(Color(.paper).ignoresSafeArea())
    }

    private var header: some View {
        HStack {
            if flow.canGoBack {
                BackButton { animate { flow.back() } }
            }
            Spacer()
        }
        .frame(minHeight: Size.target)
        .padding(.horizontal, Spacing.gutter)
        .padding(.top, Spacing.s2)
    }

    @ViewBuilder
    private var page: some View {
        switch flow.step {
        case .welcome:
            WelcomePage()
        case .layers:
            LayersPage(flow: $flow)
        case .location:
            LocationPage()
        }
    }

    private var footer: some View {
        VStack(spacing: Spacing.s3) {
            Text("Paso \(flow.number) de \(OnboardingFlow.stepCount)", comment: "First run: which step of how many")
                .textRole(.footnote)
                .foregroundStyle(Color(.ink2))
            if flow.isLast {
                PrimaryButton(title: LocalizedStringResource("Permitir ubicación", comment: "First run: ask for location"), symbol: "location.fill") {
                    askForLocation()
                }
                .disabled(isAsking)
                Button {
                    onFinish(flow.result)
                } label: {
                    Text("Ahora no", comment: "First run: skip the location prompt")
                        .textRole(.headline)
                        .frame(maxWidth: .infinity, minHeight: Size.target)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tint)
            } else {
                PrimaryButton(title: LocalizedStringResource("Continuar", comment: "First run: next step")) {
                    animate { flow.advance() }
                }
                .disabled(!flow.canContinue)
            }
        }
        .padding(.horizontal, Spacing.gutter)
        .padding(.top, Spacing.s3)
        .padding(.bottom, Spacing.s4)
        .background(Color(.paper))
    }

    /// The system prompt, then the map, whatever the answer.
    private func askForLocation() {
        isAsking = true
        Task {
            await location.request()
            onFinish(flow.result)
        }
    }

    private func animate(_ change: () -> Void) {
        if reduceMotion {
            change()
        } else {
            withAnimation(.snappy, change)
        }
    }
}
