import Foundation
import SwiftData

/// Snapshot of a Record Service save so the success toast can offer UNDO.
struct RecordedServiceUndo {
    let service: Service
    let log: ServiceLog
    let attachments: [ServiceAttachment]
    let vehicle: Vehicle?
    let priorVehicleMileage: Int

    @MainActor
    func perform(in context: ModelContext) {
        if let vehicle, vehicle.currentMileage != priorVehicleMileage {
            vehicle.currentMileage = priorVehicleMileage
        }
        for attachment in attachments { context.delete(attachment) }
        context.delete(log)
        context.delete(service)
    }
}
