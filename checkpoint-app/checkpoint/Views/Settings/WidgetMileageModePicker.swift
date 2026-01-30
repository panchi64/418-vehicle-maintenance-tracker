//
//  WidgetMileageModePicker.swift
//  checkpoint
//
//  Mileage display mode picker for widget settings
//

import SwiftUI

struct WidgetMileageModePicker: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMode: WidgetMileageDisplayMode

    init() {
        _selectedMode = State(initialValue: WidgetSettingsManager.shared.mileageDisplayMode)
    }

    var body: some View {
        ZStack {
            Theme.backgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Section header
                    Text("MILEAGE DISPLAY")
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(2)

                    VStack(spacing: 0) {
                        ForEach(WidgetMileageDisplayMode.allCases, id: \.self) { mode in
                            modeRow(for: mode)

                            if mode != WidgetMileageDisplayMode.allCases.last {
                                Rectangle()
                                    .fill(Theme.gridLine)
                                    .frame(height: Theme.borderWidth)
                            }
                        }
                    }
                    .background(Theme.surfaceInstrument)
                    .overlay(
                        Rectangle()
                            .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
                    )

                    Spacer()
                }
                .padding(Spacing.screenHorizontal)
                .padding(.top, Spacing.lg)
            }
        }
        .navigationTitle("Mileage Display")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedMode) { _, newMode in
            Task { @MainActor in
                WidgetSettingsManager.shared.mileageDisplayMode = newMode
            }
        }
    }

    private func modeRow(for mode: WidgetMileageDisplayMode) -> some View {
        Button {
            selectedMode = mode
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.displayName)
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textPrimary)

                    Text(mode.description)
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)
                }

                Spacer()

                if selectedMode == mode {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.accent)
                }
            }
            .padding(Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        WidgetMileageModePicker()
    }
    .preferredColorScheme(.dark)
}
