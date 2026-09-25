//
//  VehicleSummaryBand.swift
//  checkpoint
//
//  The odometer and specs cells at the top of Home's scroll content, with the
//  vehicle-specs panel that expands beneath them.
//
//    ──────────────────────┬──────────────────────
//    ODOMETER □ 16 D OLD › │ SPECS             ⌄
//    33,417 mi             │ IWK-482 · 0W-20
//    ──────────────────────┴──────────────────────
//
//  This was the bottom band of `VehicleHeader`, the custom chrome that sat
//  above every tab. The system navigation bar now carries what the header's
//  top bands did — the vehicle name is the navigation title, switching lives in
//  its title menu, and Settings is a toolbar item — so only the data cells are
//  left, and they belong to Home: the odometer is the reading Home's
//  "what needs doing" is computed from.
//
//  The odometer and specs sit SIDE BY SIDE rather than as two stacked bands. As
//  separate full-width strips they read as two unrelated rules across the screen
//  and cost ~38pt more height; they are both "reference data about this vehicle,
//  tap for more", so one line is honest and cheaper.
//
//  SPECS STRIP, iteration history (it took five tries; read before revisiting):
//    v1  A full bordered QuickSpecsCard below the header.   Too heavy.
//    v2  A bare `SPECS ⌄` label inside the header.          Read as a caption.
//    v3  A bordered chip.                                   Foreign to the header.
//    v4  Bracket notation `[SPECS] ⌄`.                      Right vocabulary, but
//        the target was only as wide as the word (~70×44), and collapsing the
//        panel meant NOTHING was visible by default — the plate and oil spec that
//        used to be glanceable on Home became two taps away.
//    v5  (this) The collapsed row IS the summary. Full-width target, and its
//        label is real data, so the at-a-glance reference survives while the long
//        tail (VIN, tires, marbete, notes, documents) stays one tap away.
//

import SwiftUI

struct VehicleSummaryBand: View {
    let vehicle: Vehicle
    var onMileageTap: (() -> Void)?
    let onEdit: () -> Void
    let onDocumentsTap: () -> Void

    /// Collapsed by default, so the panel costs nothing until asked for.
    @State private var isSpecsExpanded = false

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var isAccessibilitySize: Bool { dynamicTypeSize.isAccessibilitySize }

    var body: some View {
        VStack(spacing: 0) {
            dataBand

            if isSpecsExpanded {
                QuickSpecsCard(
                    vehicle: vehicle,
                    onEdit: onEdit,
                    onDocumentsTap: onDocumentsTap
                )
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Theme.gridLine)
                .frame(height: Theme.borderWidth)
        }
        // The specs describe one vehicle; switching collapses them.
        .onChange(of: vehicle.id) { _, _ in
            isSpecsExpanded = false
        }
        // The stale tag is the mileage prompt now; keep counting impressions.
        .onAppear {
            if staleFlag != nil {
                AnalyticsService.shared.capture(.mileagePromptShown)
            }
        }
    }

    /// What the collapsed strip shows: the plate, needed constantly (parking,
    /// forms, the marbete line), and one parts-counter value.
    ///
    /// Held to two values on purpose. A third truncated mid-word at 393pt, and a
    /// line ending in "0W-20 Synth…" is not glanceable — it only signals that
    /// something was cut. VIN is deliberately absent: 17 characters would consume
    /// the row, and it is needed rarely but *exactly*, which is what the expanded
    /// panel is for.
    private var specsSummary: String? {
        let values = [vehicle.licensePlate, vehicle.oilType ?? vehicle.tireSize]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        guard !values.isEmpty else { return nil }
        return values.joined(separator: "  \u{00B7}  ")
    }

    /// "16 d old" on the odometer cell when the reading is stale. It replaced a
    /// separate "update your mileage" card above the hero, which pushed Next Up
    /// down on exactly the days a stale reading made it least trustworthy, and
    /// warned away from the control that resolves it. This cell IS that
    /// control. Word + shape; the bare square it grew from was color alone.
    private var staleFlag: String? {
        guard vehicle.shouldDisplayMileageUpdatePrompt(isInteractive: onMileageTap != nil) else {
            return nil
        }
        guard let days = vehicle.daysSinceMileageUpdate, vehicle.currentMileage > 0 else {
            return L10n.homeOdometerUpdate
        }
        return L10n.homeOdometerDaysOld(days)
    }

    private var dataBand: some View {
        AdaptiveStack(spacing: 0) {
            // The trailing glyphs differ on purpose: `chevron.right` opens a
            // sheet, `chevron.down` expands in place. One glyph for both would
            // promise the same behavior from two controls that behave
            // differently.
            SummaryCell(
                label: L10n.headerOdometer,
                value: Formatters.mileage(vehicle.currentMileage),
                valueColor: Theme.accent,
                // The literal odometer. If any readout in the app rolls, it's
                // this one.
                rollsDigits: true,
                subjectID: vehicle.id,
                glyph: "chevron.right",
                flag: staleFlag,
                growsToFill: isAccessibilitySize,
                action: onMileageTap
            )

            // Vertical rule between side-by-side cells; horizontal once they
            // stack at accessibility sizes.
            Rectangle()
                .fill(Theme.gridLine)
                .frame(width: isAccessibilitySize ? nil : 1, height: isAccessibilitySize ? 1 : nil)
                .accessibilityHidden(true)

            SummaryCell(
                label: L10n.headerSpecs,
                // Not uppercased. These are values, not labels — and the panel
                // below renders the same oil spec in sentence case, so
                // uppercasing here would show one datum two ways.
                value: specsSummary ?? "—",
                valueColor: Theme.textSecondary,
                glyph: "chevron.down",
                isGlyphRotated: isSpecsExpanded,
                isActive: isSpecsExpanded,
                isExpanded: isSpecsExpanded,
                growsToFill: true,
                action: {
                    withAnimation(.easeOut(duration: Theme.animationMedium)) {
                        isSpecsExpanded.toggle()
                    }
                }
            )
        }
        .fixedSize(horizontal: false, vertical: true)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.gridLine)
                .frame(height: 1)
        }
    }
}

// MARK: - Summary cell

/// One cell of the band. Both cells share this so they cannot drift apart —
/// the odometer and the specs strip are the same kind of thing and should stay
/// the same shape.
private struct SummaryCell: View {
    let label: String
    let value: String
    var valueColor: Color = Theme.textSecondary
    /// Opt-in per cell rather than inferred from the string: the specs cell
    /// carries a plate and an oil grade, and rolling the digits inside
    /// "IWK-482 · 0W-20" would animate an identifier as though it were a
    /// quantity.
    var rollsDigits: Bool = false
    /// Which vehicle the value describes. Without this a rolling cell would
    /// animate between two cars' readings as though one reading had changed.
    var subjectID: AnyHashable?
    let glyph: String
    var isGlyphRotated: Bool = false
    /// Stale-reading tag beside the label, drawn as the due-soon mark + word.
    var flag: String?
    var isActive: Bool = false
    var isExpanded: Bool?
    /// Set on the cell that should absorb the leftover width.
    var growsToFill: Bool = false
    var action: (() -> Void)?

    private var labelText: some View {
        Text(label.uppercased())
            .font(.brutalistLabel)
            .foregroundStyle(Theme.textTertiary)
            .tracking(1.5)
            .lineLimit(1)
    }

    @ViewBuilder
    private var flagTag: some View {
        if let flag {
            HStack(spacing: 3) {
                StatusMark(status: .dueSoon)
                Text(flag.uppercased())
                    .font(.brutalistLabelBold)
                    .tracking(1)
                    .foregroundStyle(Theme.statusDueSoon)
                    .lineLimit(1)
            }
            .fixedSize()
        }
    }

    /// The trailing glyph, pushed to the edge on the cell that fills the row.
    @ViewBuilder
    private var glyphRow: some View {
        if growsToFill {
            Spacer(minLength: Spacing.xs)
        }
        Image(systemName: glyph)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Theme.accent)
            .rotationEffect(.degrees(isGlyphRotated ? 180 : 0))
            .accessibilityHidden(true)
    }

    var body: some View {
        Button {
            action?()
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                // Label and flag on one line when they fit; otherwise the flag
                // drops beneath, rather than truncating the label ("ODÓMET…"
                // beside "ACTUALIZAR" in Spanish, or at large type).
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Spacing.xs) {
                        labelText
                        flagTag
                        glyphRow
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: Spacing.xs) {
                            labelText
                            glyphRow
                        }
                        flagTag
                    }
                }

                Group {
                    if rollsDigits {
                        RollingNumberText(value, resetToken: subjectID)
                    } else {
                        Text(value)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                .font(.brutalistBody)
                .foregroundStyle(valueColor)
                .frame(maxWidth: growsToFill ? .infinity : nil, alignment: .leading)
            }
            .frame(maxWidth: growsToFill ? .infinity : nil, alignment: .leading)
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.sm)
            .frame(minHeight: 54)
            .background(isActive ? Theme.backgroundSubtle : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
        .animation(.easeOut(duration: Theme.animationFast), value: isActive)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(flag != nil ? L10n.readoutValueWithStatus(value, L10n.readoutMileageUpdateDue) : value)
        .accessibilityAddTraits(isExpanded == true ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview {
    ZStack(alignment: .top) {
        AtmosphericBackground()

        VehicleSummaryBand(
            vehicle: Vehicle.sampleVehicle,
            onMileageTap: {},
            onEdit: {},
            onDocumentsTap: {}
        )
    }
    .preferredColorScheme(.dark)
}
