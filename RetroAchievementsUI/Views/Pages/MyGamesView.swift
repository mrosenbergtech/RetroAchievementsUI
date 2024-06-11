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
        if network.userGameCompletionProgress != nil {
            NavigationView {
                Form(){
                    ForEach(network.consolesCache.consoles.sorted { $0.name.lowercased() < $1.name.lowercased()}) { console in
                        if network.userGameCompletionProgress!.results.filter({ $0.consoleName == console.name}).count > 0 {
                            Section(header: Text(console.name)){
                                ForEach(network.userGameCompletionProgress!.results.filter { $0.consoleName == console.name}.sorted { $0.title.lowercased() < $1.title.lowercased()}){ game in
                                    NavigationLink(destination: GameSummaryView(hardcoreMode: $hardcoreMode, gameID: game.id))
                                    {
                                        UserGameCompletionProgressDetailView(game: game, hardcoreMode: $hardcoreMode)
                                    }
                                }
                            }
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
    network.authenticateCredentials(webAPIUsername: debugWebAPIUsername, webAPIKey: debugWebAPIKey)
    network.getUserGameCompletionProgress()
    @State var hardcoreMode: Bool = true
    return MyGamesView(hardcoreMode: $hardcoreMode)
        .environmentObject(network)
}
