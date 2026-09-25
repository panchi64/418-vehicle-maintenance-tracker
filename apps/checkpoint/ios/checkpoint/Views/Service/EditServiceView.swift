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
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Query var services: [Service]

    @Bindable var service: Service
    let vehicle: Vehicle

    // Service details
    @State var serviceName: String = ""
    @State var dueDate: Date = Date()
    @State var hasDueDate: Bool = false
    @State var dueMileage: Int? = nil
    @State var intervalMonths: Int? = nil
    @State var intervalMiles: Int? = nil
    @State var isRecurring: Bool = false
    @State var notes: String = ""

    // Loaded originals, for change-transparency hints (F6) and the impact preview (F9)
    @State var loadedServiceName: String = ""
    @State var loadedSchedule = ReminderImpactCalculator.Schedule(dueDate: nil, dueMileage: nil)
    @State var loadedIntervalMonths: Int? = nil
    @State var loadedIntervalMiles: Int? = nil
    @State var loadedIsRecurring = false
    @State var loadedNotes = ""

    @State var reminderImpact: ReminderImpactCalculator.ReminderImpact?
    @State var showNameError = false
    @State var showDeleteConfirmation = false

    var isFormValid: Bool {
        !serviceName.isEmpty
    }

    /// Whether Save would write anything. Mirrors `loadServiceData()`.
    private var isDirty: Bool {
        serviceName != loadedServiceName
            || (hasDueDate ? dueDate : nil) != loadedSchedule.dueDate
            || dueMileage != loadedSchedule.dueMileage
            || intervalMonths != loadedIntervalMonths
            || intervalMiles != loadedIntervalMiles
            || isRecurring != loadedIsRecurring
            || notes != loadedNotes
    }

    /// Explicit values always win; an interval is only allowed to re-derive a
    /// due when the user actually changed that interval in this edit AND the
    /// service has a real completion anchor. Never fabricates an anchor from
    /// `.now` — otherwise a notes-only save would silently shift the schedule,
    /// and clearing a due date/mileage would be impossible on a recurring
    /// service (the interval would immediately re-populate it).
    var proposedSchedule: ReminderImpactCalculator.Schedule {
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
                                        requirement: .required(reason: L10n.formServiceTypeRequired)
                                    )

                                    if serviceName != loadedServiceName {
                                        OriginalValueHint(text: L10n.editWas(loadedServiceName.isEmpty ? L10n.impactNone : loadedServiceName))
                                    }

                                    if showNameError, serviceName.isEmpty {
                                        FormAdvisory.blocking(L10n.formServiceTypeRequired)
                                    }
                                }
                            }
                            .id("serviceName")

                            InstrumentSection(title: L10n.formNextDue, chrome: .plain) {
                                VStack(spacing: Spacing.md) {
                                    LabeledInstrumentToggle(
                                        label: L10n.formSetDueDate,
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
                                        label: L10n.formRepeatAfterCompletion,
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
                                // No field label: the section header above is
                                // already the word NOTES, and repeating it
                                // reads as a rendering fault.
                                RichNotesEditor(
                                    label: nil,
                                    text: $notes,
                                    placeholder: L10n.formNotesPlaceholder,
                                    minHeight: 100
                                )
                            }

                            // Delete Button
                            DestructiveFormButton(title: L10n.serviceDeleteAction) {
                                showDeleteConfirmation = true
                            }
                            .padding(.top, Spacing.md)
                        }
                        .padding(Spacing.screenHorizontal)
                        .padding(.bottom, Spacing.xxl)
                    }
                }
                .keyboardDismissToolbar()
                .formToolbar(
                    title: L10n.serviceEditTitle,
                    subtitle: vehicle.displayName,
                    canSave: isFormValid,
                    isDirty: isDirty,
                    onSave: saveChanges,
                    onBlocked: {
                        showNameError = true
                        withAnimation { proxy.scrollTo("serviceName", anchor: .center) }
                    }
                )
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
