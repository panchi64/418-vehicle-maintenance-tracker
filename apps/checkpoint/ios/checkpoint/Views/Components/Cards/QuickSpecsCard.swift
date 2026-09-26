//
//  QuickSpecsCard.swift
//  checkpoint
//
//  Vehicle reference detail — plate, VIN, tires, oil, marbete, and the doors
//  to its notes and documents.
//
//  Presented as a panel expanding from `VehicleSummaryBand`'s SPECS cell at the
//  top of Home, collapsed by default. This is *identity* data, not maintenance
//  state: tire size and oil type never need doing; they are lookup values you
//  want at a parts counter. Home's job is answering "what needs doing", so the
//  panel stays one tap away rather than occupying Home's flow.
//
//  This type owns only the expanded detail — it has no header row of its own,
//  and no border, so it reads as a continuation of the band rather than a
//  second competing card.
//

import SwiftUI

struct QuickSpecsCard: View {
    let vehicle: Vehicle
    let onEdit: () -> Void
    let onDocumentsTap: () -> Void
    let onNotesTap: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var hasAnySpecs: Bool {
        vehicle.vin != nil || vehicle.licensePlate != nil || vehicle.tireSize != nil || vehicle.oilType != nil || vehicle.hasMarbeteExpiration
    }

    // No header row of its own: the disclosure trigger lives in VehicleSummaryBand.
    var body: some View {
        VStack(spacing: 0) {
                    // Specs grid - values first, labels below
                    VStack(spacing: Spacing.lg) {
                        // License Plate and VIN
                        if vehicle.licensePlate != nil || vehicle.vin != nil {
                            AdaptiveStack(verticalAlignment: .top, spacing: Spacing.lg) {
                                if let licensePlate = vehicle.licensePlate {
                                    specBlock(
                                        value: licensePlate,
                                        label: L10n.specsPlate,
                                        isMonospace: false
                                    )
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }

                                if let vin = vehicle.vin {
                                    specBlock(
                                        value: vin,
                                        label: L10n.specsVIN,
                                        isMonospace: true
                                    )
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }

                        // Tire and Oil side by side
                        if vehicle.tireSize != nil || vehicle.oilType != nil {
                            AdaptiveStack(verticalAlignment: .top, spacing: Spacing.lg) {
                                if let tireSize = vehicle.tireSize {
                                    specBlock(
                                        value: tireSize,
                                        label: L10n.specsTires,
                                        isMonospace: false
                                    )
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }

                                if let oilType = vehicle.oilType {
                                    specBlock(
                                        value: oilType,
                                        label: L10n.specsOil,
                                        isMonospace: false
                                    )
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }

                        // Marbete expiration (if set)
                        if vehicle.hasMarbeteExpiration, let formatted = vehicle.marbeteExpirationFormatted {
                            marbeteBlock(expiration: formatted, status: vehicle.marbeteStatus)
                        }

                        // Notes and Documents rows — always shown so users can
                        // start either library even on a brand-new vehicle
                        // with no other specs.
                        notesRow
                        documentsRow

                        // Empty state
                        if !hasAnySpecs {
                            Text(L10n.specsEmpty)
                                .font(.brutalistSecondary)
                                .foregroundStyle(Theme.textTertiary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    // Horizontal inset matches VehicleSummaryBand and the tabs
                    // (Spacing.screenHorizontal), so the panel's values line up
                    // with the cells above them rather than sitting 4pt
                    // inboard.
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.vertical, Spacing.md)
                    .padding(.bottom, Spacing.xs)

                    // Divider before edit button
                    Rectangle()
                        .fill(Theme.gridLine)
                        .frame(height: 1)

                    // Edit button - more subtle
                    Button {
                        onEdit()
                    } label: {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "pencil")
                                .font(.caption2.weight(.medium))
                            Text(hasAnySpecs ? L10n.specsEdit : L10n.specsAdd)
                                .font(.brutalistLabel)
                                .tracking(1)
                        }
                        .foregroundStyle(Theme.accent)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .accessibilityLabel(hasAnySpecs ? L10n.readoutEditVehicleSpecs : L10n.readoutAddVehicleSpecs)
        }
        .background(Theme.surfaceInstrument)
        // No border: this reads as a continuation of the header above it, not a
        // second card. Fade-only transition per AESTHETIC.md (Motion).
        .transition(.opacity)
    }

    /// Documents library entry point. Always visible in the expanded card so
    /// even users with no other specs can start saving registration, insurance,
    /// and other vehicle files.
    private var documentsRow: some View {
        let count = vehicle.documents?.count ?? 0
        return libraryRow(
            count: count,
            label: L10n.documentsRowQuickSpecs,
            preview: nil,
            action: onDocumentsTap
        )
        .accessibilityLabel(L10n.documentsTitle)
        .accessibilityValue(count == 0 ? L10n.readoutDocumentsNone : L10n.readoutDocumentsSaved(count))
    }

    /// The vehicle's notes. Replaced the single notes preview: a vehicle has
    /// a list of notes now, so this is a door to them, shaped like Documents,
    /// with the first pinned note's title so the one kept for reference is
    /// still glanceable here.
    private var notesRow: some View {
        let notes = vehicle.sortedNotes
        let preview = notes.first { $0.isPinned }.map(\.displayTitle)
        return libraryRow(
            count: notes.count,
            label: L10n.notesRowQuickSpecs,
            preview: preview,
            action: onNotesTap
        )
        .accessibilityLabel(L10n.notesTitle)
        .accessibilityValue(notes.isEmpty ? L10n.readoutNotesNone : L10n.readoutNotesSaved(notes.count))
    }

    /// A count, its label, an optional one-line preview, and a chevron: the
    /// door to one of the vehicle's libraries.
    private func libraryRow(count: Int, label: String, preview: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: count == 0 ? "—" : "\(count)")
                        .font(.brutalistHeading)
                        .foregroundStyle(Theme.textPrimary)
                    Text(label.uppercased())
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(2)
                    if let preview, !preview.isEmpty {
                        Text(preview)
                            .font(.brutalistSecondary)
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: TouchTarget.minimum)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Copy a spec value to the pasteboard, with haptic + toast feedback naming the field.
    private func copySpec(value: String, fieldLabel: String) {
        UIPasteboard.general.string = value
        HapticService.shared.success()
        ToastService.shared.show(
            L10n.toastCopied(fieldLabel),
            icon: "doc.on.doc.fill",
            style: .success
        )
    }

    /// Spec block with large value and small label below. Tap to copy the raw value.
    private func specBlock(value: String, label: String, isMonospace: Bool) -> some View {
        Button {
            copySpec(value: value, fieldLabel: label)
        } label: {
            HStack(alignment: .top, spacing: Spacing.xs) {
                VStack(alignment: .leading, spacing: 2) {
                    // Value - prominent
                    Text(value)
                        .font(isMonospace ? .brutalistBody : .brutalistHeading)
                        .foregroundStyle(Theme.textPrimary)
                        // One line at standard sizes; at accessibility sizes a
                        // 17-character VIN can't fit at any scale, so it wraps.
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                        .minimumScaleFactor(0.8)

                    // Label - secondary
                    Text(label)
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Copy affordance
                Image(systemName: "doc.on.doc")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Theme.textTertiary)
                    .padding(.top, 3)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: TouchTarget.minimum, alignment: .top)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityValue(value)
        .accessibilityHint(L10n.readoutCopyHint)
    }

    /// Marbete block with status-colored expiration display. Tap to copy the expiration string.
    private func marbeteBlock(expiration: String, status: ServiceStatus) -> some View {
        Button {
            copySpec(value: expiration, fieldLabel: L10n.vehicleMarbete)
        } label: {
            HStack(spacing: Spacing.sm) {
                // Status indicator
                Rectangle()
                    .fill(status.color)
                    .frame(width: 8, height: 8)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    // Expiration date in status color
                    Text(expiration)
                        .font(.brutalistHeading)
                        .foregroundStyle(status.color)

                    // Label
                    Text(L10n.specsMarbete)
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(1)
                }

                // Copy affordance
                Image(systemName: "doc.on.doc")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Theme.textTertiary)
                    .accessibilityHidden(true)

                Spacer()

                // Status label
                if status != .neutral {
                    Text(status.label)
                        .font(.brutalistLabel)
                        .foregroundStyle(status.color)
                        .tracking(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.vehicleMarbete)
        .accessibilityValue(status == .neutral
            ? expiration
            : L10n.readoutValueWithStatus(expiration, L10n.readoutStatus(status)))
        .accessibilityHint(L10n.readoutCopyHint)
    }
}

#Preview {
    ZStack {
        AtmosphericBackground()

        ScrollView {
            VStack(spacing: Spacing.lg) {
                // With all specs + long notes
                QuickSpecsCard(
                    vehicle: Vehicle(
                        name: "Daily Driver",
                        make: "Toyota",
                        model: "Camry",
                        year: 2022,
                        currentMileage: 32500,
                        vin: "1HGBH41JXMN109186",
                        tireSize: "225/45R17",
                        oilType: "0W-20 Synthetic",
                        notes: "This car has a slight vibration at highway speeds above 70mph. The dealer mentioned it could be related to the alignment or tire balance. Need to get it checked at the next service appointment. Also, the rear passenger window makes a clicking noise when going down."
                    ),
                    onEdit: { print("Edit tapped") },
                    onDocumentsTap: { print("Documents tapped") },
                    onNotesTap: { print("Notes tapped") }
                )

                // With partial specs
                QuickSpecsCard(
                    vehicle: Vehicle(
                        name: "Weekend Car",
                        make: "Mazda",
                        model: "MX-5",
                        year: 2020,
                        currentMileage: 18200,
                        vin: "JM1NDAL79L0123456"
                    ),
                    onEdit: { print("Edit tapped") },
                    onDocumentsTap: { print("Documents tapped") },
                    onNotesTap: { print("Notes tapped") }
                )

                // With no specs
                QuickSpecsCard(
                    vehicle: Vehicle(
                        name: "New Car",
                        make: "Honda",
                        model: "Civic",
                        year: 2024,
                        currentMileage: 1500
                    ),
                    onEdit: { print("Edit tapped") },
                    onDocumentsTap: { print("Documents tapped") },
                    onNotesTap: { print("Notes tapped") }
                )
            }
            .padding(Spacing.screenHorizontal)
        }
    }
    .preferredColorScheme(.dark)
}
