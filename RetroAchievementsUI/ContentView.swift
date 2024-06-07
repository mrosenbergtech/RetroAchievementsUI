//
//  ContentView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var network: Network
    @Binding var webAPIUsername: String
    @Binding var webAPIKey: String
    @Binding var hardcoreMode: Bool
    @State var selectedTab: Int = 1
    
    var body: some View {
        if network.initialWebAPIAuthenticationCheckComplete {
            TabView(selection: $selectedTab) {
                ProfileView(network: _network)
                    .tabItem {
                        Label(
                            title: { Text("Profile") },
                            icon: { Image(systemName: "person.circle") }
                        )
                    }
                    .tag(1)
                    .onAppear {
                        selectedTab = 1
                    }
                
                MyGamesView(network: _network, hardcoreMode: $hardcoreMode)
                    .tabItem {
                        Label(
                            title: { Text("My Games") },
                            icon: { Image(systemName: "gamecontroller") }
                        )
                    }
                    .tag(2)
                    .onAppear {
                        selectedTab = 2
                    }
                
                SettingsView(webAPIUsername: $webAPIUsername, webAPIKey: $webAPIKey, hardcoreMode: $hardcoreMode)
                    .tabItem {
                        Label(
                            title: { Text("Settings") },
                            icon: { Image(systemName: "gear.circle") }
                        )
                    }
                    .tag(3)
                    .onAppear {
                        selectedTab = 3
                    }
            }
            .onAppear(){
                if !network.webAPIAuthenticated { selectedTab = 3 }
            }
        } else {
            ProgressView()
        }
    }
}

#Preview {
    struct BindingViewExamplePreviewContainer : View {
        @State private var webAPIUsername = "username"
        @State private var webAPIKey = "api_key"
        @State private var hardcoreMode = true

       var body: some View {
           ContentView(webAPIUsername: $webAPIUsername, webAPIKey: $webAPIKey,
           hardcoreMode: $hardcoreMode)
               .environmentObject(Network())
       }
    }

    return BindingViewExamplePreviewContainer()
}
