import Foundation

/// An agency whose items carry the Oficial label (PRODUCT.md §4.5, §6).
nonisolated enum Agency: String, CaseIterable, Codable, Hashable, Sendable {
    case daco
    case luma
    case aaa
    case dtop
    case nws
    case fcc
    case nmead

    /// Agencies are proper names in both languages, so this is not localized.
    var displayName: String {
        switch self {
        case .daco: "DACO"
        case .luma: "LUMA"
        case .aaa: "AAA"
        case .dtop: "DTOP"
        case .nws: "NWS"
        case .fcc: "FCC"
        case .nmead: "NMEAD"
        }
    }

    /// Where to tell the utility itself, since Biombo doesn't (§6.2, §6.3).
    /// *Verify before launch*: LUMA's site and AAA's customer line.
    var reportURL: URL? {
        switch self {
        case .luma: URL(string: "https://lumapr.com")
        case .aaa: URL(string: "tel:7876202482")
        default: nil
        }
    }

    /// The utility is told by calling it, not on a website.
    var reportsByPhone: Bool { reportURL?.scheme == "tel" }
}

/// Who an item comes from (§4.2). Community and official data are never blended (§3).
nonisolated enum Source: Codable, Hashable, Sendable {
    case community
    /// A verified owner, about their own place only.
    case owner
    /// An ingested feed, an authority post or a staff transcription of a release.
    case official(Agency)

    var agency: Agency? {
        if case .official(let agency) = self { agency } else { nil }
    }
}

/// How a report was captured. Every channel yields the same Report under the same rules (§4.2).
nonisolated enum Channel: String, Codable, Hashable, Sendable {
    case tap
    case siri
    case control
    case photo
}
