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
    case log = "Log"
    case schedule = "Schedule"
}

struct AddServiceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var services: [Service]

    let vehicle: Vehicle
    var seasonalPrefill: SeasonalPrefill?

    // Mode selection
    @State private var mode: ServiceMode = .log

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
    @State private var pendingAttachments: [AttachmentPicker.AttachmentData] = []

    // Schedule mode fields
    @State private var dueDate: Date = Date().addingTimeInterval(86400 * 30) // 30 days from now
    @State private var dueMileage: Int? = nil
    @State private var intervalMonths: Int? = nil
    @State private var intervalMiles: Int? = nil

    var serviceName: String {
        selectedPreset?.name ?? customServiceName
    }

    var isFormValid: Bool {
        !serviceName.isEmpty && (mode == .log ? mileageAtService != nil : true)
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
                        if mode == .log {
                            logModeFields
                        } else {
                            scheduleModeFields
                        }
                    }
                    .padding(Spacing.screenHorizontal)
                    .padding(.bottom, Spacing.xxl)
                }
            }
            .navigationTitle(mode == .log ? "Log Service" : "Schedule Service")
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
                // Auto-fill intervals from preset
                if let preset = newPreset {
                    if let months = preset.defaultIntervalMonths {
                        intervalMonths = months
                    }
                    if let miles = preset.defaultIntervalMiles {
                        intervalMiles = miles
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
                if let prefill = seasonalPrefill {
                    mode = .schedule
                    customServiceName = prefill.serviceName
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
            InstrumentSectionHeader(title: "Service Details")

            VStack(spacing: Spacing.md) {
                InstrumentDatePicker(
                    label: "Date Performed",
                    date: $performedDate
                )

                InstrumentNumberField(
                    label: "Mileage",
                    value: $mileageAtService,
                    placeholder: "Required",
                    suffix: "mi"
                )
            }
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
        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: "Due Date")

            VStack(spacing: Spacing.md) {
                InstrumentDatePicker(
                    label: "Due Date",
                    date: $dueDate
                )

                InstrumentNumberField(
                    label: "Due Mileage",
                    value: $dueMileage,
                    placeholder: "Optional",
                    suffix: "mi"
                )
            }
        }

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
    }

    // MARK: - Save Logic

    private func saveService() {
        // Analytics
        let isPreset = selectedPreset != nil
        let category = selectedPreset?.category
        let hasInterval = (intervalMonths != nil && intervalMonths != 0) || (intervalMiles != nil && intervalMiles != 0)

        HapticService.shared.success()

        if mode == .log {
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
        if mode == .log {
            ToastService.shared.show(L10n.toastServiceAdded, icon: "checkmark", style: .success)
        } else {
            ToastService.shared.show(L10n.toastServiceScheduled, icon: "clock", style: .success)
        }
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
            intervalMonths: intervalMonths,
            intervalMiles: intervalMiles
        )
        service.vehicle = vehicle

        // Calculate next due date/mileage
        if let months = intervalMonths, months > 0 {
            service.dueDate = Calendar.current.date(byAdding: .month, value: months, to: performedDate)
        }
        if let miles = intervalMiles, miles > 0 {
            service.dueMileage = mileage + miles
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

        // Update vehicle mileage if service mileage is higher
        if mileage > vehicle.currentMileage {
            vehicle.currentMileage = mileage
        }
    }

    private func saveScheduledService() {
        let service = Service(
            name: serviceName,
            dueDate: dueDate,
            dueMileage: dueMileage,
            intervalMonths: intervalMonths,
            intervalMiles: intervalMiles
        )
        service.vehicle = vehicle
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
        .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self], inMemory: true)
}
