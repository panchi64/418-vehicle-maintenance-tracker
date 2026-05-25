import Foundation
import SwiftData

@Model
final class CachedBrand {
    @Attribute(.unique) var name: String
    var fetchedAt: Date

    init(name: String, fetchedAt: Date = Date()) {
        self.name = name
        self.fetchedAt = fetchedAt
    }
}
