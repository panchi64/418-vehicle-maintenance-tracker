import SwiftUI
import SwiftData

enum ServiceMode: String, CaseIterable {
    case record = "Record"
    case remind = "Remind"
}

struct AddServiceView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Environment(AppState.self) var appState
    @Query var services: [Service]
    @Query var serviceLogs: [ServiceLog]

    let vehicle: Vehicle
    var seasonalPrefill: SeasonalPrefill?
    var initialMode: ServiceMode = .record

    @State var mode: ServiceMode

    init(vehicle: Vehicle, seasonalPrefill: SeasonalPrefill? = nil, initialMode: ServiceMode = .record) {
        self.vehicle = vehicle
        self.seasonalPrefill = seasonalPrefill
        self.initialMode = initialMode
        _mode = State(initialValue: initialMode)
    }

    @State var selectedPreset: PresetData? = nil
    @State var customServiceName: String = ""

    @State var performedDate: Date = Date()
    @State var mileageAtService: Int? = nil
    @State var cost: String = ""
    @State private var costError: String?
    @State var costCategory: CostCategory = .maintenance
    @State var notes: String = ""
    /// Shared "this should repeat after completion" toggle. In record mode it
    /// also schedules the next occurrence inline; in remind mode it gates
    /// whether `isRecurring` is persisted on the Service.
    @State var isRecurring: Bool = false
    @State var pendingAttachments: [AttachmentPicker.AttachmentData] = []

    @State var hasCustomDate: Bool = false
    @State var dueDate: Date = Date()
    @State var nextDueMileage: Int? = nil
    @State var intervalMonths: Int? = nil
    @State var intervalMiles: Int? = nil

    @State private var presets: [PresetData] = []

    /// Drives `Service.dueDate` directly at save time — no derivation from
    /// intervals. Intervals are recurrence policy only.
    var nextDueDate: Date? {
        hasCustomDate ? dueDate : nil
    }

    /// Whether the scheduled occurrence should chain forward on completion.
    /// Only meaningful when intervals are also set — explicit user intent
    /// (the toggle) plus a non-zero policy.
    var isRecurringSchedule: Bool {
        isRecurring && Service.hasIntervalPolicy(intervalMonths: intervalMonths, intervalMiles: intervalMiles)
    }

    var serviceName: String {
        selectedPreset?.name ?? customServiceName
    }

    var isFormValid: Bool {
        !serviceName.isEmpty
    }

    var lastLogForVehicle: ServiceLog? {
        serviceLogs.forVehicleNewestFirst(vehicle).first
    }

    var quickChips: [PresetData] {
        serviceLogs.topPresetChips(for: vehicle, from: presets, limit: 4)
    }

    private var anchors: ServiceFormAnchors {
        ServiceFormAnchors(
            vehicle: vehicle,
            logs: serviceLogs,
            serviceName: serviceName,
            performedDate: performedDate,
            enteredMileage: mileageAtService,
            enteredCostString: cost
        )
    }

    func useLastEntry() {
        guard let log = lastLogForVehicle else { return }
        let template = LoggedServiceTemplate(from: log)
        selectedPreset = nil
        customServiceName = template.serviceName
        cost = template.costString
        if let category = template.costCategory {
            costCategory = category
        }
        notes = template.notes ?? ""
        intervalMonths = template.intervalMonths
        intervalMiles = template.intervalMiles
        isRecurring = template.hasRecurringIntervals
        HapticService.shared.selectionChanged()
    }

    private var nextDuePreview: String? {
        guard isRecurring else { return nil }
        var parts: [String] = []

        if let months = intervalMonths, months > 0,
           let nextDate = Calendar.current.date(byAdding: .month, value: months, to: performedDate) {
            parts.append(Formatters.shortDate.string(from: nextDate))
        }

        if let miles = intervalMiles, miles > 0, let currentMileage = mileageAtService {
            parts.append("at \(Formatters.mileage(currentMileage + miles))")
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
                        InstrumentSegmentedControl(
                            options: ServiceMode.allCases,
                            selection: $mode
                        ) { option in
                            option.rawValue
                        }

                        if mode == .record, let last = lastLogForVehicle {
                            UseLastEntryButton(
                                serviceName: last.service?.name ?? "previous service",
                                performedDate: last.performedDate,
                                action: useLastEntry
                            )
                        }

                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            InstrumentSectionHeader(title: "Service Type")

                            if selectedPreset == nil, !quickChips.isEmpty {
                                QuickServiceChipsRow(chips: quickChips) { preset in
                                    selectedPreset = preset
                                    HapticService.shared.selectionChanged()
                                }
                            }

                            ServiceTypePicker(
                                selectedPreset: $selectedPreset,
                                customServiceName: $customServiceName
                            )
                        }

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
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.surfaceInstrument, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .toolbarButtonStyle()
                }
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text(vehicle.displayName)
                            .font(.brutalistBody)
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(1)
                        Text(mode == .record ? "RECORD SERVICE" : "SET REMINDER")
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.textTertiary)
                            .tracking(1)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(vehicle.displayName), \(mode == .record ? "Record Service" : "Set Reminder")")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveService() }
                        .toolbarButtonStyle(isDisabled: !isFormValid)
                        .disabled(!isFormValid)
                }
            }
            .onChange(of: selectedPreset) { _, newPreset in
                guard let preset = newPreset else { return }
                if let months = preset.defaultIntervalMonths { intervalMonths = months }
                if let miles = preset.defaultIntervalMiles { intervalMiles = miles }
                if Service.hasIntervalPolicy(
                    intervalMonths: preset.defaultIntervalMonths,
                    intervalMiles: preset.defaultIntervalMiles
                ) {
                    isRecurring = true
                }
            }
            .trackScreen(.addService)
            .onAppear {
                if presets.isEmpty {
                    presets = PresetDataService.shared.loadPresets()
                }
                if mileageAtService == nil {
                    mileageAtService = vehicle.currentMileage
                }
                if let prefill = seasonalPrefill {
                    mode = .remind
                    customServiceName = prefill.serviceName
                    hasCustomDate = true
                    dueDate = prefill.dueDate
                    intervalMonths = prefill.intervalMonths
                    isRecurring = true
                }
            }
        }
    }

    @ViewBuilder
    private var logModeFields: some View {
        let anchors = self.anchors

        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: "Date Performed")
            InstrumentDatePicker(label: "Date Performed", date: $performedDate)
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

                if let hint = anchors.priorCostHint {
                    Text(hint)
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel(hint)
                }

                if let warning = anchors.costWarning {
                    SanityWarningRow(message: warning)
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
                    ) { $0.displayName }
                }
            }
        }

        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: "Mileage")

            InstrumentNumberField(
                label: "Mileage",
                value: $mileageAtService,
                placeholder: "Optional",
                suffix: DistanceSettings.shared.unit.abbreviation
            )

            if mileageAtService == nil {
                Text("If left blank, current vehicle mileage will be used.")
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let warning = anchors.mileageWarning {
                SanityWarningRow(message: warning)
            }
        }

        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: "Reminder")

            VStack(spacing: Spacing.sm) {
                LabeledInstrumentToggle(
                    label: "REMIND ME NEXT TIME",
                    accessibilityLabel: "Remind me next time",
                    isOn: $isRecurring
                )

                if isRecurring {
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
            RichNotesEditor(label: "Notes", text: $notes, placeholder: "Add notes...", minHeight: 100)
        }

        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: "Attachments")
            AttachmentPicker(attachments: $pendingAttachments)
        }

        Button {
            saveService(keepOpen: true)
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "plus.square.on.square")
                    .font(.system(size: 14, weight: .medium))
                Text("SAVE & ADD ANOTHER")
                    .font(.brutalistLabel)
                    .tracking(1)
            }
            .foregroundStyle(isFormValid ? Theme.accent : Theme.textTertiary)
            .frame(maxWidth: .infinity)
            .frame(height: Theme.buttonHeight)
            .background(Theme.surfaceInstrument)
            .overlay(
                Rectangle()
                    .strokeBorder(
                        (isFormValid ? Theme.accent : Theme.gridLine).opacity(0.5),
                        lineWidth: Theme.borderWidth
                    )
            )
        }
        .disabled(!isFormValid)
        .padding(.top, Spacing.sm)
        .accessibilityLabel("Save and add another")
    }

    @ViewBuilder
    private var scheduleModeFields: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: "Next Due")

            VStack(spacing: Spacing.md) {
                LabeledInstrumentToggle(
                    label: "SET DUE DATE",
                    accessibilityLabel: "Set due date",
                    isOn: $hasCustomDate
                )

                if hasCustomDate {
                    InstrumentDatePicker(label: "Due Date", date: $dueDate)
                }

                InstrumentNumberField(
                    label: "Due Mileage",
                    value: $nextDueMileage,
                    placeholder: "Optional",
                    suffix: DistanceSettings.shared.unit.abbreviation
                )

                if let nextDueDate, let nextDueMileage {
                    whicheverFirstSummary(date: nextDueDate, mileage: nextDueMileage, pace: vehicle.dailyMilesPace)
                }
            }
        }

        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: "Repeats")

            VStack(spacing: Spacing.md) {
                LabeledInstrumentToggle(
                    label: "REPEAT AFTER COMPLETION",
                    accessibilityLabel: "Repeat after completion",
                    isOn: $isRecurring
                )

                if isRecurring {
                    InstrumentNumberField(label: "Every", value: $intervalMonths, placeholder: "6", suffix: "months")
                    InstrumentNumberField(label: "Or Every", value: $intervalMiles, placeholder: "5000", suffix: "miles")
                }
            }
        }

        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: "Notes")
            RichNotesEditor(label: "Notes", text: $notes, placeholder: "Add notes...", minHeight: 100)
        }
    }

    private func whicheverFirstSummary(date: Date, mileage: Int, pace: Double?) -> some View {
        let dateLeads = dateTriggerLeads(date: date, mileage: mileage, pace: pace)
        let dateText = Formatters.mediumDate.string(from: date)
        let mileageText = Formatters.mileage(mileage)

        return VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("WHICHEVER COMES FIRST")
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1)

            HStack(spacing: Spacing.sm) {
                triggerCell(text: dateText, isLeading: dateLeads)
                Text("OR")
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
                triggerCell(text: mileageText, isLeading: !dateLeads)
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surfaceInstrument)
        .brutalistBorder()
    }

    private func triggerCell(text: String, isLeading: Bool) -> some View {
        HStack(spacing: Spacing.xs) {
            if isLeading {
                Text("◆")
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.accent)
            }
            Text(text)
                .font(.brutalistBody)
                .foregroundStyle(isLeading ? Theme.accent : Theme.textSecondary)
        }
    }

    /// Returns true if the date trigger fires before the mileage trigger.
    /// When pace is unavailable, the date is treated as leading — the user
    /// still sees both values side-by-side, so the visual emphasis simply
    /// defaults to the explicit calendar trigger.
    private func dateTriggerLeads(date: Date, mileage: Int, pace: Double?) -> Bool {
        guard let pace, pace > 0 else { return true }
        let milesRemaining = max(mileage - vehicle.currentMileage, 0)
        let daysUntilMileage = Int((Double(milesRemaining) / pace).rounded())
        let daysUntilDate = Calendar.current.dateComponents([.day], from: Date.now, to: date).day ?? Int.max
        return daysUntilDate <= daysUntilMileage
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
