import SwiftUI
import SwiftData

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

    @State var model: AddServiceFormModel

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
        _model = State(initialValue: AddServiceFormModel(vehicle: vehicle, initialMode: initialMode))
    }

    var lastLogForVehicle: ServiceLog? {
        serviceLogs.forVehicleNewestFirst(vehicle).first
    }

    /// Best history match for the current service-type selection. Falls back
    /// to the most recent log on the vehicle so the form still has something
    /// to anchor suggestions on before a type is chosen.
    var lastLogForServiceType: ServiceLog? {
        guard !model.serviceName.isEmpty else { return lastLogForVehicle }
        return serviceLogs.mostRecent(serviceName: model.serviceName, vehicle: vehicle) ?? lastLogForVehicle
    }

    var quickChips: [PresetData] {
        serviceLogs.topPresetChips(for: vehicle, from: model.presets, limit: 4)
    }

    private var anchors: ServiceFormAnchors {
        ServiceFormAnchors(
            vehicle: vehicle,
            logs: serviceLogs,
            serviceName: model.serviceName,
            performedDate: model.performedDate,
            enteredMileage: model.mileageAtService,
            enteredCostString: model.cost
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphericBackground()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        InstrumentSegmentedControl(
                            options: ServiceMode.allCases,
                            selection: $model.mode
                        ) { option in
                            option.rawValue
                        }

                        if model.mode == .record, let last = lastLogForVehicle {
                            UseLastEntryButton(
                                serviceName: last.service?.name ?? "previous service",
                                performedDate: last.performedDate,
                                action: { model.useLastEntry(from: last) }
                            )
                        } else if model.mode == .remind, let last = lastLogForServiceType {
                            UseLastEntryButton(
                                serviceName: last.service?.name ?? "previous service",
                                performedDate: last.performedDate,
                                action: { model.useLastEntryForRemind(from: last) }
                            )
                        }

                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            InstrumentSectionHeader(title: "Service Type")

                            if model.selectedPreset == nil, !quickChips.isEmpty {
                                QuickServiceChipsRow(chips: quickChips) { preset in
                                    model.selectedPreset = preset
                                    HapticService.shared.selectionChanged()
                                }
                            }

                            ServiceTypePicker(
                                selectedPreset: $model.selectedPreset,
                                customServiceName: $model.customServiceName
                            )
                        }

                        if model.mode == .record {
                            RecordServiceFields(
                                model: model,
                                anchors: anchors,
                                onSaveAndAddAnother: { saveService(keepOpen: true) }
                            )
                        } else {
                            RemindServiceFields(model: model, lastLog: lastLogForServiceType)
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
                        Text(model.mode == .record ? "RECORD SERVICE" : "SET REMINDER")
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.textTertiary)
                            .tracking(1)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(vehicle.displayName), \(model.mode == .record ? "Record Service" : "Set Reminder")")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveService() }
                        .toolbarButtonStyle(isDisabled: !model.isFormValid)
                        .disabled(!model.isFormValid)
                }
            }
            .onChange(of: model.selectedPreset) { _, newPreset in
                guard let preset = newPreset else { return }
                if let months = preset.defaultIntervalMonths { model.intervalMonths = months }
                if let miles = preset.defaultIntervalMiles { model.intervalMiles = miles }
                if Service.hasIntervalPolicy(
                    intervalMonths: preset.defaultIntervalMonths,
                    intervalMiles: preset.defaultIntervalMiles
                ) {
                    model.isRecurring = true
                }
            }
            .onChange(of: model.mode) { _, _ in
                // Per-completion notes and per-schedule notes are different things;
                // carrying typed text across the segmented control is surprising.
                model.notes = ""
            }
            .trackScreen(.addService)
            .onAppear {
                if model.presets.isEmpty {
                    model.presets = PresetDataService.shared.loadPresets()
                }
                if model.mileageAtService == nil {
                    model.mileageAtService = vehicle.currentMileage
                }
                if let prefill = seasonalPrefill { model.applySeasonalPrefill(prefill) }
                if let prefill = postRecordPrefill { model.applyPostRecordPrefill(prefill) }
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

    AddServiceView(vehicle: vehicle)
        .environment(AppState())
        .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self], inMemory: true)
}
