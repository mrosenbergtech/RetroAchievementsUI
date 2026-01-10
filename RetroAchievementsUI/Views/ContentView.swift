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
    @Binding var unofficialSearchResults: Bool
    
    @State var selectedTab: Int = 1
    @State var shouldShowLoginSheet: Bool = false
    
    // Global state for triggering the Game Summary Sheet
    @State private var selectedGameID: GameSheetItem? = nil
    
    var body: some View {
        Group {
            if network.webAPIAuthenticated {
                authenticatedInterface
            } else {
                loadingOrLoginInterface
            }
        }
        .onAppear {
            checkInitialAuth()
        }
    }
    
    private var authenticatedInterface: some View {
        TabView(selection: $selectedTab) {
            ProfileView(hardcoreMode: $hardcoreMode)
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(1)
            
            MyGamesView(hardcoreMode: $hardcoreMode)
                .tabItem {
                    Label("My Games", systemImage: "gamecontroller")
                }
                .tag(2)
            
            ConsolesView(hardcoreMode: $hardcoreMode)
                .tabItem {
                    Label("Consoles", systemImage: "arcade.stick.console")
                }
                .tag(3)
            
            SearchView(hardcoreMode: $hardcoreMode, unofficialSearchResults: $unofficialSearchResults)
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass.circle")
                }
                .tag(4)
            
            SettingsView(
                webAPIUsername: $webAPIUsername,
                webAPIKey: $webAPIKey,
                hardcoreMode: $hardcoreMode,
                unofficialSearchResults: $unofficialSearchResults,
                shouldShowLoginSheet: $shouldShowLoginSheet
            )
            .tabItem {
                Label("Settings", systemImage: "gear.circle")
            }
            .tag(5)
        }
        .environment(\.selectedGameID, $selectedGameID)
        .sheet(item: $selectedGameID) { item in
            // Use item.id to pass the actual Int to GameSummaryView
            GameSummaryView(hardcoreMode: $hardcoreMode, gameID: item.id)
                .presentationDetents([.fraction(0.92)])
                .presentationDragIndicator(.visible)
        }
        // iOS 17+ logic to handle post-login tab switch and sheet dismissal
        .onChange(of: network.webAPIAuthenticated) { oldValue, newValue in
            if newValue {
                // Wrap in withAnimation to smooth the transition to the Profile tab
                withAnimation {
                    selectedTab = 1
                }
                // Close the login sheet if it was open
                shouldShowLoginSheet = false
            }
        }
    }
    
    private var loadingOrLoginInterface: some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea()
            
            if !network.initialWebAPIAuthenticationCheckComplete {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Authenticating with RetroAchievements...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Color.clear
                    .onAppear {
                        shouldShowLoginSheet = true
                    }
                    .sheet(isPresented: $shouldShowLoginSheet) {
                        RetroAchievementsLoginView(
                            shouldShowLoginSheet: $shouldShowLoginSheet,
                            webAPIUsername: $webAPIUsername,
                            webAPIKey: $webAPIKey
                        )
                        .interactiveDismissDisabled()
                    }
            }
        }
    }
    
    private func checkInitialAuth() {
        if !webAPIUsername.isEmpty && !webAPIKey.isEmpty && !network.webAPIAuthenticated {
            Task {
                await network.authenticateCredentials(
                    webAPIUsername: webAPIUsername,
                    webAPIKey: webAPIKey
                )
            }
        } else if webAPIUsername.isEmpty {
            network.initialWebAPIAuthenticationCheckComplete = true
        }
    }
}

// MARK: - Required Extensions & Keys
// The Wrapper Struct
struct GameSheetItem: Identifiable {
    let id: Int
}

// The Environment Key
struct SelectedGameIDKey: EnvironmentKey {
    // Corrected to use GameSheetItem
    static let defaultValue: Binding<GameSheetItem?> = .constant(nil)
}

extension EnvironmentValues {
    var selectedGameID: Binding<GameSheetItem?> {
        get { self[SelectedGameIDKey.self] }
        set { self[SelectedGameIDKey.self] = newValue }
    }
}

extension Bool {
    var inverted: Self { !self }
}

#Preview {
    @Previewable @State var webAPIUsername = debugWebAPIUsername
    @Previewable @State var webAPIKey = debugWebAPIKey
    @Previewable @State var hardcoreMode = true
    @Previewable @State var unofficialSearchResults = false
    let network = Network()

    Task {
        await network.authenticateCredentials(webAPIUsername: webAPIUsername, webAPIKey: webAPIKey)
    }
    
    return ContentView(webAPIUsername: $webAPIUsername, webAPIKey: $webAPIKey, hardcoreMode: $hardcoreMode, unofficialSearchResults: $unofficialSearchResults)
        .environmentObject(network)
}
