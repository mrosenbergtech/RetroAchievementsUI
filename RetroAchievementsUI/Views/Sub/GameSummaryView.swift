//
//  GameSummaryView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//

import SwiftUI
import Kingfisher

struct GameSummaryView: View {
    @EnvironmentObject var network: Network
    @Binding var hardcoreMode: Bool
    var gameID: Int
    
    var body: some View {
        if network.gameSummaryCache[gameID] != nil {
            Form {
                GameSummaryPreviewView(hardcoreMode: $hardcoreMode, gameID: gameID)
                
                AchievementsView(hardcoreMode: $hardcoreMode, gameSummary: network.gameSummaryCache[gameID]!)
            }
        }  else {
            ProgressView()
                .onAppear {
                    network.getGameSummary(gameID: gameID)
                }
        }
    }
}
 
// Preview Bug Likely From Use of Dictionary (Empty Dictionary Lieral?)
#Preview {
    @State var hardcoreMode: Bool = true
    let network = Network()
    network.authenticateCredentials(webAPIUsername: debugWebAPIUsername, webAPIKey: debugWebAPIKey)
    return GameSummaryView(hardcoreMode: $hardcoreMode, gameID: 10003).environmentObject(network)
}

