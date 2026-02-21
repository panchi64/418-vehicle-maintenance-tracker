//
//  DueSoonDaysThresholdPicker.swift
//  checkpoint
//
//  Picker view for selecting the "due soon" days threshold
//

import SwiftUI

struct DueSoonDaysThresholdPicker: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedThreshold: Int = DueSoonSettings.shared.daysThreshold

    var body: some View {
        ZStack {
            Theme.backgroundPrimary
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text(L10n.dueSoonDaysDesc)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, Spacing.screenHorizontal)

                VStack(spacing: 0) {
                    ForEach(DueSoonSettings.daysOptions, id: \.self) { option in
                        thresholdRow(for: option)

                        if option != DueSoonSettings.daysOptions.last {
                            Rectangle()
                                .fill(Theme.gridLine)
                                .frame(height: Theme.borderWidth)
                        }
                    }
                }
                .background(Theme.surfaceInstrument)
                .brutalistBorder()
                .padding(.horizontal, Spacing.screenHorizontal)

                Spacer()
            }
            .padding(.top, Spacing.lg)
        }
        .navigationTitle(L10n.dueSoonDaysTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedThreshold) { _, newValue in
            Task { @MainActor in
                DueSoonSettings.shared.daysThreshold = newValue
            }
        }
    }

    private func thresholdRow(for option: Int) -> some View {
        Button {
            HapticService.shared.selectionChanged()
            selectedThreshold = option
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(option) \(L10n.commonDays)")
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textPrimary)

                    if option == 30 {
                        Text(L10n.dueSoonDefault)
                            .font(.brutalistSecondary)
                            .foregroundStyle(Theme.textTertiary)
                    }
                }

                Spacer()

                if selectedThreshold == option {
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
        DueSoonDaysThresholdPicker()
    }
    .preferredColorScheme(.dark)
}
