//
//  EditServiceView.swift
//  checkpoint
//
//  Form for editing an existing service's details and schedule
//

import SwiftUI
import SwiftData

struct EditServiceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var services: [Service]

    @Bindable var service: Service
    let vehicle: Vehicle

    // Service details
    @State private var serviceName: String = ""
    @State private var dueDate: Date = Date()
    @State private var hasDueDate: Bool = false
    @State private var dueMileage: String = ""
    @State private var intervalMonths: String = ""
    @State private var intervalMiles: String = ""

    var isFormValid: Bool {
        !serviceName.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Service Details") {
                    TextField("Service Name", text: $serviceName)
                }

                Section("Due Date") {
                    Toggle("Has Due Date", isOn: $hasDueDate)

                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    }

                    HStack {
                        Text("Due Mileage")
                        Spacer()
                        TextField("Optional", text: $dueMileage)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("mi")
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                Section("Repeat Interval") {
                    HStack {
                        Text("Every")
                        Spacer()
                        TextField("6", text: $intervalMonths)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 50)
                        Text("months")
                            .foregroundStyle(Theme.textSecondary)
                    }

                    HStack {
                        Text("Or every")
                        Spacer()
                        TextField("5000", text: $intervalMiles)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 70)
                        Text("miles")
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        deleteService()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Delete Service")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Edit Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                        .foregroundStyle(Theme.accent)
                        .disabled(!isFormValid)
                }
            }
            .onAppear {
                loadServiceData()
            }
        }
    }

    // MARK: - Data Loading

    private func loadServiceData() {
        serviceName = service.name
        hasDueDate = service.dueDate != nil
        dueDate = service.dueDate ?? Date()
        dueMileage = service.dueMileage.map(String.init) ?? ""
        intervalMonths = service.intervalMonths.map(String.init) ?? ""
        intervalMiles = service.intervalMiles.map(String.init) ?? ""
    }

    // MARK: - Save Logic

    private func saveChanges() {
        service.name = serviceName
        service.dueDate = hasDueDate ? dueDate : nil
        service.dueMileage = Int(dueMileage)
        service.intervalMonths = Int(intervalMonths)
        service.intervalMiles = Int(intervalMiles)

        updateAppIcon()
        dismiss()
    }

    // MARK: - Delete Logic

    private func deleteService() {
        modelContext.delete(service)
        updateAppIcon()
        dismiss()
    }

    // MARK: - App Icon

    private func updateAppIcon() {
        AppIconService.shared.updateIcon(for: vehicle, services: services)
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

    @Previewable @State var service = Service(
        name: "Oil Change",
        dueDate: Calendar.current.date(byAdding: .day, value: 12, to: .now),
        dueMileage: 33000,
        intervalMonths: 6,
        intervalMiles: 5000
    )

    EditServiceView(service: service, vehicle: vehicle)
        .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self], inMemory: true)
}
