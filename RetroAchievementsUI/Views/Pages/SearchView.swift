//
//  ProfileView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//

import SwiftUI
import Kingfisher

struct SearchView: View {
    @EnvironmentObject var network: Network
    @Binding var hardcoreMode: Bool
    @Binding var unofficialSearchResults: Bool
    @State private var searchQuery = ""
    
    var searchResults: [GameListGame] {
        if searchQuery.isEmpty {
            return unofficialSearchResults ? network.gameList : network.gameList.filter { !$0.title.starts(with: "~") }
        } else {
            return unofficialSearchResults ? network.gameList.filter { $0.title.lowercased().contains(searchQuery.lowercased()) } : network.gameList.filter { $0.title.lowercased().contains(searchQuery.lowercased()) && !$0.title.starts(with: "~") }
        }
    }
    
    var body: some View {
        if (network.gameList.count > 0) {
            NavigationStack {
                List {
                    ForEach(searchResults, id: \.self) { game in
                        NavigationLink {
                            GameSummaryView(hardcoreMode: $hardcoreMode, gameID: game.id)
                        } label: {
                            Text(game.title)
                        }
                    }
                }
                .navigationTitle("Supported Games")
            }
            .searchable(text: $searchQuery)
        } else {
            ProgressView()
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
