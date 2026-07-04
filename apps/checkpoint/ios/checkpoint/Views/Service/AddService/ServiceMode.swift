import Foundation

enum ServiceMode: String, CaseIterable {
    case record = "Record"
    case remind = "Remind"

    var displayName: String {
        switch self {
        case .record: return L10n.serviceModeRecord
        case .remind: return L10n.serviceModeRemind
        }
    }

    var caption: String {
        switch self {
        case .record: return L10n.serviceModeRecordCaption
        case .remind: return L10n.serviceModeRemindCaption
        }
    }
}
