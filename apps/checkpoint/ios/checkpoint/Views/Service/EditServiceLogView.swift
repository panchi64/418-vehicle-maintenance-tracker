import SwiftUI
import SwiftData

/// Full-fidelity edit form for an existing ServiceLog. Mirrors the Record
/// Service field set (date, cost, category, mileage, notes, attachments)
/// so users editing a past entry don't see a different-shaped form.
struct EditServiceLogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query private var allServiceLogs: [ServiceLog]

    @Bindable var log: ServiceLog

    @State private var performedDate: Date = Date()
    @State private var mileageAtService: Int? = nil
    @State private var cost: String = ""
    @State private var costError: String?
    @State private var costCategory: CostCategory = .maintenance
    @State private var notes: String = ""
    @State private var pendingAttachments: [AttachmentPicker.AttachmentData] = []
    @State private var attachmentForDetail: Document?
    @State private var alsoMoveNextReminder = false

    // Loaded originals, for change-transparency hints (G8) and gating the
    // "also move next reminder" toggle to real date/mileage edits.
    @State private var loadedPerformedDate: Date = Date()
    @State private var loadedMileageAtService: Int? = nil

    // Fixed for the sheet's lifetime — computed once in loadFromLog().
    @State private var adjacentBefore: ServiceLog?
    @State private var adjacentAfter: ServiceLog?
    @State private var isMostRecentLogOfRecurringService = false

    private var serviceName: String { log.service?.name ?? "" }

    private var anchors: ServiceFormAnchors? {
        guard let vehicle = log.vehicle else { return nil }
        return ServiceFormAnchors(
            vehicle: vehicle,
            logs: allServiceLogs,
            serviceName: serviceName,
            performedDate: performedDate,
            enteredMileage: mileageAtService,
            enteredCostString: cost,
            excludingLogID: log.id
        )
    }

    /// Computed once in `loadFromLog()` — the neighbor logs can't change
    /// while the edit sheet is open, and re-sorting every log on each
    /// keystroke-driven render would be wasted work.
    private var adjacentLogs: (before: ServiceLog?, after: ServiceLog?) {
        (adjacentBefore, adjacentAfter)
    }

    private func logSummary(_ log: ServiceLog) -> String {
        "\(Formatters.mileage(log.mileageAtService)) (\(Formatters.shortDate.string(from: log.performedDate)))"
    }

    /// Omits whichever half doesn't exist — the earliest/latest log for a
    /// vehicle only has one neighbor (R5).
    private var contextLine: String? {
        switch adjacentLogs {
        case let (before?, after?):
            return L10n.editBetweenLogs(logSummary(before), logSummary(after))
        case let (before?, nil):
            return L10n.editSinceLog(logSummary(before))
        case let (nil, after?):
            return L10n.editBeforeLog(logSummary(after))
        case (nil, nil):
            return nil
        }
    }

    /// A cleared mileage field keeps the log's stored mileage at save, so it
    /// counts as "unchanged" for the toggle, the impact preview, and the
    /// reminder recalculation alike.
    private var effectiveMileage: Int? {
        mileageAtService ?? loadedMileageAtService
    }

    private var dateOrMileageChanged: Bool {
        performedDate != loadedPerformedDate || effectiveMileage != loadedMileageAtService
    }

    private var showAlsoMoveReminderToggle: Bool {
        dateOrMileageChanged && isMostRecentLogOfRecurringService
    }

    private var currentServiceSchedule: ReminderImpactCalculator.Schedule {
        ReminderImpactCalculator.Schedule(dueDate: log.service?.dueDate, dueMileage: log.service?.dueMileage)
    }

    /// Mirrors `Service.recalculateDueDates`: always interval-derived from
    /// this log's (edited) date/mileage, no explicit override.
    private var proposedServiceSchedule: ReminderImpactCalculator.Schedule {
        guard let service = log.service, let mileage = effectiveMileage else { return currentServiceSchedule }
        return ReminderImpactCalculator.projected(
            intervalMonths: service.intervalMonths,
            intervalMiles: service.intervalMiles,
            anchorDate: performedDate,
            anchorMileage: mileage,
            explicitDueDate: nil,
            explicitDueMileage: nil
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphericBackground()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        contextHeader

                        if let contextLine {
                            Text(contextLine)
                                .font(.brutalistSecondary)
                                .foregroundStyle(Theme.textTertiary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            InstrumentSectionHeader(title: L10n.formDatePerformed)
                            InstrumentDatePicker(label: L10n.formDatePerformed, date: $performedDate)

                            if performedDate != loadedPerformedDate {
                                OriginalValueHint(text: L10n.editWas(Formatters.shortDate.string(from: loadedPerformedDate)))
                            }
                        }

                        costSection

                        mileageSection

                        if showAlsoMoveReminderToggle {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                LabeledInstrumentToggle(
                                    label: L10n.editAlsoMoveReminder.uppercased(),
                                    accessibilityLabel: L10n.editAlsoMoveReminder,
                                    isOn: $alsoMoveNextReminder
                                )

                                if alsoMoveNextReminder,
                                   let impact = ReminderImpactCalculator.impact(current: currentServiceSchedule, proposed: proposedServiceSchedule) {
                                    ReminderImpactRow(impact: impact)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            InstrumentSectionHeader(title: L10n.formNotes)
                            RichNotesEditor(label: L10n.formNotes, text: $notes, placeholder: L10n.formNotesPlaceholder, minHeight: 100)
                        }

                        if !(log.attachments ?? []).isEmpty {
                            AttachmentSection(
                                attachments: log.attachments ?? [],
                                onSelect: { attachmentForDetail = $0 }
                            )
                        }

                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            InstrumentSectionHeader(title: L10n.formAddAttachments)
                            AttachmentPicker(attachments: $pendingAttachments)
                        }
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
                    isPrimaryEnabled: true,
                    onPrimary: { saveChanges() }
                )
            }
            .trackScreen(.editServiceLog)
            .onAppear(perform: loadFromLog)
            .sheet(item: $attachmentForDetail) { document in
                DocumentDetailView(document: document)
                    .environment(appState)
            }
        }
    }

    private var contextHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(L10n.formEditingTag)
                .textCase(.uppercase)
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1.5)

            Text(log.service?.name ?? L10n.serviceFallbackName)
                .font(.brutalistTitle)
                .foregroundStyle(Theme.textPrimary)

            if let vehicle = log.vehicle {
                Text("\(vehicle.displayName) · \(Formatters.mediumDate.string(from: log.performedDate))".uppercased())
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textSecondary)
                    .tracking(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(Theme.surfaceInstrument)
        .brutalistBorder()
    }

    @ViewBuilder
    private var costSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: L10n.formCost)

            VStack(spacing: Spacing.md) {
                InstrumentTextField(
                    label: L10n.formAmount,
                    text: $cost,
                    placeholder: "0.00",
                    keyboardType: .decimalPad
                )
                .onChange(of: cost) { _, newValue in
                    cost = CostValidation.filterCostInput(newValue)
                    costError = CostValidation.validate(cost)
                }

                if let hint = anchors?.priorCostHint {
                    Text(hint)
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let warning = anchors?.costWarning {
                    SanityWarningRow(message: warning)
                }

                if let costError {
                    ErrorMessageRow(message: costError) {
                        self.costError = nil
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(L10n.formCategory)
                        .textCase(.uppercase)
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
    }

    @ViewBuilder
    private var mileageSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: L10n.formMileage)

            InstrumentNumberField(
                label: L10n.formMileage,
                value: $mileageAtService,
                placeholder: L10n.formOptionalTag,
                suffix: DistanceSettings.shared.unit.abbreviation
            )

            if mileageAtService != loadedMileageAtService {
                OriginalValueHint(text: L10n.editWas(OriginalValueHint.value(forMileage: loadedMileageAtService)))
            }

            if let warning = anchors?.mileageWarning {
                SanityWarningRow(message: warning)
            }
        }
    }

    private func loadFromLog() {
        performedDate = log.performedDate
        mileageAtService = log.mileageAtService
        cost = log.cost.map { NSDecimalNumber(decimal: $0).stringValue } ?? ""
        costCategory = log.costCategory ?? .maintenance
        notes = log.notes ?? ""

        loadedPerformedDate = log.performedDate
        loadedMileageAtService = log.mileageAtService

        if let vehicle = log.vehicle {
            let vehicleLogs: [ServiceLog] = allServiceLogs.forVehicleNewestFirst(vehicle).reversed()
            if let index = vehicleLogs.firstIndex(where: { $0.id == log.id }) {
                adjacentBefore = index > 0 ? vehicleLogs[index - 1] : nil
                adjacentAfter = index < vehicleLogs.count - 1 ? vehicleLogs[index + 1] : nil
            }
        }

        // Only the most recent log of a recurring service can move that
        // service's next reminder — earlier logs are historical record-keeping.
        if let service = log.service, service.hasIntervalPolicy {
            let newest = (service.logs ?? []).max { $0.performedDate < $1.performedDate }
            isMostRecentLogOfRecurringService = newest?.id == log.id
        }
    }

    private func saveChanges() {
        let originalNotes = log.notes ?? ""
        let newNotes = notes.isEmpty ? nil : notes
        let notesChanged = (newNotes ?? "") != originalNotes

        HapticService.shared.success()
        AnalyticsService.shared.capture(.serviceLogEdited(
            notesChanged: notesChanged,
            attachmentsAdded: pendingAttachments.count
        ))

        log.performedDate = performedDate
        if let mileage = mileageAtService {
            log.mileageAtService = mileage
        }
        let costDecimal = Decimal(string: cost)
        log.cost = costDecimal
        log.costCategory = costDecimal != nil ? costCategory : nil
        log.notes = newNotes

        if alsoMoveNextReminder, showAlsoMoveReminderToggle,
           let service = log.service, let mileage = effectiveMileage {
            service.recalculateDueDates(performedDate: performedDate, mileage: mileage)
            if let vehicle = log.vehicle {
                ServiceNotificationScheduler.rescheduleNotifications(for: vehicle)
            }
        }

        for attachmentData in pendingAttachments {
            let thumbnailData = ServiceAttachment.generateThumbnailData(
                from: attachmentData.data,
                mimeType: attachmentData.mimeType
            )
            let attachment = ServiceAttachment(
                serviceLog: log,
                data: attachmentData.data,
                thumbnailData: thumbnailData,
                fileName: attachmentData.fileName,
                mimeType: attachmentData.mimeType,
                extractedText: attachmentData.extractedText
            )
            modelContext.insert(attachment)
        }

        ToastService.shared.show(L10n.toastServiceLogUpdated, icon: "checkmark", style: .success)
        dismiss()
    }
}

#Preview {
    @Previewable @State var log = ServiceLog(
        service: Service(name: "Oil Change", dueDate: nil),
        vehicle: Vehicle(
            name: "Test Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 32500
        ),
        performedDate: Date.now,
        mileageAtService: 32000,
        cost: 45.99,
        costCategory: .maintenance,
        notes: "Synthetic 0W-20 oil change at local shop."
    )

    EditServiceLogView(log: log)
        .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self, ServiceAttachment.self], inMemory: true)
        .environment(AppState())
        .preferredColorScheme(.dark)
}
