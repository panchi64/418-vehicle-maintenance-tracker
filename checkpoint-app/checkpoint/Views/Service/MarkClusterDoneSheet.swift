//
//  MarkClusterDoneSheet.swift
//  checkpoint
//
//  Sheet for marking all services in a cluster as done at once
//

import SwiftUI
import SwiftData

struct MarkClusterDoneSheet: View {
    let cluster: ServiceCluster
    var onSaved: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var services: [Service]

    @State private var performedDate: Date = Date()
    @State private var mileage: Int? = nil
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Services being logged
                        servicesSection

                        // Shared details
                        detailsSection

                        // Optional notes
                        notesSection

                        Spacer(minLength: Spacing.xl)
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.vertical, Spacing.lg)
                }
            }
            .navigationTitle("Mark All Done")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .toolbarButtonStyle()
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveAll() }
                        .toolbarButtonStyle(isDisabled: mileage == nil)
                        .disabled(mileage == nil)
                }
            }
            .onAppear {
                mileage = cluster.vehicle.effectiveMileage
            }
        }
    }

    // MARK: - Services Section

    private var servicesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            InstrumentSectionHeader(title: "Services (\(cluster.serviceCount))")

            VStack(spacing: 0) {
                ForEach(Array(cluster.services.enumerated()), id: \.element.id) { index, service in
                    HStack(spacing: Spacing.sm) {
                        Rectangle()
                            .fill(Theme.statusGood)
                            .frame(width: 4, height: 4)

                        Text(service.name.uppercased())
                            .font(.brutalistBody)
                            .foregroundStyle(Theme.textPrimary)

                        Spacer()
                    }
                    .padding(Spacing.md)

                    if index < cluster.services.count - 1 {
                        Rectangle()
                            .fill(Theme.gridLine)
                            .frame(height: 1)
                    }
                }
            }
            .background(Theme.surfaceInstrument)
            .overlay(
                Rectangle()
                    .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
            )
        }
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            InstrumentSectionHeader(title: "Details")

            InstrumentDatePicker(
                label: "Date Performed",
                date: $performedDate
            )

            InstrumentNumberField(
                label: "Mileage",
                value: $mileage,
                placeholder: "Required",
                suffix: DistanceSettings.shared.unit.abbreviation
            )
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            InstrumentSectionHeader(title: "Notes (Optional)")

            InstrumentTextEditor(
                label: "Shared Notes",
                text: $notes,
                placeholder: "Add notes for all services...",
                minHeight: 80
            )
        }
    }

    // MARK: - Save Action

    private func saveAll() {
        let mileageInt = mileage ?? cluster.vehicle.effectiveMileage

        for service in cluster.services {
            // Create service log
            let log = ServiceLog(
                service: service,
                vehicle: cluster.vehicle,
                performedDate: performedDate,
                mileageAtService: mileageInt,
                cost: nil,  // User can edit individual logs later
                notes: notes.isEmpty ? nil : notes
            )
            modelContext.insert(log)

            // Update service tracking and recalculate due dates
            service.recalculateDueDates(performedDate: performedDate, mileage: mileageInt)
        }

        // Update vehicle mileage if service mileage is higher
        if mileageInt > cluster.vehicle.currentMileage {
            cluster.vehicle.currentMileage = mileageInt
            cluster.vehicle.mileageUpdatedAt = performedDate
        }

        // Create mileage snapshot
        let shouldCreateSnapshot = !MileageSnapshot.hasSnapshotToday(
            snapshots: cluster.vehicle.mileageSnapshots ?? []
        )

        if shouldCreateSnapshot {
            let snapshot = MileageSnapshot(
                vehicle: cluster.vehicle,
                mileage: mileageInt,
                recordedAt: performedDate,
                source: .serviceCompletion
            )
            modelContext.insert(snapshot)
        }

        // Update app icon and widget
        AppIconService.shared.updateIcon(for: cluster.vehicle, services: services)
        WidgetDataService.shared.updateWidget(for: cluster.vehicle)

        onSaved?()
        dismiss()
    }
}

#Preview {
    let vehicle = Vehicle.sampleVehicle
    let services = Service.sampleServices(for: vehicle)
    let cluster = ServiceCluster(
        services: Array(services.prefix(3)),
        anchorService: services[0],
        vehicle: vehicle,
        mileageWindow: 1000,
        daysWindow: 30
    )

    return MarkClusterDoneSheet(cluster: cluster)
        .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self, MileageSnapshot.self], inMemory: true)
        .preferredColorScheme(.dark)
}
