//
//  AppRoute.swift
//  checkpoint
//
//  Detail screens pushed onto a tab's NavigationStack. Details are pushed,
//  tasks are sheets (`ActiveSheet`): anything the user reads and backs out of
//  lives here; anything they fill in and save or cancel does not.
//

import Foundation

enum AppRoute: Hashable {
    case service(Service)
    case serviceLog(ServiceLog)
    case visit(ServiceVisit)
    case document(Document)
    case documents(Vehicle)
}
