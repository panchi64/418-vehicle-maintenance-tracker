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
    var postRecordPrefill: PostRecordPrefill?
    var initialMode: ServiceMode = .record

    @State var mode: ServiceMode

    init(
        vehicle: Vehicle,
        seasonalPrefill: SeasonalPrefill? = nil,
        postRecordPrefill: PostRecordPrefill? = nil,
        initialMode: ServiceMode = .record
    ) {
        self.vehicle = vehicle
        self.seasonalPrefill = seasonalPrefill
        self.postRecordPrefill = postRecordPrefill
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

    /// Best history match for the current service-type selection. Falls back
    /// to the most recent log on the vehicle so the form still has something
    /// to anchor suggestions on before a type is chosen.
    var lastLogForServiceType: ServiceLog? {
        guard !serviceName.isEmpty else { return lastLogForVehicle }
        return serviceLogs.mostRecent(serviceName: serviceName, vehicle: vehicle) ?? lastLogForVehicle
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

    private func applySeasonalPrefill(_ prefill: SeasonalPrefill) {
        mode = .remind
        customServiceName = prefill.serviceName
        hasCustomDate = true
        dueDate = prefill.dueDate
        intervalMonths = prefill.intervalMonths
        isRecurring = true
    }

    private func applyPostRecordPrefill(_ prefill: PostRecordPrefill) {
        mode = .remind
        customServiceName = prefill.serviceName
        intervalMonths = prefill.intervalMonths
        intervalMiles = prefill.intervalMiles
        isRecurring = Service.hasIntervalPolicy(
            intervalMonths: prefill.intervalMonths,
            intervalMiles: prefill.intervalMiles
        )
        if let months = prefill.intervalMonths, months > 0,
           let projected = Calendar.current.date(byAdding: .month, value: months, to: prefill.performedDate) {
            hasCustomDate = true
            dueDate = projected
        }
        if let miles = prefill.intervalMiles, miles > 0 {
            nextDueMileage = prefill.performedMileage + miles
        }
    }

    /// Remind-mode counterpart to `useLastEntry()`. Diverges by projecting a
    /// next-due date/mileage from the historic anchor + interval policy, and
    /// by skipping cost/notes (which only matter when recording a completion).
    /// The service name is preserved if the user already has one in flight.
    func useLastEntryForRemind() {
        guard let log = lastLogForServiceType else { return }
        let template = LoggedServiceTemplate(from: log)
        if selectedPreset == nil && customServiceName.isEmpty {
            customServiceName = template.serviceName
        }
        intervalMonths = template.intervalMonths
        intervalMiles = template.intervalMiles
        isRecurring = template.hasRecurringIntervals
        if let interval = template.intervalMiles, interval > 0 {
            nextDueMileage = log.mileageAtService + interval
        }
        if let months = template.intervalMonths, months > 0,
           let suggested = Calendar.current.date(byAdding: .month, value: months, to: log.performedDate) {
            hasCustomDate = true
            dueDate = suggested
        }
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
                        } else if mode == .remind, let last = lastLogForServiceType {
                            UseLastEntryButton(
                                serviceName: last.service?.name ?? "previous service",
                                performedDate: last.performedDate,
                                action: useLastEntryForRemind
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
            .onChange(of: mode) { _, _ in
                // Per-completion notes and per-schedule notes are different things;
                // carrying typed text across the segmented control is surprising.
                notes = ""
            }
            .trackScreen(.addService)
            .onAppear {
                if presets.isEmpty {
                    presets = PresetDataService.shared.loadPresets()
                }
                if mileageAtService == nil {
                    mileageAtService = vehicle.currentMileage
                }
                if let prefill = seasonalPrefill { applySeasonalPrefill(prefill) }
                if let prefill = postRecordPrefill { applyPostRecordPrefill(prefill) }
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
        // Resolve history once per render; downstream suggestions read from
        // the captured log instead of re-running the lookup.
        let last = lastLogForServiceType
        let policyMonths = (last?.service?.intervalMonths).flatMap { $0 > 0 ? $0 : nil }
        let policyMiles = (last?.service?.intervalMiles).flatMap { $0 > 0 ? $0 : nil }
        let projectedDueMileage = last.flatMap { log in policyMiles.map { log.mileageAtService + $0 } }

        if let last {
            Text("Last done: \(Formatters.shortDate.string(from: last.performedDate)) · \(Formatters.mileage(last.mileageAtService))")
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }

        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: "Next Due")

            VStack(spacing: Spacing.md) {
                ChipRow(items: fuzzyDateChips, label: \.label) { chip in
                    hasCustomDate = true
                    dueDate = chip.date
                    HapticService.shared.selectionChanged()
                }

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

                ChipRow(items: mileageOffsetChips, label: \.label) { chip in
                    nextDueMileage = vehicle.currentMileage + chip.miles
                    HapticService.shared.selectionChanged()
                }

                if nextDueMileage == nil, let suggested = projectedDueMileage {
                    SuggestedValueRow(label: "Suggest \(Formatters.mileage(suggested))") {
                        nextDueMileage = suggested
                    }
                }

                if let nextDueDate, nextDueDate < Date.now {
                    Text("This date is in the past — will be marked overdue.")
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let countdown = countdownText(date: nextDueDate, mileage: nextDueMileage) {
                    Text(countdown.text)
                        .font(.brutalistSecondary)
                        .foregroundStyle(countdown.isOverdue ? Theme.statusOverdue : Theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

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
                    ChipRow(items: Self.monthIntervalChips, label: \.label) { chip in
                        intervalMonths = chip.months
                        HapticService.shared.selectionChanged()
                    }

                    InstrumentNumberField(label: "Every", value: $intervalMonths, placeholder: "6", suffix: "months")
                    if intervalMonths == nil, let suggested = policyMonths {
                        SuggestedValueRow(label: "Suggest \(suggested) months") {
                            intervalMonths = suggested
                        }
                    }

                    ChipRow(items: mileageIntervalChips, label: \.label) { chip in
                        intervalMiles = chip.miles
                        HapticService.shared.selectionChanged()
                    }

                    InstrumentNumberField(label: "Or Every", value: $intervalMiles, placeholder: "5000", suffix: "miles")
                    if intervalMiles == nil, let suggested = policyMiles {
                        SuggestedValueRow(label: "Suggest \(Formatters.mileage(suggested))") {
                            intervalMiles = suggested
                        }
                    }

                    if let preview = recurrencePolicyPreview {
                        Text(preview)
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .foregroundStyle(Theme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
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

    /// Time-dependent — recomputed each render so dates anchor to "now."
    private var fuzzyDateChips: [FuzzyDateChip] {
        let cal = Calendar.current
        let now = Date.now
        return [
            FuzzyDateChip(label: "Next Week", date: cal.date(byAdding: .day, value: 7, to: now) ?? now),
            FuzzyDateChip(label: "~1 mo", date: cal.date(byAdding: .month, value: 1, to: now) ?? now),
            FuzzyDateChip(label: "~3 mo", date: cal.date(byAdding: .month, value: 3, to: now) ?? now),
            FuzzyDateChip(label: "~6 mo", date: cal.date(byAdding: .month, value: 6, to: now) ?? now)
        ]
    }

    private static let monthIntervalChips: [MonthIntervalChip] = [
        MonthIntervalChip(months: 3, label: "3 mo"),
        MonthIntervalChip(months: 6, label: "6 mo"),
        MonthIntervalChip(months: 12, label: "1 yr"),
        MonthIntervalChip(months: 24, label: "2 yr")
    ]

    /// Recurrence-cadence chips. Scale matches typical maintenance intervals
    /// for the user's unit (e.g. oil change ~5k mi vs ~8–10k km).
    private var mileageIntervalChips: [MileageChip] {
        switch DistanceSettings.shared.unit {
        case .miles:
            return [
                MileageChip(miles: 3000, label: "+3k"),
                MileageChip(miles: 5000, label: "+5k"),
                MileageChip(miles: 7500, label: "+7.5k"),
                MileageChip(miles: 10000, label: "+10k")
            ]
        case .kilometers:
            return [
                MileageChip(miles: 5000, label: "+5k"),
                MileageChip(miles: 8000, label: "+8k"),
                MileageChip(miles: 12000, label: "+12k"),
                MileageChip(miles: 16000, label: "+16k")
            ]
        }
    }

    /// One-shot offsets from current mileage. Smaller values than intervals
    /// because users often schedule "the next inspection" not a recurring policy.
    private var mileageOffsetChips: [MileageChip] {
        switch DistanceSettings.shared.unit {
        case .miles:
            return [
                MileageChip(miles: 1000, label: "+1k"),
                MileageChip(miles: 3000, label: "+3k"),
                MileageChip(miles: 5000, label: "+5k"),
                MileageChip(miles: 10000, label: "+10k")
            ]
        case .kilometers:
            return [
                MileageChip(miles: 1500, label: "+1.5k"),
                MileageChip(miles: 5000, label: "+5k"),
                MileageChip(miles: 8000, label: "+8k"),
                MileageChip(miles: 16000, label: "+16k")
            ]
        }
    }

    private var recurrencePolicyPreview: String? {
        var parts: [String] = []
        if let months = intervalMonths, months > 0 {
            parts.append(months == 1 ? "every month" : "every \(months) months")
        }
        if let miles = intervalMiles, miles > 0 {
            parts.append("every \(Formatters.mileage(miles))")
        }
        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: " or ")
    }

    /// Returns nil when neither trigger is set so the strip doesn't render.
    private func countdownText(date: Date?, mileage: Int?) -> (text: String, isOverdue: Bool)? {
        var parts: [String] = []
        var isOverdue = false

        if let date {
            let days = Calendar.current.dateComponents([.day], from: Date.now, to: date).day ?? 0
            if days < 0 {
                parts.append("\(-days) days overdue")
                isOverdue = true
            } else {
                parts.append("~\(days) days")
            }
        }

        if let mileage {
            let delta = mileage - vehicle.currentMileage
            if delta < 0 {
                parts.append("\(Formatters.mileage(-delta)) past")
                isOverdue = true
            } else {
                parts.append("~\(Formatters.mileage(delta)) ahead")
            }
        }

        guard !parts.isEmpty else { return nil }
        return (parts.joined(separator: " · "), isOverdue)
    }
}

// MARK: - Chip Data

private struct FuzzyDateChip: Hashable {
    let label: String
    let date: Date
}

private struct MonthIntervalChip: Hashable {
    let months: Int
    let label: String
}

/// Used for both recurrence-cadence chips and one-shot offset-from-current
/// chips — the shape is identical; the meaning is set by the call site.
private struct MileageChip: Hashable {
    let miles: Int
    let label: String
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
