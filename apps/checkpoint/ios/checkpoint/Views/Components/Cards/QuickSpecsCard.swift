//
//  QuickSpecsCard.swift
//  checkpoint
//
//  Vehicle reference detail — plate, VIN, tires, oil, marbete, notes, documents.
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

    @State private var showFullNotes = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var hasAnySpecs: Bool {
        vehicle.vin != nil || vehicle.licensePlate != nil || vehicle.tireSize != nil || vehicle.oilType != nil || !(vehicle.notes ?? "").isEmpty || vehicle.hasMarbeteExpiration
    }

    private var hasNotes: Bool {
        !(vehicle.notes ?? "").isEmpty
    }

    /// Truncated notes for preview display (first ~50 chars)
    private var truncatedNotes: String? {
        guard let notes = vehicle.notes, !notes.isEmpty else { return nil }
        if notes.count <= 50 {
            return notes
        }
        return String(notes.prefix(50)) + "..."
    }

    /// Whether notes are long enough to be truncated
    private var isNotesTruncated: Bool {
        guard let notes = vehicle.notes else { return false }
        return notes.count > 50
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
                                        label: "PLATE",
                                        isMonospace: false
                                    )
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }

                                if let vin = vehicle.vin {
                                    specBlock(
                                        value: vin,
                                        label: "VIN",
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
                                        label: "TIRES",
                                        isMonospace: false
                                    )
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }

                                if let oilType = vehicle.oilType {
                                    specBlock(
                                        value: oilType,
                                        label: "OIL",
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

                        // Notes section
                        if hasNotes {
                            VStack(alignment: .leading, spacing: 0) {
                                // Separator
                                Rectangle()
                                    .fill(Theme.gridLine)
                                    .frame(height: 2)
                                    .padding(.bottom, Spacing.sm)

                                // Notes label
                                Text("NOTES")
                                    .font(.brutalistLabel)
                                    .foregroundStyle(Theme.textTertiary)
                                    .tracking(1)
                                    .padding(.bottom, 4)

                                // Notes content - tappable when truncated
                                if isNotesTruncated {
                                    Button {
                                        showFullNotes = true
                                    } label: {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(truncatedNotes ?? "")
                                                .font(.brutalistBody)
                                                .foregroundStyle(Theme.textPrimary)
                                                .lineLimit(3)
                                                .multilineTextAlignment(.leading)

                                            Text("TAP TO READ MORE")
                                                .font(.brutalistLabel)
                                                .foregroundStyle(Theme.accent)
                                                .tracking(1)
                                        }
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(L10n.readoutVehicleNotes)
                                    .accessibilityValue(truncatedNotes ?? "")
                                    .accessibilityHint(L10n.readoutReadFullNotesHint)
                                } else {
                                    Text(truncatedNotes ?? "")
                                        .font(.brutalistBody)
                                        .foregroundStyle(Theme.textPrimary)
                                        .lineLimit(3)
                                }
                            }
                        }

                        // Documents row — always shown so users can add docs
                        // even on a brand-new vehicle with no other specs.
                        documentsRow

                        // Empty state
                        if !hasAnySpecs {
                            Text("No specifications added")
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
                            Text(hasAnySpecs ? "EDIT" : "ADD SPECS")
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
        .sheet(isPresented: $showFullNotes) {
            FullNotesView(notes: vehicle.notes ?? "")
        }
    }

    /// Documents library entry point. Always visible in the expanded card so
    /// even users with no other specs can start saving registration, insurance,
    /// and other vehicle files.
    private var documentsRow: some View {
        let count = vehicle.documents?.count ?? 0
        return Button {
            onDocumentsTap()
        } label: {
            HStack(alignment: .center, spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(count == 0 ? "—" : "\(count)")
                        .font(.brutalistHeading)
                        .foregroundStyle(Theme.textPrimary)
                    Text(L10n.documentsRowQuickSpecs.uppercased())
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(2)
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
        .accessibilityLabel(L10n.documentsTitle)
        .accessibilityValue(count == 0 ? L10n.readoutDocumentsNone : L10n.readoutDocumentsSaved(count))
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
            copySpec(value: expiration, fieldLabel: "Marbete")
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
                    Text("MARBETE")
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

// MARK: - Full Notes View

struct FullNotesView: View {
    let notes: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(notes)
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.md)
            }
            .background(Theme.backgroundPrimary)
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textSecondary)
                            .minimumTouchTarget()
                    }
                    .accessibilityLabel(L10n.readoutClose)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
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
                    onDocumentsTap: { print("Documents tapped") }
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
                    onDocumentsTap: { print("Documents tapped") }
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
                    onDocumentsTap: { print("Documents tapped") }
                )
            }
            .padding(Spacing.screenHorizontal)
        }
    }
    .preferredColorScheme(.dark)
}
