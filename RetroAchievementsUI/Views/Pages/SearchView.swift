//
//  SearchView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//

import SwiftUI
import Kingfisher

struct SearchView: View {
    @EnvironmentObject var network: Network
    @Environment(\.selectedGameID) var selectedGameID: Binding<GameSheetItem?>
    @Binding var hardcoreMode: Bool
    @Binding var unofficialSearchResults: Bool
    @State private var searchQuery = ""
    
    var searchResults: [GameListGame] {
        let baseList = unofficialSearchResults ? network.gameList : network.gameList.filter { !$0.title.starts(with: "~") }
        if searchQuery.isEmpty {
            return baseList
        } else {
            return baseList.filter { $0.title.lowercased().contains(searchQuery.lowercased()) }
        }
    }
    
    var body: some View {
        if (network.gameList.count > 0) {
            NavigationStack {
                List {
                    ForEach(searchResults, id: \.self) { game in
                        // Trigger sheet via Button
                        Button {
                            selectedGameID.wrappedValue = GameSheetItem(id: game.id)
                        } label: {
                            ConsoleGameDetailView(gameListGame: game, hardcoreMode: $hardcoreMode)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .navigationTitle("Supported Games")
            }
            .searchable(text: $searchQuery)
        } else {
            VStack {
                ProgressView()
                Text("Loading Game List...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
    }
}

#Preview {
    @Previewable @State var hardcoreMode: Bool = true
    @Previewable @State var unofficialSearchResults: Bool = false

    let network = Network()
    Task {
        await network.authenticateCredentials(webAPIUsername: debugWebAPIUsername, webAPIKey: debugWebAPIKey)
    }
    
    return SearchView(hardcoreMode: $hardcoreMode, unofficialSearchResults: $unofficialSearchResults)
        .environmentObject(network)
}
