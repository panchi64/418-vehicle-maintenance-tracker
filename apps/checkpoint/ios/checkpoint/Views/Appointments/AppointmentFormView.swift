//
//  AppointmentFormView.swift
//  checkpoint
//
//  Book or edit a shop visit — a Decision surface. Resolved in
//  tools/sketchpad (screens/AppointmentForm.tsx).
//
//  DEFAULT PATH (what makes the booking WORK): Shop → When → Services, then
//  the reminders it will set, as a readout. Address and note make it
//  COMPLETE and sit under Details (Decision rule 5): Maps can find a shop by
//  name, so an address isn't needed for directions.
//
//  TAP BUDGET — book from Home: 6 (sketchpad measured 4, ~6 with the real
//  date picker): Book → type the shop (focused already) or tap a past one →
//  When → pick → Save. The Next Up service is ticked already; tomorrow 9:00
//  needs no When at all. Services are check rows, not chips (see below).
//
//  DEFAULTS DO THE WORK: tomorrow at 9:00; the service Home was showing;
//  shops you've used before offered as you type.
//  ADVISORIES: `.blocking` at Shop when Save is tapped without one (F2);
//  `.caution` at When when another visit is booked that day.
//  Save in the toolbar (F1), dismiss-protected (F3). Cancel Appointment is
//  last in the scroll, confirmed, and only when editing a scheduled visit.
//

import SwiftUI
import SwiftData

struct AppointmentFormView: View {
    let request: AppointmentEditorRequest
    let vehicle: Vehicle

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query private var allAppointments: [Appointment]
    @Query private var visits: [ServiceVisit]

    @State private var fields: AppointmentFields
    @State private var baseline: AppointmentFields
    @State private var showBlocker = false
    @State private var showCancelConfirmation = false

    private var editing: Appointment? {
        if case .edit(let appointment) = request.target { return appointment }
        return nil
    }

    init(request: AppointmentEditorRequest, vehicle: Vehicle, now: Date = .now) {
        self.request = request
        self.vehicle = vehicle
        let initial: AppointmentFields
        switch request.target {
        case .new(_, let preselected):
            initial = .newBooking(now: now, serviceIDs: preselected.map(\.id))
        case .edit(let appointment):
            initial = AppointmentFields(appointment: appointment)
        }
        _fields = State(initialValue: initial)
        _baseline = State(initialValue: initial)
        _visits = Query(filter: #Predicate<ServiceVisit> { $0.shopName != nil })
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ZStack {
                    AtmosphericBackground()

                    ScrollView {
                        VStack(alignment: .leading, spacing: Spacing.xl) {
                            shopSection.id("shop")
                            whenSection
                            servicesSection
                            detailsSection
                            if editing?.isScheduled == true {
                                cancelButton
                            }
                        }
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .padding(.top, Spacing.md)
                        .padding(.bottom, Spacing.xxl)
                    }
                }
                .keyboardDismissToolbar()
                .formToolbar(
                    title: editing == nil ? L10n.appointmentFormTitleNew : L10n.appointmentFormTitleEdit,
                    subtitle: vehicle.displayName,
                    canSave: fields.isValid,
                    isDirty: fields != baseline,
                    onSave: save,
                    onBlocked: {
                        showBlocker = true
                        withAnimation { proxy.scrollTo("shop", anchor: .center) }
                    }
                )
                .trackScreen(.appointmentForm)
            }
        }
    }

    // MARK: - Sections

    private var shopSection: some View {
        FormSection(title: L10n.appointmentShop) {
            InstrumentTextField(
                label: nil,
                text: $fields.shopName,
                placeholder: L10n.appointmentShopPlaceholder,
                textContentType: .organizationName,
                autocapitalization: .words,
                requirement: .required(reason: L10n.appointmentShopRequired),
                // The one thing the defaults can't answer (sketchpad: book
                // from Home is 6 taps with this, 7 without).
                focusOnAppear: editing == nil
            )

            if showBlocker, !fields.isValid {
                FormAdvisory.blocking(L10n.appointmentShopRequired)
            }

            let suggestions = shopSuggestions
            if !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(suggestions, id: \.name) { suggestion in
                        Button {
                            fields.shopName = suggestion.name
                            if fields.address.isEmpty, let address = suggestion.address {
                                fields.address = address
                            }
                        } label: {
                            Text(suggestion.name)
                                .font(.brutalistBody)
                                .foregroundStyle(Theme.textPrimary)
                                .frame(maxWidth: .infinity, minHeight: TouchTarget.minimum, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint(L10n.appointmentShopSuggestionHint)
                    }
                }
            }
        }
    }

    private var whenSection: some View {
        FormSection(title: L10n.appointmentWhen) {
            InstrumentDatePicker(
                label: nil,
                date: $fields.startDate,
                displayedComponents: [.date, .hourAndMinute]
            )

            let sameDay = Appointment.sameDay(as: fields.startDate, in: allAppointments, excluding: editing?.id)
            if let other = sameDay.first {
                FormAdvisory.caution(L10n.appointmentSameDayCaution(
                    other.trimmedShopName ?? L10n.appointmentShopFallback,
                    other.startDate.formatted(date: .omitted, time: .shortened)
                ))
            }

            // The proof the booking will remind: a value, not an advisory.
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.appointmentReminders.uppercased())
                    .font(.brutalistLabel)
                    .tracking(1.5)
                    .foregroundStyle(Theme.textTertiary)
                Text(AppointmentFormat.reminders(for: fields.startDate) ?? L10n.appointmentRemindersNone)
                    .font(.brutalistBodyEmphasis)
                    .foregroundStyle(Theme.textPrimary)
            }
            .accessibilityElement(children: .combine)
        }
    }

    @ViewBuilder
    private var servicesSection: some View {
        // Tracked services only (a completed one-off keeps its history under
        // the same name and would list twice), plus any already linked.
        let services = (vehicle.services ?? [])
            .filter { $0.hasDueTracking || fields.serviceIDs.contains($0.id) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        FormSection(title: L10n.appointmentServices, trailing: L10n.formOptionalTag) {
            if services.isEmpty {
                InsufficientDataNote(message: L10n.appointmentServicesEmpty)
            } else {
                // Check rows, as the starter schedule's: filled chips
                // out-shouted Shop and When under the squint test, and plain
                // chips showed selection by brightness alone.
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(services, id: \.id) { service in
                        serviceRow(service, isSelected: fields.serviceIDs.contains(service.id))
                    }
                }
            }
        }
    }

    private var detailsSection: some View {
        CollapsibleDetailsSection(
            storageKey: "formDetailsAppointment",
            filledCount: [fields.address, fields.note].filter { !$0.isEmpty }.count,
            autoExpandWhenFilled: true
        ) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                InstrumentTextField(
                    label: L10n.appointmentAddress,
                    text: $fields.address,
                    placeholder: L10n.appointmentAddressPlaceholder,
                    textContentType: .fullStreetAddress,
                    autocapitalization: .words
                )
                InstrumentTextEditor(
                    label: L10n.appointmentNote,
                    text: $fields.note,
                    placeholder: L10n.appointmentNotePlaceholder,
                    minHeight: 80
                )
            }
        }
    }

    /// Destructive, so last in the scroll and never beside Save (F1).
    private var cancelButton: some View {
        DestructiveFormButton(title: L10n.appointmentCancelAction) {
            showCancelConfirmation = true
        }
        .alert(L10n.appointmentCancelConfirmTitle, isPresented: $showCancelConfirmation) {
            Button(L10n.appointmentCancelAction, role: .destructive, action: cancelAppointment)
            Button(L10n.appointmentKeepAction, role: .cancel) {}
        } message: {
            Text(L10n.appointmentCancelConfirmMessage)
        }
    }

    // MARK: - Values

    private struct ShopSuggestion {
        let name: String
        let address: String?
    }

    /// Shops used before that start with (or contain) what's typed, newest
    /// first, never the exact text already there. At most three.
    private var shopSuggestions: [ShopSuggestion] {
        let typed = fields.shopName.trimmingCharacters(in: .whitespacesAndNewlines)
        // Unchanged since the sheet opened (an edit) offers nothing: the
        // user didn't ask.
        guard !typed.isEmpty, fields.shopName != baseline.shopName else { return [] }
        let fromAppointments = allAppointments
            .sorted { $0.createdAt > $1.createdAt }
            .compactMap { appointment in
                appointment.trimmedShopName.map { ShopSuggestion(name: $0, address: appointment.address) }
            }
        let fromVisits = visits
            .sorted { $0.performedDate > $1.performedDate }
            .compactMap { visit in
                visit.shopName.map { ShopSuggestion(name: $0, address: nil) }
            }
        var seen = Set<String>()
        return (fromAppointments + fromVisits).filter { suggestion in
            let key = suggestion.name.lowercased()
            guard key != typed.lowercased(), suggestion.name.localizedStandardContains(typed),
                  !seen.contains(key) else { return false }
            seen.insert(key)
            return true
        }
        .prefix(3)
        .map { $0 }
    }

    private func serviceRow(_ service: Service, isSelected: Bool) -> some View {
        Button {
            toggle(service)
            HapticService.shared.selectionChanged()
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(isSelected ? Theme.accent : Theme.textTertiary)
                    .accessibilityHidden(true)
                Text(service.name)
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: TouchTarget.minimum)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func toggle(_ service: Service) {
        if let index = fields.serviceIDs.firstIndex(of: service.id) {
            fields.serviceIDs.remove(at: index)
        } else {
            fields.serviceIDs.append(service.id)
        }
    }

    // MARK: - Actions

    private func save() {
        HapticService.shared.success()
        if let editing {
            AppointmentService.update(editing, with: fields)
        } else {
            AppointmentService.schedule(fields, on: vehicle, in: modelContext)
            IntentDonations.bookedAppointment(on: vehicle, shop: fields.shopName)
        }
        try? modelContext.save()
        SpotlightIndexer.shared.scheduleReindex(from: modelContext.container)
        ToastService.shared.show(
            editing == nil ? L10n.appointmentToastBooked : L10n.appointmentToastUpdated,
            icon: "calendar.badge.checkmark",
            style: .success
        )
        dismiss()
    }

    private func cancelAppointment() {
        guard let editing else { return }
        HapticService.shared.warning()
        AppointmentService.cancel(editing)
        try? modelContext.save()
        SpotlightIndexer.shared.scheduleReindex(from: modelContext.container)
        ToastService.shared.show(L10n.appointmentToastCancelled, icon: "calendar.badge.minus", style: .success)
        dismiss()
    }
}

#Preview {
    let vehicle = Vehicle.sampleVehicle
    return AppointmentFormView(
        request: AppointmentEditorRequest(target: .new(vehicle, preselected: [])),
        vehicle: vehicle
    )
    .environment(AppState())
    .modelContainer(for: Vehicle.self, inMemory: true)
}
