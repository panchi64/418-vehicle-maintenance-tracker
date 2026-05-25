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

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphericBackground()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        contextHeader

                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            InstrumentSectionHeader(title: "Date Performed")
                            InstrumentDatePicker(label: "Date Performed", date: $performedDate)
                        }

                        costSection

                        mileageSection

                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            InstrumentSectionHeader(title: "Notes")
                            RichNotesEditor(label: "Notes", text: $notes, placeholder: "Add notes...", minHeight: 100)
                        }

                        if !(log.attachments ?? []).isEmpty {
                            AttachmentSection(
                                attachments: log.attachments ?? [],
                                onSelect: { attachmentForDetail = $0 }
                            )
                        }

                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            InstrumentSectionHeader(title: "Add Attachments")
                            AttachmentPicker(attachments: $pendingAttachments)
                        }
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
                    Button("Cancel") { dismiss() }
                        .toolbarButtonStyle()
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                        .toolbarButtonStyle()
                }
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
            Text("EDITING")
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1.5)

            Text(log.service?.name ?? "Service")
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
    }

    @ViewBuilder
    private var mileageSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: "Mileage")

            InstrumentNumberField(
                label: "Mileage",
                value: $mileageAtService,
                placeholder: "Optional",
                suffix: DistanceSettings.shared.unit.abbreviation
            )

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
