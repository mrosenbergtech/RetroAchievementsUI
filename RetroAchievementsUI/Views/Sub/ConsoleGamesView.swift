//
//  MyGamesView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//

import SwiftUI

struct ConsoleGamesView: View {
    @EnvironmentObject var network: Network
    @Binding var hardcoreMode: Bool
    var consoleID: Int
    
    var body: some View {
        if network.gameList.count > 0 {
                Form(){
                    ForEach(network.gameList.filter { $0.consoleID == consoleID } .sorted { $0.title.lowercased() < $1.title.lowercased()}) { game in
                        NavigationLink(destination: GameSummaryView(hardcoreMode: $hardcoreMode, gameID: game.id)
                            .task {
                                await network.getGameSummary(gameID: game.id)
                            })
                            {
                                ConsoleGameDetailView(gameListGame: game, hardcoreMode: $hardcoreMode)
                            }
                            .navigationBarTitle(network.consolesCache?.getConsoleDataByID(consoleID: consoleID).name ?? "Error")
                    }
                }
            
        } else {
            ProgressView()
        }
            
    }
}

// Preview Bug Likely From Use of Dictionary (Empty Dictionary Lieral?)
#Preview {
    @Previewable @State var hardcoreMode: Bool = true
    let network = Network()
    Task {
        await network.authenticateCredentials(webAPIUsername: debugWebAPIUsername, webAPIKey: debugWebAPIKey)
    }
    return ConsoleGamesView(hardcoreMode: $hardcoreMode, consoleID: 2)
        .environmentObject(network)
}
