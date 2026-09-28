import Foundation
import UserNotifications
import WidgetKit

/// "Borrar mis datos" (PRODUCT.md §13), for every tier, device-only
/// included: the watch list, the outbox, Tu aporte (reports, votes, seals,
/// claims) and every choice and setting go at once. The first run shows
/// again. There is no account or device id to drop yet; once the server
/// exists, this is where the link to it is cut.
struct DataEraser {
    let watches: WatchStore
    let device: DeviceStore
    let contributions: ContributionStore
    var defaults: UserDefaults = .standard
    var shared: UserDefaults? = SharedContainer.defaults

    /// Everything kept on the device. The app saves the emptied stores.
    func eraseStoredData() {
        watches.replaceAll(with: [])
        device.eraseOutbox()
        contributions.eraseAll()
        for key in Preferences.erasable {
            defaults.removeObject(forKey: key)
        }
        WidgetSnapshot.erase(from: shared)
    }

    /// And what the system holds for Biombo: waiting notifications and the
    /// widgets' last picture.
    func eraseSystemTraces() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
