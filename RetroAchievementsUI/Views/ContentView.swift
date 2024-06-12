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
    @State var shouldShowLoginSheet: Bool = false
    
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
                
                // TODO: Move to Sheet
                SettingsView(webAPIUsername: $webAPIUsername, webAPIKey: $webAPIKey, hardcoreMode: $hardcoreMode, shouldShowLoginSheet: $shouldShowLoginSheet)
                    .tabItem {
                        Label(
                            title: { Text("Settings") },
                            icon: { Image(systemName: "gear.circle") }
                        )
                    }
                    .tag(4)
                    .onAppear {
                        selectedTab = 4
                    }
            }
            .sheet(isPresented: $shouldShowLoginSheet) {
                print("Login Sheet Dismissed!")
                shouldShowLoginSheet = false
            } content: {
                VStack{
                    if network.webAPIAuthenticated{
                        HStack{
                            
                            Spacer()
                            
                            Button("Done") {
                                shouldShowLoginSheet = false
                            }
                            .padding()
                            
                        }
                    }
                    
                    RetroAchievementsLoginView(webAPIUsername: $webAPIUsername, webAPIKey: $webAPIKey, shouldShowLoginSheet: $shouldShowLoginSheet)

                }
            }
            .onAppear(){
                if !network.webAPIAuthenticated {
                    shouldShowLoginSheet = true
                }
            }
        } else {
            ProgressView()
            
        }
    }
}

#Preview {
    @State var webAPIUsername = debugWebAPIUsername
    @State var webAPIKey = debugWebAPIKey
    @State var hardcoreMode = true
    let network = Network()
    network.authenticateCredentials(webAPIUsername: webAPIUsername, webAPIKey: webAPIKey)
    return ContentView(webAPIUsername: $webAPIUsername, webAPIKey: $webAPIKey,
    hardcoreMode: $hardcoreMode)
        .environmentObject(network)
}
