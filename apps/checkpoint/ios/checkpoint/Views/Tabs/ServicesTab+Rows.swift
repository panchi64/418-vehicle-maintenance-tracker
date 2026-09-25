//
//  ServicesTab+Rows.swift
//  checkpoint
//
//  The Services list's rows and their actions. Every swipe action is also in
//  the context menu, so none is reachable only by a gesture — and VoiceOver
//  exposes swipe actions in its Actions rotor.
//
//    service:  Edit · Mark Done           full swipe = Mark Done. Stop
//                                         Tracking and Delete sit in the
//                                         context menu only: rarer, heavier.
//    log:      Duplicate · Edit · Delete  full swipe = Delete, with Undo.
//                                         With more than one vehicle the
//                                         menu's Duplicate is "Duplicate To ▸",
//                                         one item per vehicle.
//
//  (Listed leading-to-trailing as they appear; SwiftUI declares a trailing
//  swipe's buttons outermost-first, so the code reads in reverse.)
//

import SwiftUI

/// The system `List` with the brand's row geometry: flush with the section
/// header, theme hairlines, content over the tab's own background.
enum ServicesListRow {
    static let insets = EdgeInsets(
        top: 0,
        leading: Spacing.screenHorizontal,
        bottom: 0,
        trailing: Spacing.screenHorizontal
    )
}

extension View {
    func servicesListRow() -> some View {
        self
            .listRowInsets(ServicesListRow.insets)
            .listRowBackground(Color.clear)
            .listRowSeparatorTint(Theme.gridLine)
            .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
    }

    /// A section header in the list: the brand's Title Case header, not the
    /// system's (which would uppercase it), spaced from the section above.
    func servicesListHeader() -> some View {
        self
            .textCase(nil)
            .padding(.top, Spacing.lg)
            .listRowInsets(ServicesListRow.insets)
    }
}

extension ServicesTab {

    // MARK: - Service rows

    func serviceRow(_ service: Service, mileage: MileageEstimate, vehicle: Vehicle) -> some View {
        NavigationLink(value: AppRoute.service(service)) {
            ServiceRow(
                service: service,
                currentMileage: mileage.effective,
                isEstimatedMileage: mileage.isEstimated,
                groupedByStatus: true
            )
        }
        .tag(ServicesSelectionID.service(service.id))
        .servicesListRow()
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            markDoneButton(service, vehicle: vehicle)
            editButton { sheet = .editService(service) }
        }
        .contextMenu {
            markDoneButton(service, vehicle: vehicle)
            editButton { sheet = .editService(service) }
            Button {
                ServiceDeleteAction.stopTracking(service, vehicle: vehicle)
            } label: {
                Label(L10n.servicesActionStopTracking, systemImage: "bell.slash")
            }
            Divider()
            Button(role: .destructive) {
                pendingDelete = .service(service)
            } label: {
                Label(L10n.serviceDeleteAction, systemImage: "trash")
            }
        }
    }

    private func markDoneButton(_ service: Service, vehicle: Vehicle) -> some View {
        Button {
            HapticService.shared.lightImpact()
            appState.present(.markDone(MarkDoneRequest(services: [service], vehicle: vehicle)))
        } label: {
            Label(L10n.servicesActionMarkDone, systemImage: "checkmark")
        }
        .tint(Theme.statusGood)
    }

    private func editButton(_ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(L10n.servicesActionEdit, systemImage: "pencil")
        }
        .tint(Theme.textTertiary)
    }

    // MARK: - Log rows

    func logRow(_ log: ServiceLog, vehicle: Vehicle) -> some View {
        NavigationLink(value: AppRoute.serviceLog(log)) {
            historyRow(log)
        }
        .tag(ServicesSelectionID.log(log.id))
        .servicesListRow()
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            deleteLogButton(log)
            editButton { sheet = .editLog(log) }
            duplicateButton(log, vehicle: vehicle)
        }
        .contextMenu {
            duplicateMenu(log, vehicle: vehicle)
            editButton { sheet = .editLog(log) }
            Divider()
            deleteLogButton(log)
        }
    }

    /// The month is in the section header, so the row carries the day only.
    private func historyRow(_ log: ServiceLog) -> some View {
        let name = log.service?.name ?? L10n.rowServiceFallback
        let day = log.performedDate.formatted(.dateTime.month(.abbreviated).day())

        return ServiceEventRow(
            indicator: .completed(),
            title: name,
            metadata: [
                .detail(day),
                .detail(Formatters.mileage(log.mileageAtService))
            ],
            amount: log.formattedCost.map { .init(text: $0, color: Theme.accent) },
            accessibilityLabelText: L10n.readoutEvent(name, L10n.spokenDate(log.performedDate))
        )
    }

    private func deleteLogButton(_ log: ServiceLog) -> some View {
        Button(role: .destructive) {
            ServiceLogDeleteAction.perform(log, offerUndo: true)
        } label: {
            Label(L10n.logDeleteAction, systemImage: "trash")
        }
    }

    /// Swipe: Duplicate onto this vehicle; the form's Vehicle field can move it.
    private func duplicateButton(_ log: ServiceLog, vehicle: Vehicle) -> some View {
        Button {
            sheet = .duplicateLog(log, to: vehicle)
        } label: {
            Label(L10n.servicesActionDuplicate, systemImage: "plus.square.on.square")
        }
        .tint(Theme.accent)
    }

    /// Long-press: the same Duplicate, or — with more than one vehicle — a
    /// "Duplicate To" submenu that opens the form on the chosen one directly.
    /// This vehicle first, marked as current.
    @ViewBuilder
    private func duplicateMenu(_ log: ServiceLog, vehicle: Vehicle) -> some View {
        if vehicles.count > 1 {
            Menu {
                Button {
                    sheet = .duplicateLog(log, to: vehicle)
                } label: {
                    Text(vehicle.displayName)
                    Text(L10n.servicesActionDuplicateCurrentVehicle)
                }
                ForEach(vehicles.filter { $0.id != vehicle.id }) { other in
                    Button(other.displayName) {
                        sheet = .duplicateLog(log, to: other)
                    }
                }
            } label: {
                Label(L10n.servicesActionDuplicateTo, systemImage: "plus.square.on.square")
            }
        } else {
            duplicateButton(log, vehicle: vehicle)
        }
    }
}
