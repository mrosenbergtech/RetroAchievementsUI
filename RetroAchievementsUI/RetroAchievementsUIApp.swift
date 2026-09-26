//
//  RetroAchievementsUIApp.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//

import SwiftUI

// Debug credentials used by #Preview blocks live in DebugCredentials.swift,
// which is gitignored. Copy DebugCredentials.example.swift to create it.

@main
struct RetroAchievementsUIApp: App {
    @AppStorage("webAPIUsername") var webAPIUsername: String = ""
    @AppStorage("hardcoreMode") var hardcoreMode: Bool = true
    @AppStorage("showUnofficial") var showUnofficial: Bool = false

    /// The API key is a secret, so unlike the other settings it lives in the
    /// Keychain rather than UserDefaults. Seeded once at launch, migrating any
    /// value left behind by a previous @AppStorage-backed build.
    @State private var webAPIKey: String = KeychainStore.migrateLegacyAPIKeyIfNeeded() ?? ""

    @StateObject private var network = Network()
    /// One tip jar for the whole app: Settings buys, the profile header
    /// shows the badge, and a tip has to light both up at once.
    @StateObject private var tips = TipStore()

    /// Child views still take a plain Binding<String>; writes are persisted to
    /// the Keychain here rather than in each call site. Both credentials go to
    /// the Keychain so iCloud Keychain carries them to the user's other
    /// devices; @AppStorage keeps the username for cheap local reads.
    private var webAPIKeyBinding: Binding<String> {
        Binding(
            get: { webAPIKey },
            set: { newValue in
                webAPIKey = newValue
                KeychainStore.save(newValue, for: .webAPIKey)
            }
        )
    }

    private var webAPIUsernameBinding: Binding<String> {
        Binding(
            get: { webAPIUsername },
            set: { newValue in
                webAPIUsername = newValue
                KeychainStore.save(newValue, for: .webAPIUsername)
            }
        )
    }

    var body: some Scene {
        WindowGroup {
            mainInterface
        }
    }

    private var mainInterface: some View {
        ContentView(webAPIUsername: webAPIUsernameBinding, webAPIKey: webAPIKeyBinding, hardcoreMode: $hardcoreMode, showUnofficial: $showUnofficial)
            .environmentObject(network)
            .environmentObject(tips)
            .task {
                // A new device gets the username from iCloud Keychain, where
                // @AppStorage — which is per-device — has nothing.
                if webAPIUsername.isEmpty,
                   let synced = KeychainStore.read(.webAPIUsername) {
                    webAPIUsername = synced
                }
                await network.authenticateCredentials(webAPIUsername: webAPIUsername, webAPIKey: webAPIKey)
            }
    }
}
