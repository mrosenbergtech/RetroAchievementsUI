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
    @Binding var showUnofficial: Bool
    
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
            // Settings is no longer a tab — it opens as a sheet from the gear in
            // the profile header, which frees the tab bar for content.
            ProfileView(hardcoreMode: $hardcoreMode,
                        showUnofficial: $showUnofficial,
                        webAPIUsername: $webAPIUsername,
                        webAPIKey: $webAPIKey,
                        shouldShowLoginSheet: $shouldShowLoginSheet)
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(1)
            
            MyGamesView(hardcoreMode: $hardcoreMode, showUnofficial: $showUnofficial)
                .tabItem {
                    Label("My Games", systemImage: "gamecontroller")
                }
                .tag(2)
            
            ConsolesView(hardcoreMode: $hardcoreMode, showUnofficial: $showUnofficial)
                .tabItem {
                    Label("Consoles", systemImage: "arcade.stick.console")
                }
                .tag(3)
            
            SearchView(hardcoreMode: $hardcoreMode, showUnofficial: $showUnofficial)
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass.circle")
                }
                .tag(4)
        }
        .environment(\.selectedGameID, $selectedGameID)
        .sheet(item: $selectedGameID) { item in
            // Use item.id to pass the actual Int to GameSummaryView
            GameSummaryView(hardcoreMode: $hardcoreMode, gameID: item.id,
                                initialAchievementID: item.achievementID)
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
            Color.raSurface.ignoresSafeArea()

            if !network.initialWebAPIAuthenticationCheckComplete {
                VStack(spacing: 16) {
                    Image(systemName: "trophy.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.raAccent)
                    ProgressView()
                    Text("Signing in to RetroAchievements…")
                        .font(.raCaption)
                        .foregroundStyle(Color.raTextSecondary)
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
    /// When set, the game sheet opens straight onto this achievement's detail.
    /// Used by the profile's Recent Achievements deck, which should land on the
    /// achievement the user tapped rather than the top of the game.
    var achievementID: Int? = nil
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

#Preview {
    @Previewable @State var webAPIUsername = debugWebAPIUsername
    @Previewable @State var webAPIKey = debugWebAPIKey
    @Previewable @State var hardcoreMode = true
    @Previewable @State var showUnofficial = false
    let network = Network()

    Task {
        await network.authenticateCredentials(webAPIUsername: webAPIUsername, webAPIKey: webAPIKey)
    }
    
    return ContentView(webAPIUsername: $webAPIUsername, webAPIKey: $webAPIKey, hardcoreMode: $hardcoreMode, showUnofficial: $showUnofficial)
        .environmentObject(network)
}
