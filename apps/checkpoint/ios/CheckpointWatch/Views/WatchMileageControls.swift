//
//  WatchMileageControls.swift
//  CheckpointWatch
//
//  Pieces shared by the two Watch screens that take a mileage — update
//  mileage and mark service done: the Digital Crown dial, step buttons, the
//  "will sync" note, and the confirmation that follows a send.
//

import SwiftUI
import WatchKit

// MARK: - Mileage Dial

/// The mileage readout. Focused, it takes the Digital Crown (with a border to
/// show it has it); unfocused, the Crown scrolls the screen as usual. VoiceOver
/// adjusts it with swipe up/down.
struct MileageDial: View {
    @Binding var mileage: Double
    let unit: String
    let tint: Color
    /// Take the Crown on appear — for a screen whose whole job is this value.
    var autofocus = false

    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: WatchSpacing.xs) {
            WatchNumeral(Int(mileage).formatted())
                .foregroundStyle(tint)
            Text(unit)
                .font(.watchCaption)
                .foregroundStyle(WatchColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, WatchSpacing.sm)
        .overlay(
            Rectangle()
                .strokeBorder(focused ? tint : WatchColors.gridLine, lineWidth: WatchColors.borderWidth)
        )
        .focusable()
        .focused($focused)
        .digitalCrownRotation(
            $mileage,
            from: 0,
            through: 999_999,
            by: 10,
            sensitivity: .medium,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
        .onAppear {
            if autofocus { focused = true }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Mileage"))
        .accessibilityValue(Text(verbatim: "\(Int(mileage).formatted()) \(unit)"))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: mileage += 10
            case .decrement: mileage = max(0, mileage - 10)
            @unknown default: break
            }
        }
    }
}

// MARK: - Step Buttons

/// ±10 / ±100 nudges, two per row so they stay tappable at large text sizes.
struct MileageStepButtons: View {
    @Binding var mileage: Double

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        LazyVGrid(columns: columns, spacing: WatchSpacing.sm) {
            ForEach([-10, 10, -100, 100], id: \.self) { delta in
                Button {
                    mileage = max(0, mileage + Double(delta))
                } label: {
                    Text(verbatim: delta > 0 ? "+\(delta)" : "\(delta)")
                        .font(.watchLabel)
                        .foregroundStyle(WatchColors.textPrimary)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel(delta > 0 ? Text("Add \(abs(delta))") : Text("Subtract \(abs(delta))"))
            }
        }
    }
}

// MARK: - Unreachable Note

/// Shown while the iPhone is out of reach: the send is queued, not lost.
struct PhoneUnreachableNote: View {
    var body: some View {
        Text("WILL SYNC WHEN PHONE IS NEARBY")
            .font(.watchCaption)
            .foregroundStyle(WatchColors.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Confirmation

/// What follows a successful send: a success haptic, a clear word, and a
/// VoiceOver announcement of that word. Returns on its own after a beat —
/// except under VoiceOver, where the user leaves with Done once they have
/// heard it, so the screen never vanishes mid-announcement.
struct WatchConfirmation: View {
    let title: String
    let tint: Color
    let onFinish: () -> Void

    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled

    var body: some View {
        VStack(spacing: WatchSpacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(tint)
                .accessibilityHidden(true)

            Text(title)
                .font(.watchHeadline)
                .foregroundStyle(tint)
                .multilineTextAlignment(.center)

            Button(action: onFinish) {
                Text("DONE")
                    .font(.watchBody)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
        .task {
            WKInterfaceDevice.current().play(.success)
            AccessibilityNotification.Announcement(title).post()
            guard !voiceOverEnabled else { return }
            do {
                try await Task.sleep(for: .seconds(2))
            } catch {
                return // Left early via Done.
            }
            onFinish()
        }
    }
}
