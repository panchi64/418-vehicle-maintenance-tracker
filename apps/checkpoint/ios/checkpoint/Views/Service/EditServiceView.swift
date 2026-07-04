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

    /// Explicit values always win; an interval is only allowed to re-derive a
    /// due when the user actually changed that interval in this edit AND the
    /// service has a real completion anchor. Never fabricates an anchor from
    /// `.now` — otherwise a notes-only save would silently shift the schedule,
    /// and clearing a due date/mileage would be impossible on a recurring
    /// service (the interval would immediately re-populate it).
    private var proposedSchedule: ReminderImpactCalculator.Schedule {
        let effectiveMonths = isRecurring ? intervalMonths : nil
        let effectiveMiles = isRecurring ? intervalMiles : nil
        let monthsChanged = effectiveMonths != loadedIntervalMonths
        let milesChanged = effectiveMiles != loadedIntervalMiles
        return ReminderImpactCalculator.projected(
            intervalMonths: (monthsChanged && service.lastPerformed != nil) ? effectiveMonths : nil,
            intervalMiles: (milesChanged && service.lastMileage != nil) ? effectiveMiles : nil,
            anchorDate: service.lastPerformed ?? .distantPast,
            anchorMileage: service.lastMileage ?? 0,
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
                            InstrumentSection(title: L10n.serviceDetailsTitle, chrome: .plain) {
                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    InstrumentTextField(
                                        label: L10n.serviceNameLabel,
                                        text: $serviceName,
                                        placeholder: L10n.serviceNamePlaceholder,
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

                            InstrumentSection(title: L10n.formNextDue, chrome: .plain) {
                                VStack(spacing: Spacing.md) {
                                    LabeledInstrumentToggle(
                                        label: L10n.formSetDueDate.uppercased(),
                                        accessibilityLabel: L10n.formSetDueDate,
                                        isOn: $hasDueDate
                                    )

                                    if hasDueDate {
                                        InstrumentDatePicker(
                                            label: L10n.formDueDate,
                                            date: $dueDate
                                        )
                                    }

                                    InstrumentNumberField(
                                        label: L10n.formDueMileage,
                                        value: $dueMileage,
                                        placeholder: L10n.formOptionalTag,
                                        suffix: DistanceSettings.shared.unit.abbreviation
                                    )

                                    if (hasDueDate ? dueDate : nil) != loadedSchedule.dueDate {
                                        OriginalValueHint(text: L10n.editWas(OriginalValueHint.value(forDate: loadedSchedule.dueDate)))
                                    }
                                    if dueMileage != loadedSchedule.dueMileage {
                                        OriginalValueHint(text: L10n.editWas(OriginalValueHint.value(forMileage: loadedSchedule.dueMileage)))
                                    }
                                }
                            }

                            InstrumentSection(title: L10n.formRepeats, chrome: .plain) {
                                VStack(spacing: Spacing.md) {
                                    LabeledInstrumentToggle(
                                        label: L10n.formRepeatAfterCompletion.uppercased(),
                                        accessibilityLabel: L10n.formRepeatAfterCompletion,
                                        isOn: $isRecurring
                                    )

                                    if isRecurring {
                                        InstrumentNumberField(
                                            label: L10n.formEvery,
                                            value: $intervalMonths,
                                            placeholder: "6",
                                            suffix: L10n.formMonthsSuffix
                                        )

                                        InstrumentNumberField(
                                            label: L10n.formOrEvery,
                                            value: $intervalMiles,
                                            placeholder: "5000",
                                            suffix: DistanceSettings.shared.unit.abbreviation
                                        )

                                        if intervalMonths != loadedIntervalMonths {
                                            OriginalValueHint(text: L10n.editWas(OriginalValueHint.value(forMonths: loadedIntervalMonths)))
                                        }
                                        if intervalMiles != loadedIntervalMiles {
                                            OriginalValueHint(text: L10n.editWas(OriginalValueHint.value(forMileage: loadedIntervalMiles)))
                                        }
                                    }
                                }
                            }

                            if let reminderImpact {
                                ReminderImpactRow(impact: reminderImpact)
                            }

                            InstrumentSection(title: L10n.formNotes, chrome: .plain) {
                                RichNotesEditor(
                                    label: L10n.formNotes,
                                    text: $notes,
                                    placeholder: L10n.formNotesPlaceholder,
                                    minHeight: 100
                                )
                            }

                            // Delete Button
                            Button {
                                showDeleteConfirmation = true
                            } label: {
                                HStack {
                                    Image(systemName: "trash")
                                    Text(L10n.serviceDeleteAction)
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
                .navigationTitle(L10n.serviceEditTitle)
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
                            showNameError = true
                            withAnimation { proxy.scrollTo("serviceName", anchor: .top) }
                        }
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
                    L10n.serviceDeleteConfirmTitle,
                    isPresented: $showDeleteConfirmation,
                    titleVisibility: .visible
                ) {
                    Button(L10n.commonDelete, role: .destructive) { deleteService() }
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
