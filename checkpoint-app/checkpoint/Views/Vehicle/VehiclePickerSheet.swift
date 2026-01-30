//
//  VehiclePickerSheet.swift
//  checkpoint
//
//  Sheet for selecting between vehicles with instrument cluster aesthetic
//

import SwiftUI
import SwiftData
import WidgetKit
import UserNotifications

struct VehiclePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var vehicles: [Vehicle]

    @Binding var selectedVehicle: Vehicle?
    let onAddVehicle: () -> Void

    // State for delete confirmation
    @State private var vehicleToDelete: Vehicle?
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphericBackground()

                ScrollView {
                    VStack(spacing: Spacing.md) {
                        // Vehicles list
                        VStack(spacing: 0) {
                            ForEach(vehicles) { vehicle in
                                vehicleRow(vehicle)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            vehicleToDelete = vehicle
                                            showDeleteConfirmation = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }

                                if vehicle.id != vehicles.last?.id {
                                    Rectangle()
                                        .fill(Theme.gridLine)
                                        .frame(height: 1)
                                        .padding(.leading, Spacing.md)
                                }
                            }
                        }
                        .background(Theme.surfaceInstrument)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(Theme.gridLine, lineWidth: 1)
                        )

                        // Add vehicle button
                        Button {
                            dismiss()
                            onAddVehicle()
                        } label: {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Theme.accent)

                                Text("Add Vehicle")
                                    .font(.instrumentBody)
                                    .foregroundStyle(Theme.accent)

                                Spacer()
                            }
                            .padding(Spacing.md)
                            .background(Theme.surfaceInstrument)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(Theme.accent.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.instrument)
                        .accessibilityLabel("Add new vehicle")
                    }
                    .padding(Spacing.screenHorizontal)
                    .padding(.top, Spacing.md)
                }
            }
            .navigationTitle("Select Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.surfaceInstrument, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.accent)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .applyGlassBackground()
        .alert("Delete Vehicle?", isPresented: $showDeleteConfirmation, presenting: vehicleToDelete) { vehicle in
            Button("Cancel", role: .cancel) {
                vehicleToDelete = nil
            }
            Button("Delete", role: .destructive) {
                deleteVehicle(vehicle)
            }
        } message: { vehicle in
            if vehicles.count == 1 {
                Text("This is your only vehicle. Deleting it will remove all associated services and maintenance history. You'll need to add a new vehicle to continue using Checkpoint.")
            } else {
                Text("This will permanently delete \"\(vehicle.displayName)\" and all its services and maintenance history.")
            }
        }
    }

    // MARK: - Delete Vehicle

    private func deleteVehicle(_ vehicle: Vehicle) {
        let vehicleID = vehicle.id.uuidString
        let isSelectedVehicle = selectedVehicle?.id == vehicle.id

        // Cancel all notifications for this vehicle's services
        if let services = vehicle.services {
            for service in services {
                if let notificationID = service.notificationID {
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])
                }
            }
        }

        // Cancel mileage reminder notification
        let mileageReminderID = "mileage-reminder-\(vehicleID)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [mileageReminderID])

        // Cancel yearly roundup notification
        let yearlyRoundupID = "yearly-roundup-\(vehicleID)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [yearlyRoundupID])

        // Remove widget data for this vehicle
        WidgetDataService.shared.removeWidgetData(for: vehicleID)

        // Delete the vehicle from SwiftData (cascade deletes services, logs, snapshots)
        modelContext.delete(vehicle)

        // Clear selection if the deleted vehicle was selected
        // ContentView's onChange(of: vehicles) will handle setting a new selection
        if isSelectedVehicle {
            selectedVehicle = nil
        }

        // Reload widget timelines
        WidgetCenter.shared.reloadAllTimelines()

        vehicleToDelete = nil
    }

    private func vehicleRow(_ vehicle: Vehicle) -> some View {
        Button {
            selectedVehicle = vehicle
            dismiss()
        } label: {
            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(vehicle.displayName.uppercased())
                        .font(.custom("Barlow-SemiBold", size: 16))
                        .foregroundStyle(Theme.textPrimary)
                        .tracking(0.5)

                    Text("\(String(vehicle.year)) \(vehicle.make) \(vehicle.model)")
                        .font(.instrumentLabel)
                        .foregroundStyle(Theme.textTertiary)
                }

                Spacer()

                if selectedVehicle?.id == vehicle.id {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.accent)
                }
            }
            .padding(Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(ServiceRowButtonStyle())
        .accessibilityLabel(vehicle.displayName)
        .accessibilityHint(selectedVehicle?.id == vehicle.id ? "Currently selected" : "Double tap to select")
    }
}

// MARK: - Glass Background Modifier (iOS 26+)

extension View {
    @ViewBuilder
    func applyGlassBackground() -> some View {
        if #available(iOS 26, *) {
            self.presentationBackground(.regularMaterial)
        } else {
            self
        }
    }
}

#Preview {
    @Previewable @State var selected: Vehicle? = nil

    VehiclePickerSheet(
        selectedVehicle: $selected,
        onAddVehicle: { print("Add vehicle") }
    )
    .modelContainer(for: Vehicle.self, inMemory: true)
}
