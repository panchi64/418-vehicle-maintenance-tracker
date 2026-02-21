//
//  ClusteringDaysWindowPicker.swift
//  checkpoint
//
//  Picker for selecting service clustering days window
//

import SwiftUI

struct ClusteringDaysWindowPicker: View {
    @State private var selectedWindow: Int = ClusteringSettings.shared.daysWindow

    var body: some View {
        ZStack {
            Theme.backgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Text("DAYS WINDOW")
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(2)

                    VStack(spacing: 0) {
                        ForEach(ClusteringSettings.daysWindowOptions, id: \.self) { option in
                            windowRow(for: option)

                            if option != ClusteringSettings.daysWindowOptions.last {
                                Rectangle()
                                    .fill(Theme.gridLine)
                                    .frame(height: Theme.borderWidth)
                            }
                        }
                    }
                    .background(Theme.surfaceInstrument)
                    .brutalistBorder()

                    Text("Services due within this many days of each other will be suggested for bundling.")
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)
                        .lineSpacing(4)
                }
                .padding(Spacing.screenHorizontal)
                .padding(.top, Spacing.lg)
            }
        }
        .navigationTitle("Days Window")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedWindow) { _, newValue in
            Task { @MainActor in
                ClusteringSettings.shared.daysWindow = newValue
            }
        }
    }

    private func windowRow(for option: Int) -> some View {
        Button {
            selectedWindow = option
        } label: {
            HStack {
                Text("\(option) days")
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)

                if option == 30 {
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
        ClusteringDaysWindowPicker()
    }
    .preferredColorScheme(.dark)
}
