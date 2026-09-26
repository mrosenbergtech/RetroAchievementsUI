//
//  TipStore.swift
//  RetroAchievementsUI
//
//  The tip jar: three consumables, bought as often as someone likes, granting
//  nothing but a "Contributed" badge in Settings.
//
//  Consumables are the right product type precisely because they unlock
//  nothing — but it means StoreKit keeps no record of them. A consumable does
//  not appear in `Transaction.currentEntitlements`, so "has tipped" cannot be
//  restored from the store and has to be remembered by the app.
//
//  It is remembered in the Keychain, alongside the credentials and
//  synchronizable for the same reason: someone who tipped and later
//  reinstalled should not have to tip again to see the badge. The Keychain
//  rather than iCloud's key-value store because a synchronizable Keychain
//  item needs no entitlement and no capability on the App ID, where the
//  key-value store needs both — and a boolean is not worth an entitlement.
//  UserDefaults is kept as the local fast path.
//
//  This is deliberately a soft claim: it is a thank-you, not an entitlement,
//  so it costs nothing if iCloud Keychain is off and it is not worth
//  defending against someone who wants the badge for free.
//

import Foundation
import StoreKit

@MainActor
final class TipStore: ObservableObject {

    /// Product IDs as created in App Store Connect. Order is display order.
    static let productIDs = [
        "com.mrosenbergtech.RetroAchievementsUI.tip.small",
        "com.mrosenbergtech.RetroAchievementsUI.tip.medium",
        "com.mrosenbergtech.RetroAchievementsUI.tip.large",
    ]

    /// What a tip row needs to draw itself.
    ///
    /// A value type rather than StoreKit's `Product`, which cannot be
    /// constructed outside StoreKit — so previews, tests and the App Store
    /// review-screenshot capture could not show this UI at all otherwise.
    struct TipProduct: Identifiable, Equatable {
        let id: String
        let displayName: String
        /// Already localised by StoreKit: a reader in Japan sees yen.
        let displayPrice: String

        /// One symbol per tier, so the rows read as a ladder rather than
        /// three of the same thing. Keyed on the product ID rather than on
        /// position, because StoreKit's ordering is not guaranteed and a
        /// fourth tier would silently shift a positional mapping.
        var symbolName: String { TipStore.symbolName(for: id) }
    }

    /// Falls back to a heart for an ID this build does not know — a tier
    /// added in App Store Connect before the app ships should still draw.
    ///
    /// `nonisolated` because it is a pure lookup and TipProduct — a plain
    /// value type — reads it synchronously; the enclosing class is
    /// @MainActor, which would otherwise make this unreachable from there.
    nonisolated static func symbolName(for productID: String) -> String {
        switch productID {
        case productIDs[0]: return "centsign.circle.fill"   // Insert Coin
        case productIDs[1]: return "play.circle.fill"       // Continue
        case productIDs[2]: return "crown.fill"             // High Score
        default:            return "heart.fill"
        }
    }

    /// Empty until StoreKit answers — and it stays empty if the products are
    /// unavailable, which is how the Settings section knows to show nothing
    /// rather than a row of dead buttons.
    @Published private(set) var products: [TipProduct] = []

    /// The StoreKit products behind `products`, kept so a tap can buy one.
    private var storeProducts: [Product.ID: Product] = [:]
    @Published private(set) var isLoading = false
    @Published private(set) var purchasing: Product.ID?
    @Published private(set) var hasTipped: Bool
    /// Set after a successful purchase so the sheet can say thank you.
    @Published var justTipped = false
    @Published var failureMessage: String?

    private let defaults: UserDefaults
    /// Injectable so tests can exercise the local path without touching the
    /// shared Keychain.
    private let syncsToKeychain: Bool

    static let hasTippedKey = "hasTipped"

    init(defaults: UserDefaults = .standard, syncsToKeychain: Bool = true) {
        self.defaults = defaults
        self.syncsToKeychain = syncsToKeychain
        self.hasTipped = Self.readHasTipped(defaults: defaults,
                                            syncsToKeychain: syncsToKeychain)
    }

    /// True if either store says so. Either may be the only one that knows:
    /// the Keychain item survives a reinstall, UserDefaults answers instantly
    /// and works with iCloud Keychain switched off.
    private static func readHasTipped(defaults: UserDefaults,
                                      syncsToKeychain: Bool) -> Bool {
        if defaults.bool(forKey: hasTippedKey) { return true }
        return syncsToKeychain && KeychainStore.read(.hasTipped) == "1"
    }

    func loadProducts() async {
        guard products.isEmpty, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let loaded = try await Product.products(for: Self.productIDs)
            // StoreKit returns them in an unspecified order; price order is
            // the only one a reader would expect.
            let sorted = loaded.sorted { $0.price < $1.price }
            storeProducts = Dictionary(uniqueKeysWithValues: sorted.map { ($0.id, $0) })
            products = sorted.map {
                TipProduct(id: $0.id, displayName: $0.displayName,
                           displayPrice: $0.displayPrice)
            }
        } catch {
            // No message: a tip jar that cannot load is not worth an error in
            // the reader's face. The section simply does not appear.
            products = []
        }
    }

    /// Fills the list without StoreKit, for previews and for capturing the
    /// App Store review screenshots. Purchases are impossible in this state —
    /// `storeProducts` stays empty — so it cannot be mistaken for a live jar.
    func loadPlaceholderProducts(_ placeholders: [TipProduct]) {
        products = placeholders
    }

    func purchase(_ tip: TipProduct) async {
        guard purchasing == nil, let product = storeProducts[tip.id] else { return }
        purchasing = tip.id
        defer { purchasing = nil }

        do {
            switch try await product.purchase() {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    recordTip()
                    justTipped = true
                case .unverified:
                    // Unverified means the receipt failed StoreKit's own
                    // checks. Nothing is granted, so there is nothing to undo.
                    failureMessage = "That purchase couldn’t be verified."
                }
            case .userCancelled:
                break
            case .pending:
                // Ask to Buy and similar: it may complete later, so say so
                // rather than reporting a failure.
                failureMessage = "Your tip is pending approval."
            @unknown default:
                break
            }
        } catch {
            failureMessage = "Something went wrong: \(error.localizedDescription)"
        }
    }

    /// Consumables are finished immediately and never re-delivered, so this is
    /// the only record that a tip happened.
    func recordTip() {
        hasTipped = true
        defaults.set(true, forKey: Self.hasTippedKey)
        if syncsToKeychain { KeychainStore.save("1", for: .hasTipped) }
    }

    /// Picks up a tip made on another device, and caches it locally so the
    /// badge still shows if iCloud Keychain is later switched off.
    func refreshFromCloud() {
        guard Self.readHasTipped(defaults: defaults, syncsToKeychain: syncsToKeychain)
        else { return }
        hasTipped = true
        defaults.set(true, forKey: Self.hasTippedKey)
    }
}
