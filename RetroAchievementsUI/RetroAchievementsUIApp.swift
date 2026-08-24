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

    /// Child views still take a plain Binding<String>; writes are persisted to
    /// the Keychain here rather than in each call site.
    private var webAPIKeyBinding: Binding<String> {
        Binding(
            get: { webAPIKey },
            set: { newValue in
                webAPIKey = newValue
                KeychainStore.save(newValue, for: .webAPIKey)
            }
        )
    }

    var body: some Scene {
        WindowGroup {
            mainInterface
        }
    }

    private var mainInterface: some View {
        ContentView(webAPIUsername: $webAPIUsername, webAPIKey: webAPIKeyBinding, hardcoreMode: $hardcoreMode, showUnofficial: $showUnofficial)
            .environmentObject(network)
            .task {
                await network.authenticateCredentials(webAPIUsername: webAPIUsername, webAPIKey: webAPIKey)
            }
    }
}
