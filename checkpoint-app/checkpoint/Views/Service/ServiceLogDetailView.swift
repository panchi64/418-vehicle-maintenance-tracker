//
//  ServiceLogDetailView.swift
//  checkpoint
//
//  Detail view for a single service log showing all recorded information
//

import SwiftUI
import SwiftData

struct ServiceLogDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let log: ServiceLog

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Service name header
                serviceHeader

                // Details section
                detailsSection

                // Notes section
                if let notes = log.notes, !notes.isEmpty {
                    notesSection(notes: notes)
                }

                // Attachments
                if !(log.attachments ?? []).isEmpty {
                    AttachmentSection(attachments: log.attachments ?? [])
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.lg)
        }
        .trackScreen(.serviceLogDetail)
        .background(Theme.backgroundPrimary)
        .navigationTitle("Service Log")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }

    // MARK: - Service Header

    private var serviceHeader: some View {
        VStack(spacing: Spacing.sm) {
            // Category icon
            if let category = log.costCategory {
                Image(systemName: category.icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(category.color)
            } else {
                Image(systemName: "wrench.and.screwdriver")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(Theme.accent)
            }

            Text(log.service?.name ?? "Service")
                .font(.brutalistTitle)
                .foregroundStyle(Theme.textPrimary)

            Text(Formatters.mediumDate.string(from: log.performedDate))
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xl)
        .glassCardStyle(intensity: .subtle, padding: 0)
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            InstrumentSectionHeader(title: "Details")

            VStack(spacing: 0) {
                if let cost = log.formattedCost {
                    detailRow(title: "Cost", value: cost)
                    Divider()
                }

                if let category = log.costCategory {
                    detailRow(title: "Category", value: category.displayName)
                    Divider()
                }

                detailRow(title: "Mileage", value: Formatters.mileage(log.mileageAtService))
            }
            .background(Theme.surfaceInstrument)
            .clipShape(Rectangle())
            .overlay(
                Rectangle()
                    .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
            )
        }
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title.uppercased())
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1)
            Spacer()
            Text(value)
                .font(.brutalistBody)
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(Spacing.md)
    }

    // MARK: - Notes Section

    private func notesSection(notes: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            InstrumentSectionHeader(title: "Notes")

            Text(notes)
                .font(.brutalistBody)
                .foregroundStyle(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.md)
                .background(Theme.surfaceInstrument)
                .clipShape(Rectangle())
                .overlay(
                    Rectangle()
                        .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
                )
        }
    }
}

#Preview {
    let vehicle = Vehicle(
        name: "Test Car",
        make: "Toyota",
        model: "Camry",
        year: 2022,
        currentMileage: 32500
    )

    let service = Service(name: "Oil Change", dueDate: nil)

    let log = ServiceLog(
        service: service,
        vehicle: vehicle,
        performedDate: Date.now,
        mileageAtService: 32000,
        cost: 45.99,
        costCategory: .maintenance,
        notes: "Synthetic 0W-20 oil change at local shop. Filter replaced."
    )

    NavigationStack {
        ServiceLogDetailView(log: log)
    }
    .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self, ServiceAttachment.self], inMemory: true)
    .preferredColorScheme(.dark)
}
