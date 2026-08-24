//
//  StorageTests.swift
//  RetroAchievementsUITests
//
//  GameListStore and KeychainStore, including the migrations that move users
//  off the previous UserDefaults-backed storage without forcing a re-sync or a
//  re-login.
//

import Foundation
import Testing
@testable import RetroAchievementsUI

@Suite("GameListStore")
struct GameListStoreTests {

    private func makeStore(defaults: UserDefaults? = nil) -> (GameListStore, URL, UserDefaults) {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ra-store-\(UUID().uuidString)", isDirectory: true)
        let suite = defaults ?? UserDefaults(suiteName: "ra-store-\(UUID().uuidString)")!
        return (GameListStore(directory: dir, defaults: suite), dir, suite)
    }

    private var sampleGames: [GameListGame] {
        try! JSONDecoder().decode([GameListGame].self, from: Fixtures.gameList)
    }

    @Test("Round-trips a payload")
    func roundTrip() {
        let (store, dir, _) = makeStore()
        defer { try? FileManager.default.removeItem(at: dir) }

        #expect(store.save(sampleGames, to: .gameList))

        let loaded = store.load(.gameList, as: [GameListGame].self)
        #expect(loaded?.count == 1)
        #expect(loaded?.first?.id == 11278)
    }

    @Test("An empty store is a miss, not an error")
    func emptyIsMiss() {
        let (store, dir, _) = makeStore()
        defer { try? FileManager.default.removeItem(at: dir) }

        #expect(store.load(.gameList, as: [GameListGame].self) == nil)
        #expect(store.cachedAt(.gameList) == nil)
    }

    @Test("A payload inside its TTL is served; past it, it is a miss")
    func ttlExpiry() {
        let (store, dir, _) = makeStore()
        defer { try? FileManager.default.removeItem(at: dir) }

        let eightDaysAgo = Date().addingTimeInterval(-8 * 86_400)
        store.save(sampleGames, to: .gameList, now: eightDaysAgo)

        #expect(store.load(.gameList, as: [GameListGame].self, ttl: GameListStore.gameListTTL) == nil)
        // Without a TTL the payload is still readable.
        #expect(store.load(.gameList, as: [GameListGame].self) != nil)
    }

    @Test("A fresh payload survives the TTL check")
    func freshWithinTTL() {
        let (store, dir, _) = makeStore()
        defer { try? FileManager.default.removeItem(at: dir) }

        store.save(sampleGames, to: .gameList)
        #expect(store.load(.gameList, as: [GameListGame].self, ttl: GameListStore.gameListTTL) != nil)
    }

    @Test("A corrupt file reads as a miss instead of throwing into the UI")
    func corruptFileIsMiss() throws {
        let (store, dir, _) = makeStore()
        defer { try? FileManager.default.removeItem(at: dir) }

        store.save(sampleGames, to: .gameList)
        let file = dir.appendingPathComponent(GameListStore.Slot.gameList.rawValue)
        try Data("garbage".utf8).write(to: file)

        #expect(store.load(.gameList, as: [GameListGame].self) == nil)
        // Corruption is cleared so the next sync starts clean.
        #expect(FileManager.default.fileExists(atPath: file.path) == false)
    }

    @Test("Clearing removes the payload")
    func clearing() {
        let (store, dir, _) = makeStore()
        defer { try? FileManager.default.removeItem(at: dir) }

        store.save(sampleGames, to: .gameList)
        store.save(sampleGames, to: .consoleList)
        store.clearAll()

        #expect(store.load(.gameList, as: [GameListGame].self) == nil)
        #expect(store.load(.consoleList, as: [GameListGame].self) == nil)
    }

    @Test("Slots are independent")
    func slotsIndependent() {
        let (store, dir, _) = makeStore()
        defer { try? FileManager.default.removeItem(at: dir) }

        store.save(sampleGames, to: .gameList)
        #expect(store.load(.gameList, as: [GameListGame].self) != nil)
        #expect(store.load(.consoleList, as: [GameListGame].self) == nil)
    }

    // MARK: - Migration

    @Test("A legacy UserDefaults blob is adopted without triggering a re-sync")
    func migratesLegacyBlob() {
        let suite = UserDefaults(suiteName: "ra-migrate-\(UUID().uuidString)")!
        let (store, dir, _) = makeStore(defaults: suite)
        defer { try? FileManager.default.removeItem(at: dir) }

        // Legacy format: the bare array, plus a separate cacheDate key.
        let threeDaysAgo = Date().addingTimeInterval(-3 * 86_400)
        suite.set(Fixtures.gameList, forKey: GameListStore.Slot.gameList.legacyDefaultsKey)
        suite.set(threeDaysAgo.timeIntervalSince1970, forKey: "cacheDate")

        store.migrateLegacyBlobIfNeeded(.gameList, as: [GameListGame].self)

        // Readable from the new store, and still fresh — the user must not be
        // forced through another multi-minute game-list sync after updating.
        let loaded = store.load(.gameList, as: [GameListGame].self, ttl: GameListStore.gameListTTL)
        #expect(loaded?.count == 1)
        #expect(suite.data(forKey: GameListStore.Slot.gameList.legacyDefaultsKey) == nil)
    }

    @Test("Migration is a no-op when there is nothing to migrate")
    func migrationNoOp() {
        let (store, dir, _) = makeStore()
        defer { try? FileManager.default.removeItem(at: dir) }

        store.migrateLegacyBlobIfNeeded(.gameList, as: [GameListGame].self)
        #expect(store.load(.gameList, as: [GameListGame].self) == nil)
    }

    @Test("Migration does not clobber a payload the store already holds")
    func migrationDoesNotClobber() {
        let suite = UserDefaults(suiteName: "ra-migrate-\(UUID().uuidString)")!
        let (store, dir, _) = makeStore(defaults: suite)
        defer { try? FileManager.default.removeItem(at: dir) }

        store.save(sampleGames, to: .gameList)
        suite.set(Fixtures.emptyArray, forKey: GameListStore.Slot.gameList.legacyDefaultsKey)

        store.migrateLegacyBlobIfNeeded(.gameList, as: [GameListGame].self)

        #expect(store.load(.gameList, as: [GameListGame].self)?.count == 1)
        #expect(suite.data(forKey: GameListStore.Slot.gameList.legacyDefaultsKey) == nil)
    }
}

@Suite("KeychainStore", .serialized)
struct KeychainStoreTests {

    private func cleanSlate() {
        KeychainStore.delete(.webAPIKey)
    }

    @Test("Round-trips a value")
    func roundTrip() {
        cleanSlate()
        defer { cleanSlate() }

        #expect(KeychainStore.save("secret-key", for: .webAPIKey))
        #expect(KeychainStore.read(.webAPIKey) == "secret-key")
    }

    @Test("Saving twice updates rather than duplicating")
    func overwrite() {
        cleanSlate()
        defer { cleanSlate() }

        KeychainStore.save("first", for: .webAPIKey)
        KeychainStore.save("second", for: .webAPIKey)

        #expect(KeychainStore.read(.webAPIKey) == "second")
    }

    @Test("Reading a missing item yields nil")
    func readMissing() {
        cleanSlate()
        #expect(KeychainStore.read(.webAPIKey) == nil)
    }

    @Test("Saving an empty value clears the item")
    func emptyClears() {
        cleanSlate()
        defer { cleanSlate() }

        KeychainStore.save("something", for: .webAPIKey)
        KeychainStore.save("", for: .webAPIKey)

        #expect(KeychainStore.read(.webAPIKey) == nil)
    }

    @Test("Deleting a missing item succeeds")
    func deleteMissingIsFine() {
        cleanSlate()
        #expect(KeychainStore.delete(.webAPIKey))
    }

    // MARK: - Migration

    @Test("A key left in UserDefaults moves to the Keychain and is removed")
    func migratesLegacyKey() {
        cleanSlate()
        defer { cleanSlate() }

        let suite = UserDefaults(suiteName: "ra-keychain-\(UUID().uuidString)")!
        suite.set("legacy-key", forKey: "webAPIKey")

        let result = KeychainStore.migrateLegacyAPIKeyIfNeeded(defaults: suite)

        #expect(result == "legacy-key")
        #expect(KeychainStore.read(.webAPIKey) == "legacy-key")
        // The plaintext copy must not be left behind.
        #expect(suite.string(forKey: "webAPIKey") == nil)
    }

    @Test("With nothing to migrate the existing Keychain value is returned")
    func migrationFallsBackToKeychain() {
        cleanSlate()
        defer { cleanSlate() }

        KeychainStore.save("already-here", for: .webAPIKey)
        let suite = UserDefaults(suiteName: "ra-keychain-\(UUID().uuidString)")!

        #expect(KeychainStore.migrateLegacyAPIKeyIfNeeded(defaults: suite) == "already-here")
    }

    @Test("A signed-out user migrates to nothing")
    func migrationWithNoCredentials() {
        cleanSlate()
        let suite = UserDefaults(suiteName: "ra-keychain-\(UUID().uuidString)")!

        #expect(KeychainStore.migrateLegacyAPIKeyIfNeeded(defaults: suite) == nil)
    }
}
