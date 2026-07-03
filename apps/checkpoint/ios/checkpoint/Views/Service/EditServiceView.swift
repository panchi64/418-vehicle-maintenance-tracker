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
    @State private var isRecurring: Bool = false
    @State private var notes: String = ""

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

                        // Next Due Section
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            InstrumentSectionHeader(title: "Next Due")

                            VStack(spacing: Spacing.md) {
                                LabeledInstrumentToggle(
                                    label: "SET DUE DATE",
                                    accessibilityLabel: "Set due date",
                                    isOn: $hasDueDate
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

                        // Repeats Section
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            InstrumentSectionHeader(title: "Repeats")

                            VStack(spacing: Spacing.md) {
                                LabeledInstrumentToggle(
                                    label: "REPEAT AFTER COMPLETION",
                                    accessibilityLabel: "Repeat after completion",
                                    isOn: $isRecurring
                                )

                                if isRecurring {
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
                        }

                        // Notes Section
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            InstrumentSectionHeader(title: "Notes")

                            RichNotesEditor(
                                label: "Notes",
                                text: $notes,
                                placeholder: "Add notes...",
                                minHeight: 100
                            )
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
            .numberPadDoneButton()
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
                Text(L10n.serviceDeleteConfirmMessage)
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
        isRecurring = service.isRecurring
        notes = service.notes ?? ""
    }

    // MARK: - Save Logic

    private func saveChanges() {
        HapticService.shared.success()
        AnalyticsService.shared.capture(.serviceEdited)

        service.name = serviceName
        service.dueDate = hasDueDate ? dueDate : nil
        service.dueMileage = dueMileage
        service.intervalMonths = isRecurring ? intervalMonths : nil
        service.intervalMiles = isRecurring ? intervalMiles : nil
        service.isRecurring = isRecurring && Service.hasIntervalPolicy(
            intervalMonths: intervalMonths,
            intervalMiles: intervalMiles
        )
        service.notes = notes.isEmpty ? nil : notes

        updateAppIcon()
        updateWidgetData()
        dismiss()
    }

    // MARK: - Delete Logic

    private func deleteService() {
        AnalyticsService.shared.capture(.serviceDeleted)
        modelContext.delete(service)
        // Deleting the service cascades to its logs, which now .nullify their
        // attachments rather than deleting them. Any attachment that had no
        // vehicle link (e.g. a receipt saved before the Documents library and
        // never backfilled) is left with neither a log nor a vehicle — sweep
        // those so they don't linger in external storage with no owner.
        // Documents that are linked to a vehicle survive in the library.
        Document.purgeOrphans(in: modelContext)
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
