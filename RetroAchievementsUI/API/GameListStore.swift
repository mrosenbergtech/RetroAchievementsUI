//
//  GameListStore.swift
//  RetroAchievementsUI
//
//  On-disk cache for the two large, rebuildable API payloads: the full RA game
//  list (tens of thousands of entries) and the console list.
//
//  These previously lived in UserDefaults via @AppStorage. UserDefaults is
//  loaded into memory wholesale at launch and is not meant for multi-megabyte
//  blobs, so both now live in Application Support and are excluded from backup.
//

import Foundation

/// A cached payload plus the date it was written, so TTL logic lives in one place.
struct CachedPayload<Value: Codable>: Codable {
    let value: Value
    let cachedAt: Date

    func isFresh(within ttl: TimeInterval, now: Date = Date()) -> Bool {
        now.timeIntervalSince(cachedAt) < ttl
    }
}

final class GameListStore {

    /// Matches the previous @AppStorage behaviour: game list expires after 7 days.
    static let gameListTTL: TimeInterval = 604_800

    /// Unlock shares drift slowly, and every entry is refreshed for free the
    /// next time its game is opened, so this outlives the game list by a lot.
    static let rarityIndexTTL: TimeInterval = 30 * 86_400

    enum Slot: String {
        case gameList = "gamelist.json"
        case consoleList = "consolelist.json"
        /// achievement ID → share of the game's players holding it.
        case rarityIndex = "rarityindex.json"
        /// username → index into Network.recentAchievementWindows.
        case recentWindow = "recentwindow.json"

        /// Legacy UserDefaults key this slot was migrated away from.
        var legacyDefaultsKey: String {
            switch self {
            case .gameList:    return "completeRetroAchievementsGameListJSONData"
            case .consoleList: return "completeRetroAchievementsConsoleListJSONData"
            case .rarityIndex: return ""      // never lived in UserDefaults
            case .recentWindow: return ""     // never lived in UserDefaults
            }
        }
    }

    private let directory: URL
    private let fileManager: FileManager
    private let defaults: UserDefaults

    /// `directory` is injectable so tests can run against a temporary folder
    /// instead of the real Application Support container.
    init(directory: URL? = nil,
         fileManager: FileManager = .default,
         defaults: UserDefaults = .standard) {
        self.fileManager = fileManager
        self.defaults = defaults
        self.directory = directory ?? Self.defaultDirectory(fileManager: fileManager)
        createDirectoryIfNeeded()
    }

    private static func defaultDirectory(fileManager: FileManager) -> URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        return base.appendingPathComponent("RetroAchievementsUI", isDirectory: true)
    }

    private func createDirectoryIfNeeded() {
        guard !fileManager.fileExists(atPath: directory.path) else { return }
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    private func url(for slot: Slot) -> URL {
        directory.appendingPathComponent(slot.rawValue)
    }

    // MARK: - Load / Save / Clear

    /// Returns the cached value, or `nil` if absent, unreadable, corrupt, or
    /// past `ttl`. Corruption is treated as a cache miss rather than an error:
    /// every payload here is rebuildable from the API.
    func load<Value: Codable>(_ slot: Slot, as type: Value.Type, ttl: TimeInterval? = nil) -> Value? {
        guard let data = try? Data(contentsOf: url(for: slot)) else { return nil }
        guard let payload = try? JSONDecoder().decode(CachedPayload<Value>.self, from: data) else {
            // Unreadable or written by an older schema — drop it.
            clear(slot)
            return nil
        }
        if let ttl, !payload.isFresh(within: ttl) { return nil }
        return payload.value
    }

    @discardableResult
    func save<Value: Codable>(_ value: Value, to slot: Slot, now: Date = Date()) -> Bool {
        let payload = CachedPayload(value: value, cachedAt: now)
        guard let data = try? JSONEncoder().encode(payload) else { return false }

        var target = url(for: slot)
        do {
            try data.write(to: target, options: .atomic)
            // Rebuildable cache — keep it out of iCloud/iTunes backups.
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try? target.setResourceValues(values)
            return true
        } catch {
            return false
        }
    }

    func cachedAt(_ slot: Slot) -> Date? {
        guard let data = try? Data(contentsOf: url(for: slot)),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let timestamp = object["cachedAt"] as? TimeInterval
        else { return nil }
        // JSONEncoder's default date strategy is seconds since reference date.
        return Date(timeIntervalSinceReferenceDate: timestamp)
    }

    func clear(_ slot: Slot) {
        try? fileManager.removeItem(at: url(for: slot))
    }

    func clearAll() {
        Slot.allCases.forEach(clear)
    }

    // MARK: - Migration

    /// Moves a legacy raw-JSON blob out of UserDefaults and into this store.
    ///
    /// The legacy format was the bare `[Value]` array with a separate `cacheDate`
    /// key; it is rewrapped in `CachedPayload` so TTL still works and the user
    /// does not trigger a full multi-minute game-list re-sync after updating.
    func migrateLegacyBlobIfNeeded<Value: Codable>(
        _ slot: Slot,
        as type: Value.Type,
        legacyCacheDateKey: String = "cacheDate"
    ) {
        // Nothing to do if this store already holds the payload.
        guard !fileManager.fileExists(atPath: url(for: slot).path) else {
            defaults.removeObject(forKey: slot.legacyDefaultsKey)
            return
        }

        guard let legacyData = defaults.data(forKey: slot.legacyDefaultsKey),
              let decoded = try? JSONDecoder().decode(Value.self, from: legacyData)
        else { return }

        let legacyDate = defaults.object(forKey: legacyCacheDateKey) as? TimeInterval
        let cachedAt = legacyDate.map { Date(timeIntervalSince1970: $0) } ?? Date()

        if save(decoded, to: slot, now: cachedAt) {
            defaults.removeObject(forKey: slot.legacyDefaultsKey)
        }
    }
}

extension GameListStore.Slot: CaseIterable {}

extension Array {
    /// Fixed-size batches, used to bound how many requests are in flight.
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
