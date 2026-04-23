import Foundation
import Security

/// Anonymous per-device identifier persisted in the keychain. Used to rate-limit
/// submissions and de-duplicate confirm/flag votes without an account system.
actor DeviceTokenService {
    static let shared = DeviceTokenService()

    private static let service = "com.418-studio.biombo"
    private static let account = "device-token"

    private var cached: String?

    func token() -> String {
        if let cached { return cached }
        if let existing = Self.load() {
            cached = existing
            return existing
        }
        let fresh = UUID().uuidString
        Self.save(fresh)
        cached = fresh
        return fresh
    }

    func invalidateCache() {
        cached = nil
    }

    private static func load() -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        return token
    }

    @discardableResult
    private static func save(_ token: String) -> Bool {
        let data = Data(token.utf8)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }
}
