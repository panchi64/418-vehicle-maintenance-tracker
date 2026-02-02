//
//  ListUpcomingServicesIntent.swift
//  checkpoint
//
//  Siri intent for listing upcoming services on a vehicle
//  "Hey Siri, what maintenance is coming up in Checkpoint?"
//

import AppIntents

/// Intent to list upcoming services on a vehicle
struct ListUpcomingServicesIntent: AppIntent {
    static var title: LocalizedStringResource = "List Upcoming Services"
    static var description = IntentDescription("List the next few maintenance services due on your vehicle")

    @Parameter(
        title: "Vehicle",
        description: "The vehicle to check",
        requestValueDialog: "Which vehicle would you like to check?"
    )
    var vehicle: VehicleEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("List upcoming services on \(\.$vehicle)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let data = SiriDataProvider.loadServiceData(for: vehicle?.id)

        guard let serviceData = data else {
            return .result(dialog: "I couldn't find any vehicle data. Please open Checkpoint to set up your vehicles.")
        }

        guard !serviceData.services.isEmpty else {
            return .result(dialog: "No services are scheduled for \(serviceData.vehicleName).")
        }

        let dialog = formatServicesDialog(
            services: serviceData.services,
            vehicleName: serviceData.vehicleName
        )

        return .result(dialog: IntentDialog(stringLiteral: dialog))
    }

    private func formatServicesDialog(services: [SiriService], vehicleName: String) -> String {
        // Take up to 3 services
        let topServices = Array(services.prefix(3))

        if topServices.count == 1 {
            return formatSingleService(topServices[0], vehicleName: vehicleName)
        }

        // Build a natural-sounding list
        var parts: [String] = []
        for service in topServices {
            parts.append(formatServiceItem(service))
        }

        let intro = "Here's what's coming up for \(vehicleName): "
        let list = parts.joined(separator: ". ")

        return intro + list + "."
    }

    private func formatSingleService(_ service: SiriService, vehicleName: String) -> String {
        let statusText = service.status.dialogPrefix.lowercased()
        return "For \(vehicleName), \(service.name) is \(statusText). \(service.dueDescription)."
    }

    private func formatServiceItem(_ service: SiriService) -> String {
        switch service.status {
        case .overdue:
            return "\(service.name) is overdue"
        case .dueSoon:
            if let days = service.daysRemaining {
                if days == 0 {
                    return "\(service.name) is due today"
                } else if days == 1 {
                    return "\(service.name) is due tomorrow"
                } else if days > 0 {
                    return "\(service.name) is due in \(days) days"
                } else {
                    return "\(service.name) is \(abs(days)) days overdue"
                }
            }
            return "\(service.name) is due soon"
        case .good:
            if let days = service.daysRemaining, days > 0 {
                return "\(service.name) in \(days) days"
            }
            return "\(service.name): \(service.dueDescription.lowercased())"
        case .neutral:
            return "\(service.name): \(service.dueDescription.lowercased())"
        }
    }
}
