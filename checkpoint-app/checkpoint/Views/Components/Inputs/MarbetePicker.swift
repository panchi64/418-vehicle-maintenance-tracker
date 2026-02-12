//
//  MarbetePicker.swift
//  checkpoint
//
//  Reusable picker for Puerto Rico marbete (vehicle registration tag) expiration
//

import SwiftUI

struct MarbetePicker: View {
    @Binding var month: Int?
    @Binding var year: Int?

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Month picker
            monthPicker

            // Year picker
            yearPicker

            // Status indicator (only shown when marbete is set)
            if month != nil && year != nil {
                statusIndicator
            }
        }
    }

    // MARK: - Month Picker

    private var monthPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("EXPIRATION MONTH")
                .font(.instrumentLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1.5)
                .textCase(.uppercase)

            Menu {
                Button("Not Set") {
                    month = nil
                    HapticService.shared.selectionChanged()
                }
                Divider()
                ForEach(1...12, id: \.self) { monthValue in
                    Button(Calendar.current.monthSymbols[monthValue - 1]) {
                        month = monthValue
                        HapticService.shared.selectionChanged()
                    }
                }
            } label: {
                HStack {
                    if let month = month {
                        Text(Calendar.current.monthSymbols[month - 1])
                            .font(.instrumentBody)
                            .foregroundStyle(Theme.textPrimary)
                    } else {
                        Text("Not Set")
                            .font(.instrumentBody)
                            .foregroundStyle(Theme.textTertiary)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }
                .padding(Spacing.md)
                .background(Theme.surfaceInstrument)
                .overlay(
                    Rectangle()
                        .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
                )
            }
        }
    }

    // MARK: - Year Picker

    private var yearPicker: some View {
        let currentYear = Calendar.current.component(.year, from: .now)
        let yearRange = currentYear...(currentYear + 2)

        return VStack(alignment: .leading, spacing: 6) {
            Text("EXPIRATION YEAR")
                .font(.instrumentLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1.5)
                .textCase(.uppercase)

            Menu {
                Button("Not Set") {
                    year = nil
                    HapticService.shared.selectionChanged()
                }
                Divider()
                ForEach(yearRange, id: \.self) { yearValue in
                    Button(String(yearValue)) {
                        year = yearValue
                        HapticService.shared.selectionChanged()
                    }
                }
            } label: {
                HStack {
                    if let year = year {
                        Text(String(year))
                            .font(.instrumentBody)
                            .foregroundStyle(Theme.textPrimary)
                    } else {
                        Text("Not Set")
                            .font(.instrumentBody)
                            .foregroundStyle(Theme.textTertiary)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }
                .padding(Spacing.md)
                .background(Theme.surfaceInstrument)
                .overlay(
                    Rectangle()
                        .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
                )
            }
        }
    }

    // MARK: - Status Indicator

    private var statusIndicator: some View {
        let status = computeStatus()
        let statusText = statusText(for: status)

        return HStack(spacing: Spacing.sm) {
            Rectangle()
                .fill(status.color)
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)

            Text(statusText)
                .font(.brutalistSecondary)
                .foregroundStyle(status.color)

            Spacer()

            if let formatted = formattedExpiration() {
                Text(formatted)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(Spacing.md)
        .background(status.color.opacity(0.1))
        .overlay(
            Rectangle()
                .strokeBorder(status.color.opacity(0.3), lineWidth: Theme.borderWidth)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Marbete status: \(statusText)")
        .accessibilityValue(formattedExpiration() ?? "")
    }

    // MARK: - Status Helpers

    private func computeStatus() -> ServiceStatus {
        guard let month = month,
              let year = year else { return .neutral }

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1

        guard let firstDay = Calendar.current.date(from: components),
              let lastDay = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: firstDay) else {
            return .neutral
        }

        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: lastDay)).day ?? 0

        if days < 0 {
            return .overdue
        } else if days <= 60 {
            return .dueSoon
        } else {
            return .good
        }
    }

    private func statusText(for status: ServiceStatus) -> String {
        switch status {
        case .overdue: return "EXPIRED"
        case .dueSoon: return "EXPIRES SOON"
        case .good: return "VALID"
        case .neutral: return ""
        }
    }

    private func formattedExpiration() -> String? {
        guard let month = month,
              let year = year else { return nil }
        let monthName = Calendar.current.monthSymbols[month - 1]
        return "\(monthName) \(year)"
    }
}

#Preview {
    ZStack {
        AtmosphericBackground()

        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Empty state
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    InstrumentSectionHeader(title: "Marbete - Empty")
                    MarbetePicker(month: .constant(nil), year: .constant(nil))
                }

                // Valid state
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    InstrumentSectionHeader(title: "Marbete - Valid")
                    MarbetePicker(month: .constant(12), year: .constant(2026))
                }

                // Expiring soon state
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    InstrumentSectionHeader(title: "Marbete - Expiring Soon")
                    MarbetePicker(month: .constant(2), year: .constant(2026))
                }

                // Expired state
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    InstrumentSectionHeader(title: "Marbete - Expired")
                    MarbetePicker(month: .constant(1), year: .constant(2025))
                }
            }
            .padding(Spacing.screenHorizontal)
        }
    }
    .preferredColorScheme(.dark)
}
