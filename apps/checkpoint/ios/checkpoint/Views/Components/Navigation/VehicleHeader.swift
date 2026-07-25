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
    /// Drives the vehicle-specs panel that hangs below the header. Owned by the
    /// shell (ContentView) so the panel can render outside this view's bounds.
    var isSpecsExpanded: Binding<Bool>?

    private var syncService: SyncStatusService {
        SyncStatusService.shared
    }

    var body: some View {
        // Top-aligned, not bottom-aligned. The right column is taller (a 44pt
        // icon target plus the mileage block), so bottom alignment pushed the
        // vehicle name down and left dead space above it.
        HStack(alignment: .top, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 0) {
                leftColumn
                specsToggle
            }

            Spacer()

            rightColumn
        }
        // Was Theme.screenHorizontalPadding (16), which disagreed with the
        // Spacing.screenHorizontal (20) used by every tab below — so the header
        // was inset 4pt tighter than the content it sat above.
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.top, Spacing.xs)
        .padding(.bottom, Spacing.sm)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Theme.gridLine)
                .frame(height: Theme.borderWidth)
        }
    }

    // MARK: - Left column: [SELECT] + nickname + make/model

    /// The make/model/year line only earns its place when the user gave the
    /// vehicle a nickname. Without one, `displayName` is already
    /// "2026 Toyota RAV4", so this line repeated every word above it.
    private var specLine: String? {
        guard let vehicle, !vehicle.name.isEmpty else { return nil }
        return "\(vehicle.make) \(vehicle.model) \u{00B7} \(String(vehicle.year))".uppercased()
    }

    private var leftColumn: some View {
        // One button, not two stacked ones. `[SELECT]` and the name previously
        // were separate buttons firing the same action, with the first marked
        // accessibilityHidden — so VoiceOver saw one control and touch saw two.
        Button {
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                Text("[SELECT]")
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.accent)
                    .tracking(1)

                // Was brutalistHero (56pt) with minimumScaleFactor(0.5), so a
                // long nickname shrank to ~28pt and the header's weight swung
                // with the name's length. It also out-shouted every screen's
                // actual hero content. Persistent chrome identifies; it should
                // not dominate.
                Text(vehicle?.displayName.uppercased() ?? L10n.headerSelectVehicle)
                    .font(.brutalistTitle)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if let specLine {
                    Text(specLine)
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.top, Spacing.xs)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(vehicle?.displayName ?? L10n.headerSelectVehicleAccessibility)
        .accessibilityHint(L10n.headerSelectVehicleHint)
    }

    /// Specs disclosure, directly beneath the vehicle name so all vehicle
    /// identity — name, reference data, odometer — reads as one block.
    ///
    /// A separate control from the name button: the name opens the vehicle
    /// picker, and one control cannot own two actions.
    @ViewBuilder
    private var specsToggle: some View {
        if let isSpecsExpanded, vehicle != nil {
            Button {
                withAnimation(.easeOut(duration: Theme.animationMedium)) {
                    isSpecsExpanded.wrappedValue.toggle()
                }
            } label: {
                // Bracket notation, matching `[SELECT]` above and `[UPDATE]`
                // opposite. Brackets are this app's established signal for
                // "this text is a control" — a boxed chip is foreign to the
                // header, and a bare unbracketed label reads as a caption.
                HStack(spacing: Spacing.xs) {
                    Text("[\(L10n.headerSpecs)]")
                        .font(.brutalistLabel)
                        .tracking(1)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .rotationEffect(.degrees(isSpecsExpanded.wrappedValue ? 180 : 0))
                }
                .foregroundStyle(Theme.accent)
                .frame(minHeight: 44, alignment: .center)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.headerSpecsAccessibility)
            .accessibilityValue(
                isSpecsExpanded.wrappedValue
                    ? L10n.headerSpecsExpanded
                    : L10n.headerSpecsCollapsed
            )
        }
    }

    // MARK: - Right column: settings/sync icons + mileage

    private var rightColumn: some View {
        VStack(alignment: .trailing, spacing: 0) {
            iconRow

            if let vehicle = vehicle {
                let mileageText = Formatters.mileage(vehicle.currentMileage)
                let isInteractive = onMileageTap != nil
                let showsUpdatePrompt = vehicle.shouldDisplayMileageUpdatePrompt(isInteractive: isInteractive)

                Button {
                    onMileageTap?()
                } label: {
                    VStack(alignment: .trailing, spacing: 0) {
                        if isInteractive {
                            HStack(spacing: Spacing.xs) {
                                if showsUpdatePrompt {
                                    Rectangle()
                                        .fill(Theme.statusDueSoon)
                                        .frame(width: 6, height: 6)
                                        .accessibilityHidden(true)
                                }

                                Text("[UPDATE]")
                                    .font(.brutalistLabel)
                                    .foregroundStyle(Theme.accent)
                                    .tracking(1)
                            }
                        }

                        Text(mileageText)
                            .font(.brutalistBody)
                            .foregroundStyle(Theme.accent)
                    }
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .allowsHitTesting(isInteractive)
                .accessibilityLabel("Mileage: \(mileageText)")
                .accessibilityValue(showsUpdatePrompt ? "Update needed" : "")
                .accessibilityHint(isInteractive ? "Double tap to update odometer reading" : "")

                // The YTD / year-over-year line was removed from here. It was
                // 13pt tertiary in the corner of persistent chrome — a
                // genuinely interesting stat rendered where nobody would read
                // it, costing ~18pt of header height on every screen.
                // Phase 3 gives it a real ReadoutSection on Home, where it can
                // be a section's primary value rather than a footnote.
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

    // NOTE: `drivingMetrics` / `DrivingMetrics` were deleted along with the YTD
    // subline rather than left unused. The underlying data
    // (`Vehicle.milesDrivenYearToDate`, `milesDrivenSamePeriodLastYear`) is
    // untouched, so Phase 3 can surface it on Home as a real readout. It also
    // built its display strings by concatenation, which rule 11 forbids — the
    // replacement needs L10n format keys.
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
