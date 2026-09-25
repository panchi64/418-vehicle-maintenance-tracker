//
//  ServiceLogFormMode.swift
//  checkpoint
//
//  Which door the unified service form was opened through.
//

import Foundation

enum ServiceLogFormMode {
    /// [+]: pick a service, say when.
    case log
    /// Mark Done: the service is preselected and locked; saving completes it.
    case complete(Service)
    /// A history entry: prefilled, Save dim until something changes.
    case edit(ServiceLog)

    var isEdit: Bool {
        if case .edit = self { return true }
        return false
    }

    var completing: Service? {
        if case .complete(let service) = self { return service }
        return nil
    }

    var editing: ServiceLog? {
        if case .edit(let log) = self { return log }
        return nil
    }

    /// Only [+] can pick its service, and only [+] can schedule instead of log.
    var isServiceLocked: Bool { !isLogDoor }
    var offersNotYet: Bool { isLogDoor }

    private var isLogDoor: Bool {
        if case .log = self { return true }
        return false
    }
}
