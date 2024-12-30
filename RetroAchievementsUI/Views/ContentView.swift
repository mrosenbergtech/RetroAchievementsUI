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
    @State var shouldShowLoginSheet: Bool = true
    
    var body: some View {
        if network.webAPIAuthenticated {
            TabView(selection: $selectedTab) {
                ProfileView(network: _network, hardcoreMode: $hardcoreMode)
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
                
                ConsolesView(hardcoreMode: $hardcoreMode)
                    .tabItem {
                        Label(
                            title: { Text("Consoles") },
                            icon: { Image(systemName: "arcade.stick.console") }
                        )
                    }
                    .tag(3)
                    .onAppear {
                        selectedTab = 3
                    }
                
                SearchView(hardcoreMode: $hardcoreMode)
                    .tabItem {
                        Label(
                            title: { Text("Search") },
                            icon: { Image(systemName: "magnifyingglass.circle") }
                        )
                    }
                    .tag(4)
                    .onAppear {
                        selectedTab = 4
                    }
                
                // TODO: Move to Sheet
                SettingsView(webAPIUsername: $webAPIUsername, webAPIKey: $webAPIKey, hardcoreMode: $hardcoreMode, shouldShowLoginSheet: $shouldShowLoginSheet)
                    .tabItem {
                        Label(
                            title: { Text("Settings") },
                            icon: { Image(systemName: "gear.circle") }
                        )
                    }
                    .tag(5)
                    .onAppear {
                        selectedTab = 5
                    }
            }
        } else if !network.initialWebAPIAuthenticationCheckComplete {
            ProgressView()
        } else {
            ProgressView()
                .onAppear(){
                    shouldShowLoginSheet = true
                }
                .sheet(isPresented: $shouldShowLoginSheet) {
                    print("RA Login Sheet Dismissed!")
                } content: {
                    VStack{
                        RetroAchievementsLoginView(shouldShowLoginSheet: $shouldShowLoginSheet, webAPIUsername: $webAPIUsername, webAPIKey: $webAPIKey)
                    }
                    .interactiveDismissDisabled()
                }
        }
    }
}

extension Bool {
  var inverted: Self {
    get { !self }
    set { }
  }
}

#Preview {
    @Previewable @State var webAPIUsername = debugWebAPIUsername
    @Previewable @State var webAPIKey = debugWebAPIKey
    @Previewable @State var hardcoreMode = true
    let network = Network()
    Task {
        await network.authenticateCredentials(webAPIUsername: webAPIUsername, webAPIKey: webAPIKey)

    }
    return ContentView(webAPIUsername: $webAPIUsername, webAPIKey: $webAPIKey,
    hardcoreMode: $hardcoreMode)
        .environmentObject(network)
}
