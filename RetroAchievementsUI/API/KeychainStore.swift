//
//  KeychainStore.swift
//  RetroAchievementsUI
//
//  Minimal Security.framework wrapper for the signed-in user's Web API key.
//
//  It previously lived in UserDefaults via @AppStorage, which is neither
//  encrypted nor excluded from backups. This moves it to the Keychain.
//
//  Items are written *synchronizable*, so iCloud Keychain carries them to the
//  user's other devices and across a reinstall — signing in on a new phone no
//  longer means a trip to the RetroAchievements website for the key. iCloud
//  Keychain is end-to-end encrypted and needs no entitlement, unlike the
//  key-value store used for the tip badge; a credential does not belong in an
//  unencrypted plist.
//
//  Reads accept either kind of item. A synchronizable item is a *different*
//  item from a local one with the same service and account, so a query that
//  demanded one would miss the other — and every existing install has the
//  local kind.
//

import Foundation
import Security

enum KeychainStore {

    /// Namespaced so we never collide with another app's items in a shared
    /// keychain-access-group future.
    private static let service = "com.mrosenbergtech.RetroAchievementsUI"

    enum Key: String {
        case webAPIKey = "webAPIKey"
        case webAPIUsername = "webAPIUsername"
        /// Not secrets — they ride here because a synchronizable Keychain
        /// item is the only cross-device store that needs no entitlement,
        /// and the tip badge should survive a reinstall. See TipStore.
        case hasTipped = "hasTipped"
        /// Product ID of the highest tier tipped, which chooses the badge.
        case topTipTier = "topTipTier"
    }

    // MARK: - Read / Write / Delete

    static func read(_ key: Key) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            // Any: this has to find both the synced item and the local one a
            // pre-sync install left behind, or upgrading looks like a logout.
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
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

        // Writes are always synchronizable; a local leftover is cleared below
        // so the two cannot drift apart and disagree about the credential.
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecAttrSynchronizable as String: true,
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data,
            // Not …ThisDeviceOnly: that accessibility class cannot sync, and
            // AfterFirstUnlock is what lets a background refresh read the key.
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            deleteLocalCopy(key)
            return true
        }

        guard updateStatus == errSecItemNotFound else { return false }

        var insert = query
        insert.merge(attributes) { current, _ in current }
        let added = SecItemAdd(insert as CFDictionary, nil) == errSecSuccess
        if added { deleteLocalCopy(key) }
        return added
    }

    @discardableResult
    static func delete(_ key: Key) -> Bool {
        // Any: signing out must remove both kinds, or a stale local item would
        // sign the user back in on the next launch.
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    /// Removes the pre-sync, device-only item once its value has been written
    /// to the synchronizable one.
    @discardableResult
    private static func deleteLocalCopy(_ key: Key) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecAttrSynchronizable as String: false,
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
        else {
            // No legacy value: the item, if any, may still be the device-only
            // kind from before syncing. Writing it back upgrades it in place
            // and clears the local copy — one launch, then it is synced.
            guard let existing = read(.webAPIKey) else { return nil }
            save(existing, for: .webAPIKey)
            return existing
        }

        // Only clear the legacy value once it is safely in the Keychain,
        // so an interrupted migration can be retried on the next launch.
        if save(legacyValue, for: .webAPIKey) {
            defaults.removeObject(forKey: legacyKey)
            return legacyValue
        }

        return legacyValue
    }
}
