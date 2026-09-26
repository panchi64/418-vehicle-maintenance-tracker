//
//  HomeTab+Appointments.swift
//  checkpoint
//
//  Home's Shop Visit section and what its buttons do. The section itself is
//  `AppointmentSection`; this wires it to the router and to Maps.
//

import SwiftData
import SwiftUI

extension HomeTab {

    func appointmentSection(_ content: Content, vehicle: Vehicle) -> some View {
        AppointmentSection(
            appointments: content.appointments,
            onBook: {
                // Defaults do the work: the service Next Up is showing is
                // usually the reason for the visit.
                let preselected = (content.nextUp as? Service).map { [$0] } ?? []
                appState.present(.appointment(AppointmentEditorRequest(
                    target: .new(vehicle, preselected: preselected)
                )))
            },
            onOpen: { appointment in
                appState.present(.appointment(AppointmentEditorRequest(target: .edit(appointment))))
            },
            onDirections: { appointment in
                Task { await openDirections(to: appointment) }
            },
            onLogVisit: { appointment in
                appState.present(.completeAppointment(appointment))
            }
        )
    }

    private func openDirections(to appointment: Appointment) async {
        let opened = await AppointmentDirections.open(appointment)
        if opened {
            // A place found by name is saved back, so the next tap is exact.
            try? modelContext.save()
        } else {
            ToastService.shared.show(L10n.appointmentDirectionsFailed, icon: "map", style: .error)
        }
    }
}
