//
//  DocumentType.swift
//  checkpoint
//
//  Categorization for vehicle documents stored in the Documents library.
//

import Foundation
import SwiftUI

enum DocumentType: String, Codable, CaseIterable, Identifiable {
    case registration
    case insurance
    case title
    case inspection
    case warranty
    case manual
    case receipt
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .registration: return L10n.documentTypeRegistration
        case .insurance: return L10n.documentTypeInsurance
        case .title: return L10n.documentTypeTitle
        case .inspection: return L10n.documentTypeInspection
        case .warranty: return L10n.documentTypeWarranty
        case .manual: return L10n.documentTypeManual
        case .receipt: return L10n.documentTypeReceipt
        case .other: return L10n.documentTypeOther
        }
    }

    var icon: String {
        switch self {
        case .registration: return "doc.text.fill"
        case .insurance: return "shield.fill"
        case .title: return "doc.richtext.fill"
        case .inspection: return "checkmark.seal.fill"
        case .warranty: return "checkmark.shield.fill"
        case .manual: return "book.fill"
        case .receipt: return "receipt.fill"
        case .other: return "doc.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .registration: return Theme.accent
        case .insurance: return Theme.statusGood
        case .title: return Theme.accent
        case .inspection: return Theme.statusGood
        case .warranty: return Theme.statusDueSoon
        case .manual: return Theme.textSecondary
        case .receipt: return Theme.accent
        case .other: return Theme.textSecondary
        }
    }

    /// Best-effort document type from a filename. Pure heuristic — never the
    /// final word; the user can always override in the add-flow review step.
    static func suggestedType(forFileName fileName: String) -> DocumentType {
        let name = fileName.lowercased()

        if name.contains("registr") || name.contains("marbete") || name.contains("dmv") {
            return .registration
        }
        if name.contains("insur") || name.contains("policy") || name.contains("declar") || name.contains("seguro") {
            return .insurance
        }
        if name.contains("title") || name.contains("titulo") || name.contains("lien") {
            return .title
        }
        if name.contains("inspect") || name.contains("emiss") || name.contains("smog") {
            return .inspection
        }
        if name.contains("warrant") || name.contains("garant") {
            return .warranty
        }
        if name.contains("manual") || name.contains("owner") || name.contains("guide") {
            return .manual
        }
        if name.contains("receipt") || name.contains("invoice") || name.contains("recibo") || name.contains("factura") {
            return .receipt
        }
        return .other
    }

    /// Sort order used by the grouped list in DocumentsView.
    static let listOrder: [DocumentType] = [
        .registration,
        .insurance,
        .title,
        .inspection,
        .warranty,
        .manual,
        .receipt,
        .other,
    ]
}
