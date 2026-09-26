//
//  BrowseView.swift
//  RetroAchievementsUI
//
//  Finding a game you don't already track: by system, or by name.
//
//  Consoles and Search were two tabs doing one job, and five tabs crowded
//  iOS 26's floating tab bar — the selected item's capsule expands and
//  collides with its neighbours. Merged, they also read better: the console
//  grid is what "browse" looks like before you type, and results are what it
//  looks like after.
//
//  The search field belongs to this screen so the two halves cannot disagree
//  about what was typed; ConsolesListView and SearchResultsView are content
//  only.
//

import SwiftUI

struct BrowseView: View {
    @Binding var hardcoreMode: Bool
    @Binding var showUnofficial: Bool

    @State private var searchQuery = ""

    /// Two characters, matching SearchResultsView's own floor: one letter
    /// matches most of a catalogue running to tens of thousands of games.
    private var isSearching: Bool {
        searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
    }

    var body: some View {
        NavigationStack {
            Group {
                if isSearching {
                    SearchResultsView(hardcoreMode: $hardcoreMode,
                                      showUnofficial: $showUnofficial,
                                      searchQuery: searchQuery)
                } else {
                    ConsolesListView(hardcoreMode: $hardcoreMode,
                                     showUnofficial: $showUnofficial)
                }
            }
            .background(Color.raSurface)
            .navigationTitle(isSearching ? "Search" : "Browse")
            .navigationBarTitleDisplayMode(.large)
            // Always visible, not revealed by pulling down: search is half of
            // what this tab is for, and a field you have to know to scroll for
            // is a field most people never find.
            .searchable(text: $searchQuery,
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Search all supported games")
            // Lives here rather than on the console grid: a console tapped
            // from either half pushes onto this one stack.
            .navigationDestination(for: ConsoleRoute.self) { route in
                ConsoleGamesView(hardcoreMode: $hardcoreMode,
                                 showUnofficial: $showUnofficial,
                                 consoleID: route.consoleID)
            }
        }
    }
}

#Preview {
    @Previewable @State var hardcoreMode: Bool = true
    @Previewable @State var showUnofficial: Bool = false

    let network = Network()
    Task {
        await network.authenticateCredentials(webAPIUsername: debugWebAPIUsername,
                                              webAPIKey: debugWebAPIKey)
    }

    return BrowseView(hardcoreMode: $hardcoreMode, showUnofficial: $showUnofficial)
        .environmentObject(network)
}
