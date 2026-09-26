//
//  TipStoreTests.swift
//  RetroAchievementsUITests
//
//  The tip jar's own rules — what "has tipped" means and where it is kept.
//  StoreKit's purchase flow is not exercised here: it needs a StoreKit test
//  session, and the logic worth protecting is the record, not Apple's sheet.
//

import Foundation
import Testing
@testable import RetroAchievementsUI

@Suite("Tip jar")
struct TipStoreTests {

    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "ra-tips-\(UUID().uuidString)")!
    }

    @Test("A fresh install has not tipped")
    @MainActor
    func startsUntipped() {
        // syncsToKeychain: false stands in for iCloud Keychain being off,
        // which must not be read as "has tipped".
        let store = TipStore(defaults: makeDefaults(), syncsToKeychain: false)
        #expect(!store.hasTipped)
        #expect(store.products.isEmpty)
    }

    @Test("Recording a tip sticks, and survives a new store over the same defaults")
    @MainActor
    func recordsTip() {
        let defaults = makeDefaults()
        let store = TipStore(defaults: defaults, syncsToKeychain: false)

        store.recordTip()

        #expect(store.hasTipped)
        // A relaunch reads it back rather than forgetting.
        #expect(TipStore(defaults: defaults, syncsToKeychain: false).hasTipped)
    }

    @Test("Tipping twice is not a problem")
    @MainActor
    func tipsAreRepeatable() {
        // Consumables can be bought again and again; the badge is a boolean,
        // so a second tip must simply be a no-op rather than an error.
        let store = TipStore(defaults: makeDefaults(), syncsToKeychain: false)

        store.recordTip()
        store.recordTip()

        #expect(store.hasTipped)
    }

    @Test("A tip recorded only in the Keychain still shows the badge")
    @MainActor
    func readsFromKeychain() {
        // The reinstall case: local defaults are empty, the synchronizable
        // Keychain item remembers.
        KeychainStore.save("1", for: .hasTipped)
        defer { KeychainStore.delete(.hasTipped) }

        #expect(TipStore(defaults: makeDefaults(), syncsToKeychain: true).hasTipped)
    }

    @Test("Refreshing copies a tip made elsewhere into local storage")
    @MainActor
    func refreshCachesLocally() {
        let defaults = makeDefaults()
        KeychainStore.delete(.hasTipped)
        let store = TipStore(defaults: defaults, syncsToKeychain: true)
        #expect(!store.hasTipped)

        // A tip on another device arrives through iCloud Keychain; this
        // device picks it up and keeps a local copy, so the badge survives
        // iCloud Keychain being switched off later.
        KeychainStore.save("1", for: .hasTipped)
        defer { KeychainStore.delete(.hasTipped) }
        store.refreshFromCloud()

        #expect(store.hasTipped)
        #expect(defaults.bool(forKey: TipStore.hasTippedKey))
    }

    @Test("Recording a tip writes the Keychain item that survives a reinstall")
    @MainActor
    func recordWritesKeychain() {
        KeychainStore.delete(.hasTipped)
        defer { KeychainStore.delete(.hasTipped) }

        TipStore(defaults: makeDefaults(), syncsToKeychain: true).recordTip()

        // A reinstall clears UserDefaults but not the Keychain.
        #expect(KeychainStore.read(.hasTipped) == "1")
        #expect(TipStore(defaults: makeDefaults(), syncsToKeychain: true).hasTipped)
    }

    @Test("The badge shows the highest tier tipped")
    @MainActor
    func badgeFollowsTopTier() {
        let store = TipStore(defaults: makeDefaults(), syncsToKeychain: false)

        store.recordTip(tier: TipStore.productIDs[0])
        #expect(store.badgeSymbol == TipStore.symbolName(for: TipStore.productIDs[0]))

        store.recordTip(tier: TipStore.productIDs[2])
        #expect(store.badgeSymbol == TipStore.symbolName(for: TipStore.productIDs[2]))
    }

    @Test("A smaller later tip does not demote the badge")
    @MainActor
    func smallerTipDoesNotDemote() {
        // Someone who gave the top tier once and a small one later should
        // keep the better badge; anything else punishes tipping again.
        let store = TipStore(defaults: makeDefaults(), syncsToKeychain: false)

        store.recordTip(tier: TipStore.productIDs[2])
        store.recordTip(tier: TipStore.productIDs[0])

        #expect(store.topTipTier == TipStore.productIDs[2])
    }

    @Test("A tip recorded before tiers existed still earns a badge")
    func legacyTipFallsBackToHeart() {
        // Builds before this one stored only the boolean, so the tier is
        // unknown — they contributed and the badge must still say so.
        #expect(TipStore.badgeSymbol(forTopTier: nil) == "heart.fill")
        #expect(TipStore.badgeSymbol(forTopTier: "com.example.unknown") == "heart.fill")
    }

    @Test("Tier ranking follows price order")
    func ranksTiers() {
        #expect(TipStore.isHigherTier(TipStore.productIDs[1], than: TipStore.productIDs[0]))
        #expect(!TipStore.isHigherTier(TipStore.productIDs[0], than: TipStore.productIDs[1]))
        // Anything beats nothing.
        #expect(TipStore.isHigherTier(TipStore.productIDs[0], than: nil))
    }

    @Test("Each tier draws its own symbol")
    func tiersHaveDistinctSymbols() {
        let symbols = TipStore.productIDs.map(TipStore.symbolName(for:))

        // Three of the same icon reads as one repeated row rather than a
        // ladder, which is the whole point of having tiers.
        #expect(Set(symbols).count == 3)
        #expect(symbols.allSatisfy { !$0.isEmpty })
    }

    @Test("An unknown product still draws something")
    func unknownProductFallsBack() {
        // A tier added in App Store Connect before the app ships would
        // otherwise render a blank row.
        #expect(TipStore.symbolName(for: "com.example.unknown.tier") == "heart.fill")
    }

    @Test("The three products are the ones created in App Store Connect")
    func productIDsMatchTheStore() {
        // A typo here is invisible until the tip jar silently fails to load
        // on a real device, so it is worth pinning.
        #expect(TipStore.productIDs == [
            "com.mrosenbergtech.RetroAchievementsUI.tip.small",
            "com.mrosenbergtech.RetroAchievementsUI.tip.medium",
            "com.mrosenbergtech.RetroAchievementsUI.tip.large",
        ])
    }
}
