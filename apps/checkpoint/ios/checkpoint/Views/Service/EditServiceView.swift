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

    // Loaded originals, for change-transparency hints (G8) and the impact preview (R6)
    @State private var loadedServiceName: String = ""
    @State private var loadedSchedule = ReminderImpactCalculator.Schedule(dueDate: nil, dueMileage: nil)
    @State private var loadedIntervalMonths: Int? = nil
    @State private var loadedIntervalMiles: Int? = nil

    @State private var reminderImpact: ReminderImpactCalculator.ReminderImpact?
    @State private var showNameError = false
    @State private var showDeleteConfirmation = false

    var isFormValid: Bool {
        !serviceName.isEmpty
    }

    /// Mirrors `Service.deriveDueFromIntervals`'s "explicit wins, else interval
    /// projects from the anchor, else clear" contract, so an interval-only
    /// edit actually reschedules the service instead of silently no-op'ing.
    private var proposedSchedule: ReminderImpactCalculator.Schedule {
        ReminderImpactCalculator.projected(
            intervalMonths: isRecurring ? intervalMonths : nil,
            intervalMiles: isRecurring ? intervalMiles : nil,
            anchorDate: service.lastPerformed ?? .now,
            anchorMileage: service.lastMileage ?? vehicle.currentMileage,
            explicitDueDate: hasDueDate ? dueDate : nil,
            explicitDueMileage: dueMileage
        )
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ZStack {
                    AtmosphericBackground()

                    ScrollView {
                        VStack(spacing: Spacing.lg) {
                            InstrumentSection(title: "Service Details", chrome: .plain) {
                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    InstrumentTextField(
                                        label: "Service Name",
                                        text: $serviceName,
                                        placeholder: "Oil Change, Tire Rotation...",
                                        isRequired: true
                                    )

                                    if serviceName != loadedServiceName {
                                        OriginalValueHint(text: L10n.editWas(loadedServiceName.isEmpty ? L10n.impactNone : loadedServiceName))
                                    }

                                    if showNameError, serviceName.isEmpty {
                                        ErrorMessageRow(message: L10n.formServiceTypeRequired) {
                                            showNameError = false
                                        }
                                    }
                                }
                            }
                            .id("serviceName")

                            InstrumentSection(title: "Next Due", chrome: .plain) {
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

                                    if (hasDueDate ? dueDate : nil) != loadedSchedule.dueDate {
                                        OriginalValueHint(text: L10n.editWas(hintValue(forDate: loadedSchedule.dueDate)))
                                    }
                                    if dueMileage != loadedSchedule.dueMileage {
                                        OriginalValueHint(text: L10n.editWas(hintValue(forMileage: loadedSchedule.dueMileage)))
                                    }
                                }
                            }

                            InstrumentSection(title: "Repeats", chrome: .plain) {
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

                                        if intervalMonths != loadedIntervalMonths {
                                            OriginalValueHint(text: L10n.editWas(hintValue(forMonths: loadedIntervalMonths)))
                                        }
                                        if intervalMiles != loadedIntervalMiles {
                                            OriginalValueHint(text: L10n.editWas(hintValue(forMileage: loadedIntervalMiles)))
                                        }
                                    }
                                }
                            }

                            if let reminderImpact {
                                ReminderImpactRow(impact: reminderImpact)
                            }

                            InstrumentSection(title: "Notes", chrome: .plain) {
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
                        Button(L10n.commonCancel) { dismiss() }
                            .toolbarButtonStyle()
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    FormActionBar(
                        primaryTitle: L10n.commonSave,
                        isPrimaryEnabled: isFormValid,
                        onPrimary: { saveChanges() },
                        onDisabledPrimaryTap: {
                            HapticService.shared.error()
                            showNameError = true
                            withAnimation { proxy.scrollTo("serviceName", anchor: .top) }
                        },
                        isKeyboardVisible: KeyboardVisibility.shared.isVisible
                    )
                }
                .onChange(of: serviceName) { _, newValue in
                    if !newValue.isEmpty { showNameError = false }
                }
                .task(id: proposedSchedule) {
                    try? await Task.sleep(for: .seconds(0.3))
                    guard !Task.isCancelled else { return }
                    reminderImpact = ReminderImpactCalculator.impact(current: loadedSchedule, proposed: proposedSchedule)
                }
                .confirmationDialog(
                    "Delete Service?",
                    isPresented: $showDeleteConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Delete", role: .destructive) { deleteService() }
                    Button(L10n.commonCancel, role: .cancel) { }
                } message: {
                    Text(L10n.serviceDeleteConfirmMessage)
                }
                .trackScreen(.editService)
                .onAppear {
                    loadServiceData()
                }
            }
        }
    }

    private func hintValue(forDate date: Date?) -> String {
        date.map { Formatters.shortDate.string(from: $0) } ?? L10n.impactNone
    }

    private func hintValue(forMileage mileage: Int?) -> String {
        mileage.map { Formatters.mileage($0) } ?? L10n.impactNone
    }

    private func hintValue(forMonths months: Int?) -> String {
        months.map { "\($0) mo" } ?? L10n.impactNone
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

        loadedServiceName = service.name
        loadedSchedule = ReminderImpactCalculator.Schedule(dueDate: service.dueDate, dueMileage: service.dueMileage)
        loadedIntervalMonths = service.intervalMonths
        loadedIntervalMiles = service.intervalMiles
    }

    // MARK: - Save Logic

    private func saveChanges() {
        HapticService.shared.success()
        AnalyticsService.shared.capture(.serviceEdited)

        service.name = serviceName
        let schedule = proposedSchedule
        service.dueDate = schedule.dueDate
        service.dueMileage = schedule.dueMileage
        service.intervalMonths = isRecurring ? intervalMonths : nil
        service.intervalMiles = isRecurring ? intervalMiles : nil
        service.isRecurring = isRecurring && Service.hasIntervalPolicy(
            intervalMonths: intervalMonths,
            intervalMiles: intervalMiles
        )
        service.notes = notes.isEmpty ? nil : notes

        ServiceNotificationScheduler.cancelNotification(for: service)
        ServiceNotificationScheduler.rescheduleNotifications(for: vehicle)

        updateAppIcon()
        updateWidgetData()

        ToastService.shared.show(L10n.toastServiceUpdated, icon: "checkmark", style: .success)
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
