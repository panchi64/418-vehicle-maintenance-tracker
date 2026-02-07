//
//  CostValidation.swift
//  checkpoint
//
//  Cost input filtering and validation
//

import Foundation

enum CostValidation {
    /// Filter cost input to only allow numeric characters and a single decimal point
    static func filterCostInput(_ input: String) -> String {
        var hasDecimal = false
        var filtered = ""

        for char in input {
            if char.isNumber {
                filtered.append(char)
            } else if char == "." && !hasDecimal {
                hasDecimal = true
                filtered.append(char)
            }
        }

        // Limit to 2 decimal places
        if let dotIndex = filtered.firstIndex(of: ".") {
            let decimals = filtered[filtered.index(after: dotIndex)...]
            if decimals.count > 2 {
                let endIndex = filtered.index(dotIndex, offsetBy: 3)
                filtered = String(filtered[filtered.startIndex..<endIndex])
            }
        }

        return filtered
    }

    /// Validate cost string, returning an error message or nil if valid
    static func validate(_ cost: String) -> String? {
        guard !cost.isEmpty else { return nil }

        // Must contain at least one digit
        guard cost.contains(where: { $0.isNumber }) else {
            return "INVALID AMOUNT"
        }

        // Check for valid decimal number
        guard Decimal(string: cost) != nil else {
            return "INVALID AMOUNT"
        }

        return nil
    }
}
