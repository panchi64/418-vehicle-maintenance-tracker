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
    @State var scheduleRecurring: Bool = false
    @State var pendingAttachments: [AttachmentPicker.AttachmentData] = []

    @State var hasCustomDate: Bool = false
    @State var dueDate: Date = Date()
    @State var dueMileage: Int? = nil
    @State var intervalMonths: Int? = nil
    @State var intervalMiles: Int? = nil

    @State private var presets: [PresetData] = []

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
        scheduleRecurring = template.hasRecurringIntervals
        HapticService.shared.selectionChanged()
    }

    private var nextDuePreview: String? {
        guard scheduleRecurring else { return nil }
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
                guard let preset = newPreset else { return }
                if let months = preset.defaultIntervalMonths { intervalMonths = months }
                if let miles = preset.defaultIntervalMiles { intervalMiles = miles }
                if mode == .record {
                    let hasIntervals = (preset.defaultIntervalMonths ?? 0) > 0 || (preset.defaultIntervalMiles ?? 0) > 0
                    if hasIntervals { scheduleRecurring = true }
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
                .brutalistBorder()

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
            InstrumentSectionHeader(title: "Repeat Interval")

            VStack(spacing: Spacing.md) {
                InstrumentNumberField(label: "Every", value: $intervalMonths, placeholder: "6", suffix: "months")
                InstrumentNumberField(label: "Or Every", value: $intervalMiles, placeholder: "5000", suffix: "miles")
            }
        }

        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: "When Is It Due?")

            VStack(spacing: Spacing.md) {
                if let months = intervalMonths, months > 0 {
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
                        .brutalistBorder()
                    }
                } else {
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
                    .brutalistBorder()

                    if hasCustomDate {
                        InstrumentDatePicker(label: "Due Date", date: $dueDate)
                    }
                }

                if let miles = intervalMiles, miles > 0 {
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
                    .brutalistBorder()
                } else {
                    InstrumentNumberField(label: "Due Mileage", value: $dueMileage, placeholder: "Optional", suffix: "mi")
                }
            }
        }

        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: "Notes")
            RichNotesEditor(label: "Notes", text: $notes, placeholder: "Add notes...", minHeight: 100)
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

    AddServiceView(vehicle: vehicle)
        .environment(AppState())
        .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self], inMemory: true)
}
