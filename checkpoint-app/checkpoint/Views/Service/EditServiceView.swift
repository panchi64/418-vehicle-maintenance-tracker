//
//  EditServiceView.swift
//  checkpoint
//
//  Form for editing an existing service's details and schedule
//  with instrument cluster aesthetic
//

import SwiftUI
import SwiftData

struct EditServiceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var services: [Service]

    @Bindable var service: Service
    let vehicle: Vehicle

    // Service details
    @State private var serviceName: String = ""
    @State private var dueDate: Date = Date()
    @State private var hasDueDate: Bool = false
    @State private var dueMileage: Int? = nil
    @State private var intervalMonths: Int? = nil
    @State private var intervalMiles: Int? = nil

    @State private var showDeleteConfirmation = false

    var isFormValid: Bool {
        !serviceName.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphericBackground()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Service Details Section
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            InstrumentSectionHeader(title: "Service Details")

                            InstrumentTextField(
                                label: "Service Name",
                                text: $serviceName,
                                placeholder: "Oil Change, Tire Rotation...",
                                isRequired: true
                            )
                        }

                        // Due Date Section
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            InstrumentSectionHeader(title: "Due Date")

                            VStack(spacing: Spacing.md) {
                                // Due date toggle
                                HStack {
                                    Text("HAS DUE DATE")
                                        .font(.brutalistLabel)
                                        .foregroundStyle(Theme.textTertiary)
                                        .tracking(1)

                                    Spacer()

                                    Toggle("", isOn: $hasDueDate)
                                        .labelsHidden()
                                        .tint(Theme.accent)
                                }
                                .padding(Spacing.md)
                                .background(Theme.surfaceInstrument)
                                .overlay(
                                    Rectangle()
                                        .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
                                )

                                if hasDueDate {
                                    InstrumentDatePicker(
                                        label: "Due Date",
                                        date: $dueDate
                                    )
                                }

                                InstrumentNumberField(
                                    label: "Due Mileage",
                                    value: $dueMileage,
                                    placeholder: "Optional",
                                    suffix: DistanceSettings.shared.unit.abbreviation
                                )
                            }
                        }

                        // Repeat Interval Section
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            InstrumentSectionHeader(title: "Repeat Interval")

                            VStack(spacing: Spacing.md) {
                                InstrumentNumberField(
                                    label: "Every",
                                    value: $intervalMonths,
                                    placeholder: "6",
                                    suffix: "months"
                                )

                                InstrumentNumberField(
                                    label: "Or Every",
                                    value: $intervalMiles,
                                    placeholder: "5000",
                                    suffix: DistanceSettings.shared.unit.abbreviation
                                )
                            }
                        }

                        // Delete Button
                        Button {
                            showDeleteConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Service")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.statusOverdue)
                            .frame(maxWidth: .infinity)
                            .frame(height: Theme.buttonHeight)
                            .background(Theme.statusOverdue.opacity(0.1))
                            .overlay(
                                Rectangle()
                                    .strokeBorder(Theme.statusOverdue.opacity(0.3), lineWidth: Theme.borderWidth)
                            )
                        }
                        .padding(.top, Spacing.md)
                    }
                    .padding(Spacing.screenHorizontal)
                    .padding(.bottom, Spacing.xxl)
                }
            }
            .navigationTitle("Edit Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.surfaceInstrument, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .toolbarButtonStyle()
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                        .toolbarButtonStyle(isDisabled: !isFormValid)
                        .disabled(!isFormValid)
                }
            }
            .confirmationDialog(
                "Delete Service?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) { deleteService() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will also delete all service history for this service. This action cannot be undone.")
            }
            .trackScreen(.editService)
            .onAppear {
                loadServiceData()
            }
        }
    }

    // MARK: - Data Loading

    private func loadServiceData() {
        serviceName = service.name
        hasDueDate = service.dueDate != nil
        dueDate = service.dueDate ?? Date()
        dueMileage = service.dueMileage
        intervalMonths = service.intervalMonths
        intervalMiles = service.intervalMiles
    }

    // MARK: - Save Logic

    private func saveChanges() {
        HapticService.shared.success()
        AnalyticsService.shared.capture(.serviceEdited)
        service.name = serviceName
        service.dueDate = hasDueDate ? dueDate : nil
        service.dueMileage = dueMileage
        service.intervalMonths = intervalMonths
        service.intervalMiles = intervalMiles

        updateAppIcon()
        updateWidgetData()
        dismiss()
    }

    // MARK: - Delete Logic

    private func deleteService() {
        AnalyticsService.shared.capture(.serviceDeleted)
        modelContext.delete(service)
        updateAppIcon()
        updateWidgetData()
        dismiss()
    }

    // MARK: - App Icon

    private func updateAppIcon() {
        AppIconService.shared.updateIcon(for: vehicle, services: services)
    }

    // MARK: - Widget Data

    private func updateWidgetData() {
        WidgetDataService.shared.updateWidget(for: vehicle)
    }
}

#Preview {
    @Previewable @State var vehicle = Vehicle(
        name: "Test Car",
        make: "Toyota",
        model: "Camry",
        year: 2022,
        currentMileage: 32500
    )

    @Previewable @State var service = Service(
        name: "Oil Change",
        dueDate: Calendar.current.date(byAdding: .day, value: 12, to: .now),
        dueMileage: 33000,
        intervalMonths: 6,
        intervalMiles: 5000
    )

    EditServiceView(service: service, vehicle: vehicle)
        .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self], inMemory: true)
        .preferredColorScheme(.dark)
}
