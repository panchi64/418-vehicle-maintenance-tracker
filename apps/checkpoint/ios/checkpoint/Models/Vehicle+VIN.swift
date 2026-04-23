//
//  Vehicle+VIN.swift
//  checkpoint
//
//  VIN display and validation
//

import Foundation

extension Vehicle {
    /// Truncated VIN for display (last 4 characters)
    var truncatedVIN: String? {
        guard let vin = vin, vin.count >= 4 else { return vin }
        return "..." + String(vin.suffix(4))
    }

    /// Validate a VIN string: 17 alphanumeric characters, excluding I, O, Q
    static func isValidVIN(_ vin: String) -> Bool {
        let trimmed = vin.trimmingCharacters(in: .whitespaces)
        guard trimmed.count == 17 else { return false }
        let forbidden = CharacterSet(charactersIn: "IOQioq")
        return trimmed.unicodeScalars.allSatisfy {
            !forbidden.contains($0) && CharacterSet.alphanumerics.contains($0)
        }
    }
}
