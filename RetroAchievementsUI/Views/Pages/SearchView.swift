//
//  SearchView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//
//  Catalogue search results. Content only: this lives inside BrowseView,
//  which owns the navigation stack and the search field — searching and
//  browsing by console are the same job, so they share one tab.

import SwiftUI

struct SearchResultsView: View {
    @EnvironmentObject var network: Network
    @Environment(\.selectedGameID) var selectedGameID: Binding<GameSheetItem?>
    @Binding var hardcoreMode: Bool
    @Binding var showUnofficial: Bool

    /// Supplied by BrowseView's search field.
    let searchQuery: String

    /// The catalogue runs to tens of thousands of games. Showing all of them
    /// for an empty query meant building a vast array on every render for a
    /// list nobody scrolls; an empty query now shows a prompt instead.
    private var searchResults: [GameListGame] {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }

        var matches = network.gameList.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed)
        }
        if !showUnofficial {
            matches = matches.filter { !$0.title.starts(with: "~") }
        }

        // Prefix matches first — searching "mario" should surface "Mario Kart"
        // before "Dr. Mario".
        return matches.sorted { a, b in
            let aPrefix = a.title.lowercased().hasPrefix(trimmed.lowercased())
            let bPrefix = b.title.lowercased().hasPrefix(trimmed.lowercased())
            if aPrefix != bPrefix { return aPrefix }
            return a.title.lowercased() < b.title.lowercased()
        }
    }

    private var isCatalogueReady: Bool { !network.gameList.isEmpty }

    var body: some View {
        Group {
            if !isCatalogueReady {
                syncing
            } else if searchResults.isEmpty {
                ContentUnavailableView.search(text: searchQuery)
            } else {
                results
            }
        }
        .background(Color.raSurface)
    }

    // MARK: - States

    private var results: some View {
        // A List (not a ScrollView) so cells are recycled — result sets can run
        // to thousands of rows.
        List {
            Section {
                ForEach(searchResults) { game in
                    Button {
                        selectedGameID.wrappedValue = GameSheetItem(id: game.id)
                    } label: {
                        ConsoleGameDetailView(gameListGame: game,
                                              hardcoreMode: $hardcoreMode,
                                              showConsoleName: true)
                    }
                    .buttonStyle(RowPressStyle())
                    .listRowBackground(Color.raSurfaceRaised)
                }
            } header: {
                Text("\(searchResults.count) result\(searchResults.count == 1 ? "" : "s")")
                    .font(.raStatSmall)
                    .foregroundStyle(Color.raTextTertiary)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private var syncing: some View {
        VStack(spacing: 16) {
            ProgressView().controlSize(.large)
            VStack(spacing: 4) {
                Text("Building the game library…")
                    .font(.raBody)
                    .foregroundStyle(Color.raTextPrimary)
                if network.isFetchingFullGameList {
                    Text("\(Int(network.syncProgressPercentage))%")
                        .font(.raStatSmall)
                        .foregroundStyle(Color.raTextTertiary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    @Previewable @State var hardcoreMode: Bool = true
    @Previewable @State var showUnofficial: Bool = false

    let network = Network()
    Task {
        await network.authenticateCredentials(webAPIUsername: debugWebAPIUsername, webAPIKey: debugWebAPIKey)
    }

    return SearchResultsView(hardcoreMode: $hardcoreMode,
                             showUnofficial: $showUnofficial,
                             searchQuery: "mario")
        .environmentObject(network)
}
