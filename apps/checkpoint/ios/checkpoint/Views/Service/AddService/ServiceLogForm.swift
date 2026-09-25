//
//  ServiceLogForm.swift
//  checkpoint
//
//  The unified service form — a Decision surface.
//
//  ONE FORM, THREE DOORS (`ServiceLogFormMode`):
//    log       [+] → pick a service → Save             "Log Service"
//    complete  Mark Done on a card → Save              "Complete Service"
//    edit      a history entry → change → Save         "Edit Entry"
//  Scheduling is not a fourth door: "Not done yet" under When turns the same
//  form into "Schedule Service". Intent is derived from "when", never asked.
//
//  TAP BUDGETS (from Home):
//    Mark Next Up done            2   Mark Done → Save
//    Log an oil change today + $  4   [+] → Oil row → Cost field → Save
//    Schedule a future service    4   [+] → service row → Not done yet → Save
//  What makes those possible — DEFAULTS DO THE WORK: When = Today; the
//  odometer = the last confirmed reading; a due service picked by name is
//  completed (and the form says so); the next reminder is a readout with
//  Remind ON; "Not done yet" defaults to the service's own interval.
//
//  ORDER: Service → When → Details → Next Reminder → More details. Everything
//  that makes the entry WORK is on the default path; category, notes and
//  receipts make it COMPLETE and live under More details (Decision rule 5).
//
//  SAVE IS IN THE TOOLBAR (`formToolbar`). A tap on the dim Save scrolls to the
//  blocking field and shows why there (F2).
//

import SwiftUI
import SwiftData

struct ServiceLogForm: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Environment(AppState.self) var appState
    @Query var services: [Service]
    @Query var serviceLogs: [ServiceLog]

    let vehicle: Vehicle
    var seasonalPrefill: SeasonalPrefill?
    var postRecordPrefill: PostRecordPrefill?
    var duplicating: ServiceLog?
    /// Duplicate only: what the user entered before choosing this vehicle.
    var carryover: ServiceLogCarryover?
    /// Duplicate only, with more than one vehicle: where the entry goes.
    var vehicleChoice: ServiceLogVehicleChoice?
    /// After a successful save (Mark Done's presenter pops its detail).
    var onSaved: (() -> Void)?
    /// Edit only: asks the presenter to delete the entry once this form has
    /// dismissed. Nil hides Delete Entry.
    var onDelete: (() -> Void)?

    @State var model: ServiceLogFormModel
    @State var draftResumeBanner: ServiceFormDraft?
    @State var showBlocker = false
    @State private var attachmentForDetail: Document?
    @State var adjacentLogs: (before: ServiceLog?, after: ServiceLog?) = (nil, nil)

    init(
        vehicle: Vehicle,
        mode: ServiceLogFormMode = .log,
        seasonalPrefill: SeasonalPrefill? = nil,
        postRecordPrefill: PostRecordPrefill? = nil,
        onSaved: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil
    ) {
        self.vehicle = vehicle
        self.seasonalPrefill = seasonalPrefill
        self.postRecordPrefill = postRecordPrefill
        self.onSaved = onSaved
        self.onDelete = onDelete
        _model = State(initialValue: ServiceLogFormModel(vehicle: vehicle, mode: mode))
        let vehicleID = vehicle.id
        _services = Query(filter: #Predicate<Service> { $0.vehicle?.id == vehicleID })
        _serviceLogs = Query(
            filter: #Predicate<ServiceLog> { $0.vehicle?.id == vehicleID },
            sort: \.performedDate,
            order: .reverse
        )
    }

    /// Duplicate a history entry: same service, cost, notes and cadence,
    /// logged today — on `vehicle`, which need not be the entry's own
    /// (`DuplicateServiceLogForm`).
    init(
        duplicating log: ServiceLog,
        vehicle: Vehicle,
        carryover: ServiceLogCarryover? = nil,
        vehicleChoice: ServiceLogVehicleChoice? = nil
    ) {
        self.init(vehicle: vehicle)
        self.duplicating = log
        self.carryover = carryover
        self.vehicleChoice = vehicleChoice
    }

    /// What reseeds the recurrence policy. One key, one handler: separate
    /// `onChange`s for the preset, the match, and backfill raced each other.
    private struct ScheduleDefaultsKey: Equatable {
        let presetName: String?
        let matchID: UUID?
        let isBackfill: Bool
    }

    // MARK: - Body

    var body: some View {
        let target = logTarget
        NavigationStack {
            ScrollViewReader { proxy in
                ZStack {
                    AtmosphericBackground()

                    ScrollView {
                        VStack(alignment: .leading, spacing: Spacing.xl) {
                            if let draft = draftResumeBanner {
                                DraftResumeBanner(
                                    savedAt: draft.savedAt,
                                    onResume: {
                                        model.apply(draft)
                                        draftResumeBanner = nil
                                    },
                                    onDiscard: {
                                        clearDraft()
                                        draftResumeBanner = nil
                                    }
                                )
                            }

                            // Where the entry goes decides what it completes,
                            // so the choice sits first, on the default path.
                            if let vehicleChoice {
                                ServiceLogVehicleMenu(
                                    current: vehicle,
                                    vehicles: vehicleChoice.vehicles,
                                    onSelect: { retarget(to: $0, via: vehicleChoice) }
                                )
                            }

                            ServicePickerSection(
                                model: model,
                                services: services,
                                logs: serviceLogs,
                                completing: target,
                                contextLine: editContextLine,
                                blocker: blockerMessage(for: .service)
                            )
                            .id(ServiceLogFormModel.BlockingField.service)

                            ServiceWhenSection(model: model)

                            if model.isLogging {
                                ServiceVisitFields(
                                    model: model,
                                    anchors: anchors,
                                    blocker: blockerMessage(for: .odometer)
                                )
                                .id(ServiceLogFormModel.BlockingField.odometer)

                                if model.mode.isEdit {
                                    EditReminderImpactFields(model: model)
                                } else {
                                    LoggedReminderFields(model: model)
                                }
                            } else {
                                ServiceReminderFields(model: model, blocker: blockerMessage(for: .due))
                                    .id(ServiceLogFormModel.BlockingField.due)
                            }

                            ServiceDepthSection(model: model, onSelectAttachment: { attachmentForDetail = $0 })

                            if let onDelete {
                                DestructiveFormButton(title: L10n.logDeleteAction) {
                                    onDelete()
                                    dismiss()
                                }
                            }
                        }
                        .animation(.easeInOut(duration: Theme.animationMedium), value: model.timing)
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .padding(.top, Spacing.md)
                        .padding(.bottom, Spacing.xxl)
                    }
                }
                .keyboardDismissToolbar()
                .formToolbar(
                    title: title,
                    subtitle: vehicle.displayName,
                    canSave: model.canSave,
                    isDirty: model.isDirty,
                    onSave: save,
                    onBlocked: {
                        // Edit with no changes: nothing to point at.
                        guard let blocker = model.blocker else { return }
                        showBlocker = true
                        if blocker.field == .service { model.isPickerOpen = true }
                        withAnimation { proxy.scrollTo(blocker.field, anchor: .center) }
                    },
                    onDiscard: clearDraft
                )
                .onChange(of: ScheduleDefaultsKey(
                    presetName: model.selectedPreset?.name,
                    matchID: target?.id,
                    isBackfill: model.timing.isBackfill
                )) { _, _ in
                    guard !model.mode.isEdit else { return }
                    model.applyScheduleDefaults(preset: model.selectedPreset, match: target)
                }
                .onChange(of: model.hasIntervalPolicy) { hadPolicy, hasPolicy in
                    if !hadPolicy, hasPolicy { model.intervalPolicyAppeared() }
                }
                .onChange(of: model.timing) { _, _ in model.mileageResolution = nil }
                .onChange(of: model.mileageAtService) { _, _ in model.mileageResolution = nil }
                .onChange(of: model.blocker) { _, newValue in
                    if newValue == nil { showBlocker = false }
                }
                .onChange(of: model.contentSnapshot) { _, _ in draftResumeBanner = nil }
                .task(id: model.contentSnapshot) {
                    // F10: only real edits produce a draft — a pristine form
                    // must never overwrite a stored one or leave a phantom.
                    guard let draftScope, draftResumeBanner == nil, model.hasContentChanges else { return }
                    try? await Task.sleep(for: .seconds(0.5))
                    guard !Task.isCancelled else { return }
                    ServiceFormDraftStore.save(model.toDraft(), draftScope)
                }
                .trackScreen(screen)
                .onAppear(perform: prepare)
                // Pushed on the form's own stack — details push (F13), and a
                // sheet over this sheet was navigation by stacking.
                .navigationDestination(item: $attachmentForDetail) { document in
                    DocumentDetailView(document: document, showsServiceLogLink: false)
                }
            }
        }
    }

    /// F2: a `.blocking` advisory, shown at its own field only after a tap on
    /// the dim Save.
    func blockerMessage(for field: ServiceLogFormModel.BlockingField) -> String? {
        guard showBlocker, let blocker = model.blocker, blocker.field == field else { return nil }
        return blocker.message
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

    ServiceLogForm(vehicle: vehicle)
        .environment(AppState())
        .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self], inMemory: true)
}
