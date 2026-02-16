//
//  QuickSpecsCard.swift
//  checkpoint
//
//  Collapsible card showing VIN, tire size, oil type
//  Collapsed by default, tap to expand
//

import SwiftUI

struct QuickSpecsCard: View {
    let vehicle: Vehicle
    let onEdit: () -> Void

    @State private var isExpanded = false
    @State private var showFullNotes = false

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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (always visible, tappable)
            Button {
                withAnimation(.easeOut(duration: Theme.animationMedium)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("SPECS")
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(2)

                    Spacer()

                    // Quick preview when collapsed (if has data)
                    if !isExpanded && hasAnySpecs {
                        HStack(spacing: Spacing.sm) {
                            if let licensePlate = vehicle.licensePlate {
                                Text(licensePlate)
                                    .font(.brutalistSecondary)
                                    .foregroundStyle(Theme.textSecondary)
                            }

                            if let tireSize = vehicle.tireSize {
                                if vehicle.licensePlate != nil {
                                    Text("•")
                                        .font(.brutalistSecondary)
                                        .foregroundStyle(Theme.gridLine)
                                }

                                Text(tireSize)
                                    .font(.brutalistSecondary)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                    }

                    // Chevron indicator with rotation
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(Spacing.md)
                .background(Theme.surfaceInstrument)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Vehicle specs")
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
            .accessibilityHint(isExpanded ? "Double tap to collapse" : "Double tap to expand")

            // Expandable content
            if isExpanded {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Theme.gridLine)
                        .frame(height: 1)

                    // Specs grid - values first, labels below
                    VStack(spacing: Spacing.lg) {
                        // License Plate and VIN
                        if vehicle.licensePlate != nil || vehicle.vin != nil {
                            HStack(alignment: .top, spacing: Spacing.lg) {
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
                            HStack(alignment: .top, spacing: Spacing.lg) {
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
                                    .accessibilityLabel("Vehicle notes")
                                    .accessibilityHint("Double tap to read full notes")
                                } else {
                                    Text(truncatedNotes ?? "")
                                        .font(.brutalistBody)
                                        .foregroundStyle(Theme.textPrimary)
                                        .lineLimit(3)
                                }
                            }
                        }

                        // Empty state
                        if !hasAnySpecs {
                            Text("No specifications added")
                                .font(.brutalistSecondary)
                                .foregroundStyle(Theme.textTertiary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(Spacing.md)
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
                                .font(.system(size: 11, weight: .medium))
                            Text(hasAnySpecs ? "EDIT" : "ADD SPECS")
                                .font(.brutalistLabel)
                                .tracking(1)
                        }
                        .foregroundStyle(Theme.accent)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .accessibilityLabel(hasAnySpecs ? "Edit vehicle specs" : "Add vehicle specs")
                }
                .background(Theme.surfaceInstrument)
                .transition(.opacity)
            }
        }
        .overlay(
            Rectangle()
                .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
        )
        .clipped()
        .sheet(isPresented: $showFullNotes) {
            FullNotesView(notes: vehicle.notes ?? "")
        }
    }

    /// Spec block with large value and small label below
    private func specBlock(value: String, label: String, isMonospace: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            // Value - prominent
            Text(value)
                .font(isMonospace ? .brutalistBody : .brutalistHeading)
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            // Label - secondary
            Text(label)
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1)
        }
    }

    /// Marbete block with status-colored expiration display
    private func marbeteBlock(expiration: String, status: ServiceStatus) -> some View {
        HStack(spacing: Spacing.sm) {
            // Status indicator
            Rectangle()
                .fill(status.color)
                .frame(width: 8, height: 8)

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
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Close")
                }
            }
            .toolbarBackground(Theme.surfaceInstrument, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
                    )
                ) {
                    print("Edit tapped")
                }

                // With partial specs
                QuickSpecsCard(
                    vehicle: Vehicle(
                        name: "Weekend Car",
                        make: "Mazda",
                        model: "MX-5",
                        year: 2020,
                        currentMileage: 18200,
                        vin: "JM1NDAL79L0123456"
                    )
                ) {
                    print("Edit tapped")
                }

                // With no specs
                QuickSpecsCard(
                    vehicle: Vehicle(
                        name: "New Car",
                        make: "Honda",
                        model: "Civic",
                        year: 2024,
                        currentMileage: 1500
                    )
                ) {
                    print("Edit tapped")
                }
            }
            .padding(Spacing.screenHorizontal)
        }
    }
    .preferredColorScheme(.dark)
}
