//
//  AddServiceView.swift
//  checkpoint
//
//  Dual-mode form for logging past services or scheduling future services
//  with instrument cluster aesthetic
//

import SwiftUI
import SwiftData

enum ServiceMode: String, CaseIterable {
    case record = "Record"
    case remind = "Remind"
}

struct AddServiceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query private var services: [Service]

    let vehicle: Vehicle
    var seasonalPrefill: SeasonalPrefill?
    var initialMode: ServiceMode = .record

    // Mode selection
    @State private var mode: ServiceMode

    init(vehicle: Vehicle, seasonalPrefill: SeasonalPrefill? = nil, initialMode: ServiceMode = .record) {
        self.vehicle = vehicle
        self.seasonalPrefill = seasonalPrefill
        self.initialMode = initialMode
        _mode = State(initialValue: initialMode)
    }

    // Service type selection
    @State private var selectedPreset: PresetData? = nil
    @State private var customServiceName: String = ""

    // Log mode fields
    @State private var performedDate: Date = Date()
    @State private var mileageAtService: Int? = nil
    @State private var cost: String = ""
    @State private var costError: String?
    @State private var costCategory: CostCategory = .maintenance
    @State private var notes: String = ""
    @State private var scheduleRecurring: Bool = false
    @State private var pendingAttachments: [AttachmentPicker.AttachmentData] = []

    // Schedule mode fields
    @State private var hasCustomDate: Bool = false
    @State private var dueDate: Date = Date()
    @State private var dueMileage: Int? = nil
    @State private var intervalMonths: Int? = nil
    @State private var intervalMiles: Int? = nil

    /// The due date that will be saved — derived from interval, custom pick, or nil.
    /// Used by both the UI (to show the derived date) and save logic.
    private var effectiveDueDate: Date? {
        if hasCustomDate {
            return dueDate
        } else if let months = intervalMonths, months > 0 {
            return Calendar.current.date(byAdding: .month, value: months, to: Date())
        } else {
            return nil
        }
    }

    var serviceName: String {
        selectedPreset?.name ?? customServiceName
    }

    var isFormValid: Bool {
        !serviceName.isEmpty && (mode == .record ? mileageAtService != nil : true)
    }

    /// Preview text showing when the next service would be due
    private var nextDuePreview: String? {
        guard scheduleRecurring else { return nil }
        var parts: [String] = []

        if let months = intervalMonths, months > 0 {
            if let nextDate = Calendar.current.date(byAdding: .month, value: months, to: performedDate) {
                parts.append(Formatters.shortDate.string(from: nextDate))
            }
        }

        if let miles = intervalMiles, miles > 0, let currentMileage = mileageAtService {
            let nextMileage = currentMileage + miles
            parts.append("at \(Formatters.mileage(nextMileage))")
        }

        guard !parts.isEmpty else { return nil }
        return "Next due: \(parts.joined(separator: " or "))"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphericBackground()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Mode picker
                        InstrumentSegmentedControl(
                            options: ServiceMode.allCases,
                            selection: $mode
                        ) { option in
                            option.rawValue
                        }

                        // Service type section
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            InstrumentSectionHeader(title: "Service Type")

                            ServiceTypePicker(
                                selectedPreset: $selectedPreset,
                                customServiceName: $customServiceName
                            )
                        }

                        // Mode-specific fields
                        if mode == .record {
                            logModeFields
                        } else {
                            scheduleModeFields
                        }
                    }
                    .padding(Spacing.screenHorizontal)
                    .padding(.bottom, Spacing.xxl)
                }
            }
            .numberPadDoneButton()
            .navigationTitle(mode == .record ? "Record Service" : "Set Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.surfaceInstrument, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .toolbarButtonStyle()
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveService() }
                        .toolbarButtonStyle(isDisabled: !isFormValid)
                        .disabled(!isFormValid)
                }
            }
            .onChange(of: selectedPreset) { _, newPreset in
                if let preset = newPreset {
                    if let months = preset.defaultIntervalMonths {
                        intervalMonths = months
                    }
                    if let miles = preset.defaultIntervalMiles {
                        intervalMiles = miles
                    }
                    // Auto-enable recurring when preset has intervals (Record mode)
                    if mode == .record {
                        let hasIntervals = (preset.defaultIntervalMonths ?? 0) > 0 || (preset.defaultIntervalMiles ?? 0) > 0
                        if hasIntervals {
                            scheduleRecurring = true
                        }
                    }
                }
            }
            .trackScreen(.addService)
            .onAppear {
                // Pre-fill mileage with current vehicle mileage
                if mileageAtService == nil {
                    mileageAtService = vehicle.currentMileage
                }
                // Apply seasonal reminder pre-fill
                // Seasonal dates are seasonally meaningful (e.g., Oct 1 for antifreeze),
                // so we use the prefill date as a custom override rather than deriving from interval.
                if let prefill = seasonalPrefill {
                    mode = .remind
                    customServiceName = prefill.serviceName
                    hasCustomDate = true
                    dueDate = prefill.dueDate
                    intervalMonths = prefill.intervalMonths
                }
            }
        }
    }

    // MARK: - Log Mode Fields

    @ViewBuilder
    private var logModeFields: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: "Date Performed")

            InstrumentDatePicker(
                label: "Date Performed",
                date: $performedDate
            )
        }

        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: "Cost")

            VStack(spacing: Spacing.md) {
                InstrumentTextField(
                    label: "Amount",
                    text: $cost,
                    placeholder: "0.00",
                    keyboardType: .decimalPad
                )
                .onChange(of: cost) { _, newValue in
                    cost = CostValidation.filterCostInput(newValue)
                    costError = CostValidation.validate(cost)
                }

                if let costError {
                    ErrorMessageRow(message: costError) {
                        self.costError = nil
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("CATEGORY")
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(1)

                    InstrumentSegmentedControl(
                        options: CostCategory.allCases,
                        selection: $costCategory
                    ) { category in
                        category.displayName
                    }
                }
            }
        }

        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: "Mileage")

            InstrumentNumberField(
                label: "Mileage *",
                value: $mileageAtService,
                placeholder: "Required",
                suffix: DistanceSettings.shared.unit.abbreviation
            )

            if mileageAtService == nil {
                Text("MILEAGE IS REQUIRED TO SAVE")
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.statusOverdue.opacity(0.7))
                    .tracking(1)
            }
        }

        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: "Reminder")

            VStack(spacing: Spacing.sm) {
                HStack {
                    Text("REMIND ME NEXT TIME")
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(1)

                    Spacer()

                    Toggle("", isOn: $scheduleRecurring)
                        .labelsHidden()
                        .tint(Theme.accent)
                        .accessibilityLabel("Remind me next time")
                }
                .padding(Spacing.md)
                .accessibilityElement(children: .combine)
                .background(Theme.surfaceInstrument)
                .overlay(
                    Rectangle()
                        .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
                )

                if scheduleRecurring {
                    Text(L10n.reminderHelperText)
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let preview = nextDuePreview {
                        Text(preview)
                            .font(.brutalistSecondary)
                            .foregroundStyle(Theme.accent)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }

        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: "Notes")

            InstrumentTextEditor(
                label: "Notes",
                text: $notes,
                placeholder: "Add notes...",
                minHeight: 80
            )
        }

        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: "Attachments")

            AttachmentPicker(attachments: $pendingAttachments)
        }
    }

    // MARK: - Schedule Mode Fields

    @ViewBuilder
    private var scheduleModeFields: some View {
        // Interval first — this drives the derived due date
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
                    suffix: "miles"
                )
            }
        }

        // Due section — adapts based on whether an interval is set
        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: "When Is It Due?")

            VStack(spacing: Spacing.md) {
                if let months = intervalMonths, months > 0 {
                    // Interval is set — show derived date as informational text
                    if let date = effectiveDueDate {
                        HStack {
                            Text("DUE DATE")
                                .font(.brutalistLabel)
                                .foregroundStyle(Theme.textTertiary)
                                .tracking(1)

                            Spacer()

                            Text(Formatters.mediumDate.string(from: date))
                                .font(.brutalistBody)
                                .foregroundStyle(Theme.accent)
                        }
                        .padding(Spacing.md)
                        .background(Theme.surfaceInstrument)
                        .overlay(
                            Rectangle()
                                .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
                        )
                    }
                } else {
                    // No interval — allow a one-off custom date
                    HStack {
                        Text("SET DUE DATE")
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.textTertiary)
                            .tracking(1)

                        Spacer()

                        Toggle("", isOn: $hasCustomDate)
                            .labelsHidden()
                            .tint(Theme.accent)
                            .accessibilityLabel("Set due date")
                    }
                    .padding(Spacing.md)
                    .accessibilityElement(children: .combine)
                    .background(Theme.surfaceInstrument)
                    .overlay(
                        Rectangle()
                            .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
                        )

                    if hasCustomDate {
                        InstrumentDatePicker(
                            label: "Due Date",
                            date: $dueDate
                        )
                    }
                }

                if let miles = intervalMiles, miles > 0 {
                    // Interval is set — show derived mileage as informational text
                    HStack {
                        Text("DUE MILEAGE")
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.textTertiary)
                            .tracking(1)

                        Spacer()

                        Text(Formatters.mileage(vehicle.currentMileage + miles))
                            .font(.brutalistBody)
                            .foregroundStyle(Theme.accent)
                    }
                    .padding(Spacing.md)
                    .background(Theme.surfaceInstrument)
                    .overlay(
                        Rectangle()
                            .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
                    )
                } else {
                    // No mile interval — allow explicit due mileage
                    InstrumentNumberField(
                        label: "Due Mileage",
                        value: $dueMileage,
                        placeholder: "Optional",
                        suffix: "mi"
                    )
                }
            }
        }

        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: "Notes")

            InstrumentTextEditor(
                label: "Notes",
                text: $notes,
                placeholder: "Add notes...",
                minHeight: 80
            )
        }
    }

    // MARK: - Save Logic

    private func saveService() {
        // Analytics
        let isPreset = selectedPreset != nil
        let category = selectedPreset?.category
        let hasInterval = scheduleRecurring && ((intervalMonths != nil && intervalMonths != 0) || (intervalMiles != nil && intervalMiles != 0))

        HapticService.shared.success()

        if mode == .record {
            AnalyticsService.shared.capture(.serviceLogged(
                isPreset: isPreset,
                category: category,
                hasInterval: hasInterval
            ))
            saveLoggedService()
        } else {
            AnalyticsService.shared.capture(.serviceScheduled(
                isPreset: isPreset,
                category: category,
                hasInterval: hasInterval
            ))
            saveScheduledService()
        }
        updateAppIcon()
        updateWidgetData()
        if mode == .record {
            ToastService.shared.show(L10n.toastServiceRecorded, icon: "checkmark", style: .success)
        } else {
            ToastService.shared.show(L10n.toastReminderSet, icon: "clock", style: .success)
        }
        appState.recordCompletedAction()
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

    private func saveLoggedService() {
        let mileage = mileageAtService ?? vehicle.currentMileage

        // Create service
        let service = Service(
            name: serviceName,
            lastPerformed: performedDate,
            lastMileage: mileage,
            intervalMonths: scheduleRecurring ? intervalMonths : nil,
            intervalMiles: scheduleRecurring ? intervalMiles : nil
        )
        service.vehicle = vehicle

        // Derive next due date/mileage from intervals (only when recurring)
        if scheduleRecurring {
            service.deriveDueFromIntervals(anchorDate: performedDate, anchorMileage: mileage)
        }

        modelContext.insert(service)

        // Create service log entry
        let costDecimal = Decimal(string: cost)
        let log = ServiceLog(
            service: service,
            vehicle: vehicle,
            performedDate: performedDate,
            mileageAtService: mileage,
            cost: costDecimal,
            costCategory: costDecimal != nil ? costCategory : nil,
            notes: notes.isEmpty ? nil : notes
        )
        modelContext.insert(log)

        // Save attachments
        for a in pendingAttachments {
            ServiceAttachment.insert(
                serviceLog: log, data: a.data, fileName: a.fileName,
                mimeType: a.mimeType, extractedText: a.extractedText, into: modelContext
            )
        }

        // Update vehicle mileage and create pace snapshot
        vehicle.recordServiceMileage(mileage, at: performedDate, context: modelContext)
    }

    private func saveScheduledService() {
        let service = Service(
            name: serviceName,
            intervalMonths: intervalMonths,
            intervalMiles: intervalMiles,
            notes: notes.isEmpty ? nil : notes
        )
        service.vehicle = vehicle

        // Derive deadlines from intervals (same logic as record mode and mark-complete)
        service.deriveDueFromIntervals(anchorDate: Date(), anchorMileage: vehicle.currentMileage)

        // Apply user overrides: custom date or explicit due mileage take precedence
        if hasCustomDate {
            service.dueDate = dueDate
        }
        if let explicit = dueMileage {
            service.dueMileage = explicit
        }

        modelContext.insert(service)
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

    AddServiceView(vehicle: vehicle)
        .environment(AppState())
        .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self], inMemory: true)
}
