//
//  ServiceNameTool.swift
//  checkpoint
//
//  The on-device model's way to ask "what does this vehicle call that job?"
//  while it reads a receipt. It answers from a snapshot of the vehicle's
//  service names and the presets taken on the main actor before the session
//  starts — a `Tool` is `Sendable` and called off the main actor, so it never
//  touches SwiftData.
//

import Foundation
import FoundationModels

nonisolated struct ServiceNameTool: Tool {
    let name = "findService"
    let description = """
        Looks up the name this vehicle's maintenance log uses for a job printed on the receipt. \
        Call it for every service or repair line, with the line's wording.
        """

    let matcher: ServiceNameMatcher

    @Generable
    nonisolated struct Arguments {
        @Guide(description: "The job as printed on the receipt, e.g. \"LOF\" or \"Rotación de gomas\"")
        var jobDescription: String
    }

    func call(arguments: Arguments) async throws -> String {
        Self.answer(for: arguments.jobDescription, matcher: matcher)
    }

    /// What the tool tells the model. Split out so tests can read it without a
    /// session.
    static func answer(for job: String, matcher: ServiceNameMatcher) -> String {
        if let known = matcher.match(job) {
            return "Use the service name \"\(known)\"."
        }
        return "No saved service matches \"\(job)\". Use a short name for it in title case."
    }
}
