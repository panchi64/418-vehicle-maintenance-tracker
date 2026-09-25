//
//  AddServiceView.swift
//  checkpoint
//
//  The unified service form. There is no Record/Remind mode switch.
//
//  Three ideas carry the design:
//
//  1. ONE FORM, INTENT DERIVED. The user answers "when". A past answer means
//     they are logging; a future answer means they are scheduling. They never
//     see or name those words — the sheet title and the save button state what
//     will happen. The mode switch was asking the user to classify their own
//     intent before the app would let them describe it.
//
//  2. DEFAULT-DISCLOSE WHAT MAKES IT WORK; HIDE WHAT MAKES IT COMPLETE. The
//     repeat interval is what makes a reminder fire again, so it is on the
//     default path. Notes and receipts make an entry complete, so they live in
//     depth. This was inverted: the interval sat in a collapsed drawer while a
//     raw due-mileage field sat at the top.
//
//  3. THE TAP BUDGET IS A REAL CONSTRAINT. Log an oil change with a cost in ≤6
//     taps; schedule a reminder that provably fires in ≤5.
//

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

    @State var model: AddServiceFormModel
    @State private var draftResumeBanner: ServiceFormDraft?
    @State private var saveAndAddAnotherFlash: String?
    @State private var showBlockingReason = false

    init(
        vehicle: Vehicle,
        seasonalPrefill: SeasonalPrefill? = nil,
        postRecordPrefill: PostRecordPrefill? = nil
    ) {
        self.vehicle = vehicle
        self.seasonalPrefill = seasonalPrefill
        self.postRecordPrefill = postRecordPrefill
        _model = State(initialValue: AddServiceFormModel(vehicle: vehicle))
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

    /// The tracked service this log completes instead of duplicating. Nil on
    /// the scheduling branch and for entries that stand on their own.
    var logTarget: Service? {
        guard model.isLogging else { return nil }
        return services.activeMatch(
            named: model.serviceName,
            for: vehicle,
            performedDate: model.performedDate,
            logs: serviceLogs
        )
    }

    /// What reseeds the recurrence policy. One key, one handler: separate
    /// `onChange`s for the preset, the match, and backfill raced each other
    /// over the same three fields.
    private struct ScheduleDefaultsKey: Equatable {
        let presetName: String?
        let matchID: UUID?
        let isBackfill: Bool
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

    /// The title states what will happen, which is how the derived intent
    /// becomes visible without ever asking the user to pick a mode.
    private var sheetTitle: String {
        switch model.intent {
        case .log: return L10n.addServiceTitleLog
        case .schedule: return L10n.addServiceTitleSchedule
        case nil: return L10n.addServiceTitleNeutral
        }
    }

    /// Neutral until a timing is picked. Saying "Log it" before the user has
    /// said when it happened claims an intent they have not expressed, and the
    /// button would silently change meaning under their finger.
    private var saveTitle: String {
        switch model.intent {
        case .log: return L10n.addServiceSaveLog
        case .schedule: return L10n.addServiceSaveSchedule
        case nil: return L10n.commonSave
        }
    }

    var body: some View {
        let target = logTarget
        NavigationStack {
            ScrollViewReader { proxy in
                ZStack {
                    AtmosphericBackground()

                    ScrollView {
                        // 32 between sections, against 16 between fields and 8
                        // from a header to its own content. Three unambiguous
                        // steps — at 24-vs-16 the sections did not read as
                        // separate, because a 1.5:1 ratio is not a signal.
                        VStack(alignment: .leading, spacing: Spacing.xl) {
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
                                .id("top")
                            }

                            serviceSection(completing: target)
                            whenSection

                            if model.isLogging {
                                ServiceVisitFields(model: model, anchors: anchors)
                                LoggedReminderFields(model: model)
                            }

                            if model.isScheduling {
                                ServiceReminderFields(model: model, lastLog: lastLogForServiceType)
                            }

                            if !model.serviceName.isEmpty, let last = lastLogForServiceType {
                                LastServiceReferenceCard(
                                    serviceName: model.serviceName,
                                    log: last,
                                    onUseValues: model.isLogging ? {
                                        model.useLastEntry(from: last)
                                        HapticService.shared.selectionChanged()
                                    } : nil
                                )
                                // Fade only, per AESTHETIC.md (Motion). This
                                // was `.opacity.combined(with: .move(edge:))`.
                                .transition(.opacity)
                            }

                            if model.intent != nil {
                                ServiceDepthSection(model: model)
                            }
                        }
                        .animation(.easeInOut(duration: Theme.animationMedium), value: lastLogForServiceType?.id)
                        .animation(.easeInOut(duration: Theme.animationMedium), value: model.timing)
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .padding(.top, Spacing.md)
                        .padding(.bottom, Spacing.xxl)
                    }
                }
                .keyboardDismissToolbar()
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
                            Text(sheetTitle)
                                .textCase(.uppercase)
                                .font(.brutalistLabel)
                                .foregroundStyle(Theme.textTertiary)
                                .tracking(1)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(vehicle.displayName), \(sheetTitle)")
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    FormActionBar(
                        primaryTitle: saveTitle,
                        isPrimaryEnabled: model.isFormValid,
                        onPrimary: { saveService() },
                        onDisabledPrimaryTap: {
                            showBlockingReason = true
                            withAnimation { proxy.scrollTo("serviceType", anchor: .top) }
                        },
                        secondaryTitle: model.isLogging ? L10n.formSaveAndAddAnother : nil,
                        onSecondary: model.isLogging ? {
                            saveService(keepOpen: true)
                            saveAndAddAnotherFlash = L10n.formSavedAddNext
                            withAnimation { proxy.scrollTo("serviceType", anchor: .top) }
                        } : nil,
                        successFlash: $saveAndAddAnotherFlash
                    )
                }
                .onChange(of: ScheduleDefaultsKey(
                    presetName: model.selectedPreset?.name,
                    matchID: target?.id,
                    isBackfill: model.timing?.isBackfill == true
                )) { _, _ in
                    model.applyScheduleDefaults(preset: model.selectedPreset, match: target)
                }
                .onChange(of: model.timing) { _, _ in
                    model.mileageResolution = nil
                }
                .onChange(of: model.mileageAtService) { _, _ in
                    model.mileageResolution = nil
                }
                .onChange(of: model.blockingReason) { _, newValue in
                    if newValue == nil { showBlockingReason = false }
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

    // MARK: - 1. What

    /// The section header IS this field's label, so the picker carries none.
    /// Labelling both "SERVICE" stacked two identical labels on one input.
    private func serviceSection(completing target: Service?) -> some View {
        FormSection(title: L10n.formServiceType, trailing: L10n.formRequiredTag) {
            ServiceTypePicker(
                selectedPreset: $model.selectedPreset,
                customServiceName: $model.customServiceName
            )

            // Plain chips, not outlined. These are a shortcut for the field
            // above, not a choice the form requires — eight outlined rectangles
            // made them compete with the timing control, which IS required.
            //
            // The row carries its own label. Without one it read as a second
            // input: an unlabelled strip of text directly beneath a labelled
            // field, in a form where every other line IS a field.
            if !quickChips.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(L10n.formCommon.uppercased())
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(1.5)

                    QuickServiceChipsRow(chips: quickChips, selectedName: model.serviceName) { preset in
                        model.selectedPreset = preset
                        HapticService.shared.selectionChanged()
                    }
                }
            }

            // Stated, not asked: logging a service that is already on the
            // schedule completes it, exactly as Mark Done would.
            if let target {
                FormAdvisory.info(Self.completesAdvisory(for: target, vehicle: vehicle))
            }

            if showBlockingReason, let reason = model.blockingReason {
                FormAdvisory.blocking(reason)
            }
        }
        .id("serviceType")
    }

    /// "Completes Oil Change — 400 mi overdue". Urgency is judged against the
    /// same effective mileage the Services list uses, so the two agree.
    static func completesAdvisory(for service: Service, vehicle: Vehicle) -> String {
        guard let urgency = service.urgencyText(currentMileage: vehicle.mileageEstimate.effective) else {
            return L10n.formCompletesService(service.name)
        }
        return L10n.formCompletesServiceWithStatus(service.name, urgency)
    }

    // MARK: - 2. When — the control that derives intent

    private var whenSection: some View {
        FormSection(title: L10n.formWhen, trailing: L10n.formRequiredTag) {
            FormSubgroup(title: L10n.formAlreadyDone) {
                WrappingChipRow(
                    items: ServiceTiming.pastCases,
                    label: \.displayName,
                    isSelected: { model.timing == $0 },
                    onTap: select
                )
            }

            FormSubgroup(title: L10n.formComingUp) {
                WrappingChipRow(
                    items: ServiceTiming.futureCases,
                    label: \.displayName,
                    isSelected: { model.timing == $0 },
                    onTap: select
                )
            }

            if model.timing?.needsExplicitDate == true {
                InstrumentDatePicker(
                    label: model.isLogging ? L10n.formDatePerformed : L10n.formDueDate,
                    date: $model.customDate
                )
            }
        }
    }

    private func select(_ timing: ServiceTiming) {
        model.timing = timing
        HapticService.shared.selectionChanged()
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
