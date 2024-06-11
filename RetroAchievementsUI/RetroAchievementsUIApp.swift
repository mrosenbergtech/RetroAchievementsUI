//
//  RetroAchievementsUIApp.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//

import SwiftUI

// Debug Credentials
let debugWebAPIUsername: String = "username"
let debugWebAPIKey: String = "api_key"

@main
struct RetroAchievementsUIApp: App {
    @AppStorage("webAPIUsername") var webAPIUsername: String = ""
    @AppStorage("webAPIKey") var webAPIKey: String = ""
    @AppStorage("hardcoreMode") var hardcoreMode: Bool = true
    @ObservedObject var network = Network()
    
    init() {
        network.authenticateCredentials(webAPIUsername: webAPIUsername, webAPIKey: webAPIKey)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(webAPIUsername: $webAPIUsername, webAPIKey: $webAPIKey, hardcoreMode: $hardcoreMode)
                .environmentObject(network)
        }
    }
}
