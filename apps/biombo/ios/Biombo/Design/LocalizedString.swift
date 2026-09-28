import Foundation

extension LocalizedStringResource {
    /// These words as a plain string in `locale`: for lists joined natively,
    /// measuring, and text that leaves SwiftUI (notifications, widgets, Siri).
    nonisolated func string(in locale: Locale) -> String {
        var resource = self
        resource.locale = locale
        return String(localized: resource)
    }
}
