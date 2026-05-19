//
//  VehicleHeader.swift
//  checkpoint
//
//  Persistent vehicle header — left column shows nickname + make/model,
//  right column stacks settings/sync icons over the mileage + YTD readout.
//

import SwiftUI

struct VehicleHeader: View {
    let vehicle: Vehicle?
    var onTap: () -> Void
    var onMileageTap: (() -> Void)? = nil
    var onSettingsTap: (() -> Void)? = nil

    private var syncService: SyncStatusService {
        SyncStatusService.shared
    }

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            leftColumn

            Spacer()

            rightColumn
        }
        .padding(.horizontal, Theme.screenHorizontalPadding)
        .padding(.vertical, Spacing.listItem)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Theme.gridLine)
                .frame(height: Theme.borderWidth)
        }
    }

    // MARK: - Left column: [SELECT] + nickname + make/model

    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                onTap()
            } label: {
                Text("[SELECT]")
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.accent)
                    .tracking(1)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHidden(true)

            Button {
                onTap()
            } label: {
                Text(vehicle?.displayName.uppercased() ?? "SELECT_VEHICLE")
                    .font(.brutalistHero)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(vehicle?.displayName ?? "Select vehicle")
            .accessibilityHint("Double tap to choose a vehicle")

            if let vehicle = vehicle {
                Text("\(vehicle.make)_\(vehicle.model) \u{00B7} \(String(vehicle.year))".uppercased())
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.top, Spacing.xs)
            }
        }
    }

    // MARK: - Right column: settings/sync icons + mileage + YTD

    private var rightColumn: some View {
        VStack(alignment: .trailing, spacing: 0) {
            iconRow

            if let vehicle = vehicle {
                let metrics = drivingMetrics(for: vehicle)
                let mileageText = Formatters.mileage(vehicle.currentMileage)

                Button {
                    onMileageTap?()
                } label: {
                    Text(mileageText)
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.accent)
                        .underline(onMileageTap != nil, color: Theme.accent.opacity(0.5))
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.top, Spacing.xs)
                .accessibilityLabel("Mileage: \(mileageText)")
                .accessibilityHint(onMileageTap != nil ? "Double tap to update mileage" : "")

                if let line = metrics.subline {
                    Text(line)
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)
                        .padding(.top, Spacing.xs)
                        .accessibilityLabel(metrics.accessibilityLabel)
                }
            }
        }
    }

    private var iconRow: some View {
        HStack(spacing: 0) {
            if let error = syncService.currentError {
                Button {
                    onSettingsTap?()
                } label: {
                    Image(systemName: error.systemImage)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(error.iconColor)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Sync error")
                .accessibilityHint("Double tap to open settings")
            }

            if let onSettingsTap = onSettingsTap {
                Button {
                    onSettingsTap()
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Theme.textTertiary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Settings")
            }
        }
    }

    // MARK: - Driving metrics

    /// Computed once per render and shared by the visible subline + accessibility label.
    /// Each property access triggers a snapshot sort, so we read them once and derive everything here.
    private func drivingMetrics(for vehicle: Vehicle) -> DrivingMetrics {
        guard let ytd = vehicle.milesDrivenYearToDate else {
            return DrivingMetrics(subline: nil, accessibilityLabel: "")
        }

        let prior = ytd.isPartial ? nil : vehicle.milesDrivenSamePeriodLastYear
        let yoyRounded: Int? = {
            guard let prior, prior > 0 else { return nil }
            let percent = (Double(ytd.miles - prior) / Double(prior)) * 100
            return Int(percent.rounded())
        }()

        let subline: String
        if let rounded = yoyRounded {
            let yoyFragment: String
            if rounded == 0 {
                yoyFragment = "\u{2014} 0%"
            } else {
                let arrow = rounded > 0 ? "\u{2191}" : "\u{2193}"
                yoyFragment = "\(arrow) \(abs(rounded))%"
            }
            subline = "YTD \(Formatters.mileage(ytd.miles)) \u{00B7} \(yoyFragment)"
        } else {
            subline = "YTD \(Formatters.mileage(ytd.miles))"
        }

        var a11yParts = ["Year to date: \(Formatters.mileage(ytd.miles)) driven"]
        if let rounded = yoyRounded {
            let priorYear = Calendar.current.component(.year, from: .now) - 1
            let direction = rounded > 0 ? "up" : (rounded < 0 ? "down" : "flat")
            a11yParts.append("\(direction) \(abs(rounded)) percent versus \(priorYear)")
        }

        return DrivingMetrics(subline: subline, accessibilityLabel: a11yParts.joined(separator: ", "))
    }
}

private struct DrivingMetrics {
    let subline: String?
    let accessibilityLabel: String
}

#Preview {
    ZStack {
        AtmosphericBackground()

        VStack {
            VehicleHeader(
                vehicle: Vehicle.sampleVehicle,
                onTap: {
                    print("Vehicle header tapped")
                },
                onMileageTap: {
                    print("Mileage tapped")
                },
                onSettingsTap: {
                    print("Settings tapped")
                }
            )
            .padding(.top, Spacing.sm)

            Spacer()
        }
    }
    .preferredColorScheme(.dark)
}
