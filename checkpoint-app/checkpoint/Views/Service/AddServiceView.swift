//
//  AddServiceView.swift
//  checkpoint
//
//  Dual-mode form for logging past services or scheduling future services
//

import SwiftUI
import SwiftData

enum ServiceMode: String, CaseIterable {
    case log = "Log Service"
    case schedule = "Schedule"
}

struct AddServiceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let vehicle: Vehicle

    // Mode selection
    @State private var mode: ServiceMode = .log

    // Service type selection
    @State private var selectedPreset: PresetData? = nil
    @State private var customServiceName: String = ""

    // Log mode fields
    @State private var performedDate: Date = Date()
    @State private var mileageAtService: String = ""
    @State private var cost: String = ""
    @State private var notes: String = ""

    // Schedule mode fields
    @State private var dueDate: Date = Date().addingTimeInterval(86400 * 30) // 30 days from now
    @State private var dueMileage: String = ""
    @State private var intervalMonths: String = ""
    @State private var intervalMiles: String = ""

    var serviceName: String {
        selectedPreset?.name ?? customServiceName
    }

    var isFormValid: Bool {
        !serviceName.isEmpty && (mode == .log ? !mileageAtService.isEmpty : true)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Mode picker (segmented control at top)
                Section {
                    Picker("Mode", selection: $mode) {
                        ForEach(ServiceMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                }

                // Service type section
                Section("Service Type") {
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
            .navigationTitle(mode == .log ? "Log Service" : "Schedule Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveService() }
                        .foregroundStyle(Theme.accent)
                        .disabled(!isFormValid)
                }
            }
            .onChange(of: selectedPreset) { _, newPreset in
                // Auto-fill intervals from preset
                if let preset = newPreset {
                    if let months = preset.defaultIntervalMonths {
                        intervalMonths = String(months)
                    }
                    if let miles = preset.defaultIntervalMiles {
                        intervalMiles = String(miles)
                    }
                }
            }
        }
    }

    // MARK: - Log Mode Fields

    @ViewBuilder
    private var logModeFields: some View {
        Section("Service Details") {
            DatePicker("Date Performed", selection: $performedDate, displayedComponents: .date)

            HStack {
                Text("Mileage")
                Spacer()
                TextField("Required", text: $mileageAtService)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                Text("mi")
                    .foregroundStyle(Theme.textSecondary)
            }
        }

        Section("Optional") {
            HStack {
                Text("Cost")
                Spacer()
                Text("$")
                    .foregroundStyle(Theme.textSecondary)
                TextField("0.00", text: $cost)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }

            TextField("Notes", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    // MARK: - Schedule Mode Fields

    @ViewBuilder
    private var scheduleModeFields: some View {
        Section("Due Date") {
            DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)

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
    }

    // MARK: - Save Logic

    private func saveService() {
        if mode == .log {
            saveLoggedService()
        } else {
            saveScheduledService()
        }
        dismiss()
    }

    private func saveLoggedService() {
        let mileage = Int(mileageAtService) ?? vehicle.currentMileage

        // Create service
        let service = Service(
            name: serviceName,
            lastPerformed: performedDate,
            lastMileage: mileage,
            intervalMonths: Int(intervalMonths),
            intervalMiles: Int(intervalMiles)
        )
        service.vehicle = vehicle

        // Calculate next due date/mileage
        if let months = Int(intervalMonths), months > 0 {
            service.dueDate = Calendar.current.date(byAdding: .month, value: months, to: performedDate)
        }
        if let miles = Int(intervalMiles), miles > 0 {
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
            notes: notes.isEmpty ? nil : notes
        )
        modelContext.insert(log)

        // Update vehicle mileage if service mileage is higher
        if mileage > vehicle.currentMileage {
            vehicle.currentMileage = mileage
        }
    }

    private func saveScheduledService() {
        let service = Service(
            name: serviceName,
            dueDate: dueDate,
            dueMileage: Int(dueMileage),
            intervalMonths: Int(intervalMonths),
            intervalMiles: Int(intervalMiles)
        )
        service.vehicle = vehicle
        modelContext.insert(service)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Vehicle.self, Service.self, ServiceLog.self, configurations: config)
    let vehicle = Vehicle(name: "Test Car", make: "Toyota", model: "Camry", year: 2022, currentMileage: 32500)
    container.mainContext.insert(vehicle)

    return AddServiceView(vehicle: vehicle)
        .modelContainer(container)
}
