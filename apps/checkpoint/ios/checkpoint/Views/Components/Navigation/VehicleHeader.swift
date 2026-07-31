//
//  VehicleHeader.swift
//  checkpoint
//
//  Persistent chrome, present on every tab.
//
//  STRUCTURE: full-width bands, ending in a two-cell data band.
//
//    [SELECT]                                    ⚙     chrome
//    DAILY DRIVER                                      identity (the one primary)
//    Toyota RAV4 · 2026                                identity support
//    ──────────────────────┬──────────────────────
//    ODOMETER            › │ SPECS             ⌄      data cells, side by side
//    33,417 mi             │ IWK-482 · 0W-20
//
//  The version before this was two independent vertical stacks placed beside
//  each other — [SELECT]/name/spec-line on the left, gear/[UPDATE]/mileage on
//  the right — with no shared baseline or grid between them. Nothing lined up
//  with anything, so the name read as dropped into the corner of a header rather
//  than belonging to it. Two stacks is not a layout; it is two layouts.
//
//  Bands fix three things:
//
//    1. Every element sits on one vertical rhythm and one left edge, so
//       alignment is structural rather than coincidental.
//    2. The name gets the FULL width. It previously competed with the odometer
//       for horizontal space, which is why it clipped at 375pt.
//    3. The odometer gains a label, so its meaning is stated rather than
//       inferred from a bare number under a gear icon.
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
        VStack(alignment: .leading, spacing: 0) {
            chromeBand
            identityBand
            dataBand
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Theme.gridLine)
                .frame(height: Theme.borderWidth)
        }
    }

    // MARK: - Band 1: chrome

    /// Two small elements on one baseline. The 44pt targets overflow this 28pt
    /// band via negative padding, so the band's height is set by what you can
    /// see rather than by the hit area.
    private var chromeBand: some View {
        HStack(spacing: 0) {
            Button(action: onTap) {
                Text("[SELECT]")
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.accent)
                    .tracking(1)
                    .frame(minHeight: TouchTarget.minimum, alignment: .center)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.headerSelectVehicleAccessibility)
            .accessibilityHint(L10n.headerSelectVehicleHint)

            Spacer(minLength: Spacing.sm)

            if let error = syncService.currentError {
                Button {
                    onSettingsTap?()
                } label: {
                    Image(systemName: error.systemImage)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(error.iconColor)
                        .frame(width: TouchTarget.minimum, height: TouchTarget.minimum)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Sync error")
                .accessibilityHint("Double tap to open settings")
            }

            if let onSettingsTap {
                Button(action: onSettingsTap) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Theme.textTertiary)
                        .frame(width: TouchTarget.minimum, height: TouchTarget.minimum)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Settings")
                // Pulls the icon's trailing edge out to the screen inset, so the
                // glyph aligns with the text below it rather than sitting 12pt
                // inboard of it.
                .padding(.trailing, -(TouchTarget.minimum - 18) / 2)
            }
        }
        .frame(height: 28)
        .padding(.horizontal, Spacing.screenHorizontal)
    }

    // MARK: - Band 2: identity

    /// The make/model/year line only earns its place when the user gave the
    /// vehicle a nickname. Without one, `displayName` is already
    /// "2026 Toyota RAV4", so this line repeated every word above it.
    private var specLine: String? {
        guard let vehicle, !vehicle.name.isEmpty else { return nil }
        return L10n.headerMakeModelYear(vehicle.make, vehicle.model, String(vehicle.year))
    }

    /// Full width, so it never competes for space.
    private var identityBand: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // brutalistTitle (32), not brutalistHero (56) with
                // minimumScaleFactor(0.5): a long nickname used to shrink to
                // ~28pt, so the header's weight swung with the name's length,
                // and at full size it out-shouted every screen's actual hero
                // content. Persistent chrome identifies; it should not dominate.
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
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.bottom, Spacing.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(vehicle?.displayName ?? L10n.headerSelectVehicleAccessibility)
        .accessibilityHint(L10n.headerSelectVehicleHint)
    }

    // MARK: - Band 3: odometer and specs

    /// What the collapsed strip shows: the plate, needed constantly (parking,
    /// forms, the marbete line), and one parts-counter value.
    ///
    /// Held to two values on purpose. A third truncated mid-word at 393pt, and a
    /// line ending in "0W-20 Synth…" is not glanceable — it only signals that
    /// something was cut. VIN is deliberately absent: 17 characters would consume
    /// the row, and it is needed rarely but *exactly*, which is what the expanded
    /// panel is for.
    private func specsSummary(for vehicle: Vehicle) -> String? {
        let values = [vehicle.licensePlate, vehicle.oilType ?? vehicle.tireSize]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        guard !values.isEmpty else { return nil }
        return values.joined(separator: "  \u{00B7}  ")
    }

    @ViewBuilder
    private var dataBand: some View {
        if let vehicle {
            HStack(spacing: 0) {
                // The trailing glyphs differ on purpose: `chevron.right` opens a
                // sheet, `chevron.down` expands in place. One glyph for both
                // would promise the same behavior from two controls that behave
                // differently.
                HeaderCell(
                    label: L10n.headerOdometer,
                    value: Formatters.mileage(vehicle.currentMileage),
                    valueColor: Theme.accent,
                    glyph: "chevron.right",
                    isFlagged: vehicle.shouldDisplayMileageUpdatePrompt(
                        isInteractive: onMileageTap != nil
                    ),
                    action: onMileageTap
                )

                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(width: 1)
                    .accessibilityHidden(true)

                if let isSpecsExpanded {
                    HeaderCell(
                        label: L10n.headerSpecs,
                        // Not uppercased. These are values, not labels — and the
                        // panel below renders the same oil spec in sentence case,
                        // so uppercasing here would show one datum two ways.
                        value: specsSummary(for: vehicle) ?? "—",
                        valueColor: Theme.textSecondary,
                        glyph: "chevron.down",
                        isGlyphRotated: isSpecsExpanded.wrappedValue,
                        isActive: isSpecsExpanded.wrappedValue,
                        isExpanded: isSpecsExpanded.wrappedValue,
                        growsToFill: true,
                        action: {
                            withAnimation(.easeOut(duration: Theme.animationMedium)) {
                                isSpecsExpanded.wrappedValue.toggle()
                            }
                        }
                    )
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: 1)
            }
        }
    }
}

// MARK: - Header cell

/// One cell of the header's data band. Both cells share this so they cannot
/// drift apart — the odometer and the specs strip are the same kind of thing and
/// should stay the same shape.
private struct HeaderCell: View {
    let label: String
    let value: String
    var valueColor: Color = Theme.textSecondary
    let glyph: String
    var isGlyphRotated: Bool = false
    /// Small status square beside the label, e.g. a stale odometer reading.
    var isFlagged: Bool = false
    var isActive: Bool = false
    var isExpanded: Bool?
    /// Set on the cell that should absorb the leftover width.
    var growsToFill: Bool = false
    var action: (() -> Void)?

    var body: some View {
        Button {
            action?()
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.xs) {
                    if isFlagged {
                        Rectangle()
                            .fill(Theme.statusDueSoon)
                            .frame(width: 6, height: 6)
                            .accessibilityHidden(true)
                    }

                    Text(label.uppercased())
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(1.5)
                        .lineLimit(1)
                        .frame(maxWidth: growsToFill ? .infinity : nil, alignment: .leading)

                    Image(systemName: glyph)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                        .rotationEffect(.degrees(isGlyphRotated ? 180 : 0))
                }

                Text(value)
                    .font(.brutalistBody)
                    .foregroundStyle(valueColor)
                    .lineLimit(1)
                    .truncationMode(.tail)
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
        .accessibilityValue(value)
        .accessibilityAddTraits(isExpanded == true ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview {
    ZStack {
        AtmosphericBackground()

        VStack {
            VehicleHeader(
                vehicle: Vehicle.sampleVehicle,
                onTap: {},
                onMileageTap: {},
                onSettingsTap: {},
                isSpecsExpanded: .constant(false)
            )
            .padding(.top, Spacing.sm)

            Spacer()
        }
    }
    .preferredColorScheme(.dark)
}
