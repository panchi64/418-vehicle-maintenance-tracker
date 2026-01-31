//
//  ClusteringMileageWindowPicker.swift
//  checkpoint
//
//  Picker for selecting service clustering mileage window
//

import SwiftUI

struct ClusteringMileageWindowPicker: View {
    @State private var selectedWindow: Int = ClusteringSettings.shared.mileageWindow

    var body: some View {
        ZStack {
            Theme.backgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Text("MILEAGE WINDOW")
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(2)

                    VStack(spacing: 0) {
                        ForEach(ClusteringSettings.mileageWindowOptions, id: \.self) { option in
                            windowRow(for: option)

                            if option != ClusteringSettings.mileageWindowOptions.last {
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

                    Text("Services within this mileage range of each other will be suggested for bundling.")
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)
                        .lineSpacing(4)
                }
                .padding(Spacing.screenHorizontal)
                .padding(.top, Spacing.lg)
            }
        }
        .navigationTitle("Mileage Window")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedWindow) { _, newValue in
            Task { @MainActor in
                ClusteringSettings.shared.mileageWindow = newValue
            }
        }
    }

    private func windowRow(for option: Int) -> some View {
        Button {
            selectedWindow = option
        } label: {
            HStack {
                Text("\(Formatters.mileageNumber(option)) \(DistanceSettings.shared.unit.abbreviation)")
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)

                if option == 1000 {
                    Text("(default)")
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)
                }

                Spacer()

                if selectedWindow == option {
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
        ClusteringMileageWindowPicker()
    }
    .preferredColorScheme(.dark)
}
