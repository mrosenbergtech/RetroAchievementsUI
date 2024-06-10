//
//  MyGamesView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//

import SwiftUI

struct MyGamesView: View {
    @EnvironmentObject var network: Network
    @Binding var hardcoreMode: Bool
        
    var body: some View {
        if network.userGameCompletionProgress?.results != nil {
            NavigationView {
                Form(){
                    ForEach(network.userGameCompletionProgress!.results) { game in
                        NavigationLink(destination: GameSummaryView(hardcoreMode: $hardcoreMode, gameDetails: game))
                        {
                            UserGameCompletionProgressDetailView(game: game, hardcoreMode: $hardcoreMode)
                        }
                    }
                }
            }
        } else {
            ProgressView()
        }
    }
}

#Preview {
    let network = Network()
    network.authenticateRACredentials(webAPIUsername: debugWebAPIUsername, webAPIKey: debugWebAPIKey)
    @State var hardcoreMode: Bool = true
    return MyGamesView(hardcoreMode: $hardcoreMode)
        .environmentObject(network)
}
