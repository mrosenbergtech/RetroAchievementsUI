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
        if network.userGameCompletionProgress?.results.count ?? -1 > 0 {
            NavigationView {
                Form(){
                    ForEach(network.consolesCache?.consoles.sorted { $0.name.lowercased() < $1.name.lowercased()} ?? []) { console in
                        if network.userGameCompletionProgress!.results.filter({ $0.consoleName == console.name}).count > 0 {
                            Section(header: Text(console.name)){
                                ForEach(network.userGameCompletionProgress!.results.filter { $0.consoleName == console.name}.sorted { $0.title.lowercased() < $1.title.lowercased()}){ game in
                                    NavigationLink(destination: GameSummaryView(hardcoreMode: $hardcoreMode, gameID: game.id))
                                    {
                                        GameSummaryPreviewView(hardcoreMode: $hardcoreMode, imageIconString: game.imageIcon, gameTitle: game.title, gameConsoleName: game.consoleName, maxPossible: game.maxPossible, numAwardedHardcore: game.numAwardedHardcore, numAwarded: game.numAwarded, highestAwardKind: game.highestAwardKind)
                                    }
                                }
                            }
                        }
                        
                    }

                }
                .navigationBarTitle("My Games")
                .navigationBarHidden(true)
            }
            .refreshable {
                Task {
                    await network.getUserGameCompletionProgress()
                }
            }
        } else if network.userGameCompletionProgress?.count ?? -1 == 0 {
            Text("No Games Found - Give One A Try!")
        } else {
            ProgressView()
        }
    }
}

#Preview {
    @Previewable @State var hardcoreMode: Bool = true
    let network = Network()
    Task {
        await network.authenticateCredentials(webAPIUsername: debugWebAPIUsername, webAPIKey: debugWebAPIKey)
        await network.getUserGameCompletionProgress()
    }
    return MyGamesView(hardcoreMode: $hardcoreMode)
        .environmentObject(network)
}
