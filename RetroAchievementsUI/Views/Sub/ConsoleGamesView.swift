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
        if network.consoleGamesCache[consoleID] != nil {
                Form(){
                    ForEach(network.consoleGamesCache[consoleID]!.sorted { $0.title.lowercased() < $1.title.lowercased()}) { consoleGame in
                        NavigationLink(destination: GameSummaryView(hardcoreMode: $hardcoreMode, gameID: consoleGame.id).task {
                            await network.getGameSummary(gameID: consoleGame.id)
                        })
                        {
                            ConsoleGameDetailView(consoleGame: consoleGame, hardcoreMode: $hardcoreMode)
                        }
                    }
                }
            
        } else {
            ProgressView()
                .task {
                    await network.getGameForConsole(consoleID: consoleID)
                }
        }
            
    }
}

// Preview Bug Likely From Use of Dictionary (Empty Dictionary Lieral?)
#Preview {
    let network = Network()
    Task {
        await network.authenticateCredentials(webAPIUsername: debugWebAPIUsername, webAPIKey: debugWebAPIKey)
        await network.getGameForConsole(consoleID: 2)
    }
    @State var hardcoreMode: Bool = true
    return ConsoleGamesView(hardcoreMode: $hardcoreMode, consoleID: 2)
        .environmentObject(network)
}
