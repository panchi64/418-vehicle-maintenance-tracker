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
    @State private var draftResumeBanner: ServiceFormDraft?
    @State private var saveAndAddAnotherFlash: String?
    @State private var showServiceTypeError = false

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

    private var hasExplicitPrefill: Bool {
        seasonalPrefill != nil || postRecordPrefill != nil
    }


    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ZStack {
                    AtmosphericBackground()

                    ScrollView {
                        VStack(spacing: Spacing.lg) {
                            if let draft = draftResumeBanner {
                                DraftResumeBanner(
                                    savedAt: draft.savedAt,
                                    onResume: {
                                        model.apply(draft)
                                        draftResumeBanner = nil
                                    },
                                    onDiscard: {
                                        ServiceFormDraftStore.clear(for: vehicle.id)
                                        draftResumeBanner = nil
                                    }
                                )
                            }

                            VStack(spacing: Spacing.sm) {
                                InstrumentSegmentedControl(
                                    options: ServiceMode.allCases,
                                    selection: $model.mode
                                ) { option in
                                    option.displayName
                                }

                                HStack(spacing: 0) {
                                    ForEach(ServiceMode.allCases, id: \.self) { option in
                                        Button {
                                            model.mode = option
                                        } label: {
                                            Text(option.caption)
                                                .font(.brutalistSecondary)
                                                .foregroundStyle(model.mode == option ? Theme.textPrimary : Theme.textTertiary)
                                                .multilineTextAlignment(.center)
                                                .frame(maxWidth: .infinity)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .id("top")

                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                InstrumentSectionHeader(title: L10n.formServiceType) {
                                    Text("*")
                                        .font(.brutalistLabel)
                                        .foregroundStyle(Theme.statusOverdue)
                                }

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

                                if showServiceTypeError, model.serviceName.isEmpty {
                                    ErrorMessageRow(message: L10n.formServiceTypeRequired) {
                                        showServiceTypeError = false
                                    }
                                }
                            }
                            .id("serviceType")

                            if !model.serviceName.isEmpty, let last = lastLogForServiceType {
                                LastServiceReferenceCard(
                                    serviceName: model.serviceName,
                                    log: last,
                                    onUseValues: model.mode == .record ? {
                                        model.useLastEntry(from: last)
                                        HapticService.shared.selectionChanged()
                                    } : nil
                                )
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }

                            if model.mode == .record {
                                RecordServiceFields(model: model, anchors: anchors)
                            } else {
                                RemindServiceFields(model: model, lastLog: lastLogForServiceType)
                            }
                        }
                        .animation(.easeInOut(duration: Theme.animationMedium), value: lastLogForServiceType?.id)
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
                        Button(L10n.commonCancel) {
                            if !model.isDirty {
                                ServiceFormDraftStore.clear(for: vehicle.id)
                            }
                            dismiss()
                        }
                        .toolbarButtonStyle()
                    }
                    ToolbarItem(placement: .principal) {
                        VStack(spacing: 2) {
                            Text(vehicle.displayName)
                                .font(.brutalistBody)
                                .foregroundStyle(Theme.textPrimary)
                                .lineLimit(1)
                            Group {
                                if model.mode == .record {
                                    Text(L10n.addServiceTitleRecord)
                                } else {
                                    Text(L10n.addServiceTitleRemind)
                                }
                            }
                            .textCase(.uppercase)
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.textTertiary)
                            .tracking(1)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(vehicle.displayName), \(model.mode == .record ? L10n.addServiceTitleRecord : L10n.addServiceTitleRemind)")
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    FormActionBar(
                        primaryTitle: L10n.commonSave,
                        isPrimaryEnabled: model.isFormValid,
                        onPrimary: { saveService() },
                        onDisabledPrimaryTap: {
                            showServiceTypeError = true
                            withAnimation { proxy.scrollTo("serviceType", anchor: .top) }
                        },
                        secondaryTitle: model.mode == .record ? L10n.formSaveAndAddAnother : nil,
                        onSecondary: model.mode == .record ? {
                            saveService(keepOpen: true)
                            saveAndAddAnotherFlash = L10n.formSavedAddNext
                            withAnimation { proxy.scrollTo("top", anchor: .top) }
                        } : nil,
                        successFlash: $saveAndAddAnotherFlash
                    )
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
                .onChange(of: model.serviceName) { _, newValue in
                    if !newValue.isEmpty { showServiceTypeError = false }
                }
                .onChange(of: model.mode) { _, _ in
                    withAnimation { proxy.scrollTo("top", anchor: .top) }
                }
                .onChange(of: model.contentSnapshot) { _, _ in
                    draftResumeBanner = nil
                }
                .task(id: model.contentSnapshot) {
                    // Only real edits produce a draft — a pristine (or freshly
                    // reset) form must never overwrite a stored draft or leave
                    // a phantom one behind on swipe-dismiss.
                    guard !hasExplicitPrefill, draftResumeBanner == nil, model.isDirty else { return }
                    try? await Task.sleep(for: .seconds(0.5))
                    guard !Task.isCancelled else { return }
                    ServiceFormDraftStore.save(model.toDraft(), for: vehicle.id)
                }
                .trackScreen(.addService)
                .onAppear {
                    if model.presets.isEmpty {
                        model.presets = PresetDataService.shared.loadPresets()
                    }
                    if let prefill = seasonalPrefill { model.applySeasonalPrefill(prefill) }
                    if let prefill = postRecordPrefill { model.applyPostRecordPrefill(prefill) }
                    if !hasExplicitPrefill {
                        draftResumeBanner = ServiceFormDraftStore.load(for: vehicle.id)
                    }
                }
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
