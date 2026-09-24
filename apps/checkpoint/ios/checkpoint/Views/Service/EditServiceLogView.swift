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

    // Loaded originals, for change-transparency hints (F6) and gating the
    // "also move next reminder" toggle to real date/mileage edits.
    @State private var loadedPerformedDate: Date = Date()
    @State private var loadedMileageAtService: Int? = nil

    // Fixed for the sheet's lifetime — computed once in loadFromLog().
    @State private var adjacentBefore: ServiceLog?
    @State private var adjacentAfter: ServiceLog?
    /// Logs on this occasion (this one, or its whole visit) that anchor their
    /// service's next reminder. This log first when it is one of them.
    @State private var reminderAnchorLogs: [ServiceLog] = []
    @State private var occasionServiceCount = 1

    private var serviceName: String { log.service?.name ?? "" }

    /// Set when this log was completed as part of an un-itemized visit — the
    /// cost field then edits the visit's shared total.
    private var sharedCostVisit: ServiceVisit? { log.sharedCostVisit }

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
    /// vehicle only has one neighbor (F8).
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
        dateOrMileageChanged && !reminderAnchorLogs.isEmpty
    }

    /// The service whose reminder the impact preview shows — this log's own
    /// when it anchors one, else the first visit sibling that does.
    private var previewService: Service? { reminderAnchorLogs.first?.service }

    private var currentServiceSchedule: ReminderImpactCalculator.Schedule {
        ReminderImpactCalculator.Schedule(dueDate: previewService?.dueDate, dueMileage: previewService?.dueMileage)
    }

    /// Mirrors `Service.recalculateDueDates`: always interval-derived from
    /// this log's (edited) date/mileage, no explicit override.
    private var proposedServiceSchedule: ReminderImpactCalculator.Schedule {
        guard let service = previewService, let mileage = effectiveMileage else { return currentServiceSchedule }
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
                            InstrumentDatePicker(label: nil, date: $performedDate)

                            if performedDate != loadedPerformedDate {
                                OriginalValueHint(text: L10n.editWas(Formatters.shortDate.string(from: loadedPerformedDate)))
                            }
                        }

                        costSection

                        mileageSection

                        if dateOrMileageChanged, occasionServiceCount > 1 {
                            FormAdvisory.info(L10n.editVisitOccasionHint(occasionServiceCount))
                        }

                        if showAlsoMoveReminderToggle {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                LabeledInstrumentToggle(
                                    label: L10n.editAlsoMoveReminder,
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
                            RichNotesEditor(label: nil, text: $notes, placeholder: L10n.formNotesPlaceholder, minHeight: 100)
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
            .keyboardDismissToolbar()
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
                    label: sharedCostVisit != nil ? L10n.editVisitTotal : L10n.formAmount,
                    text: $cost,
                    placeholder: "0.00",
                    keyboardType: .decimalPad
                )
                .onChange(of: cost) { _, newValue in
                    cost = CostValidation.filterCostInput(newValue)
                    costError = CostValidation.validate(cost)
                }

                // A visit total isn't comparable to this service's past
                // single-service costs, so the price anchors give way to a
                // note on what the number covers.
                if let visit = sharedCostVisit {
                    if visit.serviceCount > 1 {
                        FormAdvisory.info(L10n.editVisitTotalHint(visit.serviceCount))
                    }
                } else if let hint = anchors?.priorCostHint {
                    FormAdvisory.info(hint)
                }

                if sharedCostVisit == nil, let warning = anchors?.costWarning {
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
                label: nil,
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
        cost = log.editableCost.map { NSDecimalNumber(decimal: $0).stringValue } ?? ""
        costCategory = log.editableCostCategory ?? .maintenance
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

        // A date/mileage edit moves every service of a visit, so any of them
        // that anchors its service's next reminder can have that reminder moved.
        let occasionLogs = log.occasionLogs
        occasionServiceCount = occasionLogs.count
        let anchors = occasionLogs.filter(\.anchorsNextReminder)
        reminderAnchorLogs = anchors.filter { $0.id == log.id } + anchors.filter { $0.id != log.id }
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

        log.applyEditedOccasion(performedDate: performedDate, mileage: mileageAtService)
        log.applyEditedCost(Decimal(string: cost), category: costCategory)
        log.notes = newNotes

        if alsoMoveNextReminder, showAlsoMoveReminderToggle, let mileage = effectiveMileage {
            for anchor in reminderAnchorLogs {
                anchor.service?.recalculateDueDates(performedDate: performedDate, mileage: mileage)
            }
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
