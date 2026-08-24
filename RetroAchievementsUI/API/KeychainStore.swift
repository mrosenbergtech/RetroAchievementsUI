//
//  KeychainStore.swift
//  RetroAchievementsUI
//
//  Minimal Security.framework wrapper for the signed-in user's Web API key.
//
//  The login sheet tells users their key is "stored locally and never shared";
//  it previously lived in UserDefaults via @AppStorage, which is neither
//  encrypted nor excluded from backups. This moves it to the Keychain.
//

import Foundation
import Security

enum KeychainStore {

    /// Namespaced so we never collide with another app's items in a shared
    /// keychain-access-group future.
    private static let service = "com.mrosenbergtech.RetroAchievementsUI"

    enum Key: String {
        case webAPIKey = "webAPIKey"
    }

    // MARK: - Read / Write / Delete

    static func read(_ key: Key) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8),
              !value.isEmpty
        else { return nil }

        return value
    }

    @discardableResult
    static func save(_ value: String, for key: Key) -> Bool {
        // An empty value means "no credential" — store nothing rather than an
        // empty item that read() would have to special-case.
        guard !value.isEmpty else { return delete(key) }
        guard let data = value.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
        ]

        // Update in place if the item already exists, otherwise add it.
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess { return true }

        guard updateStatus == errSecItemNotFound else { return false }

        var insert = query
        insert.merge(attributes) { current, _ in current }
        return SecItemAdd(insert as CFDictionary, nil) == errSecSuccess
    }

    @discardableResult
    static func delete(_ key: Key) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Migration

    /// One-time move of the API key out of UserDefaults.
    ///
    /// Safe to call on every launch: it no-ops once the legacy value is gone.
    /// Returns the key that should be used for this session, if any.
    @discardableResult
    static func migrateLegacyAPIKeyIfNeeded(
        defaults: UserDefaults = .standard,
        legacyKey: String = "webAPIKey"
    ) -> String? {
        guard let legacyValue = defaults.string(forKey: legacyKey),
              !legacyValue.isEmpty
        else { return read(.webAPIKey) }

        // Only clear the legacy value once it is safely in the Keychain,
        // so an interrupted migration can be retried on the next launch.
        if save(legacyValue, for: .webAPIKey) {
            defaults.removeObject(forKey: legacyKey)
            return legacyValue
        }

        return legacyValue
    }
}
