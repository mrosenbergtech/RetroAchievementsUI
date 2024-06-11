//
//  GameSummaryView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//

import SwiftUI

struct GameSummaryView: View {
    @EnvironmentObject var network: Network
    @Binding var hardcoreMode: Bool
    var gameID: Int
    
    var body: some View {
        if network.gameSummaryCache[gameID] != nil {
            VStack {
                Text(network.gameSummaryCache[gameID]!.title)
                    .bold()
                    .scaledToFill()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .padding(.horizontal)
                
                AsyncImage(url: URL(string: "https://retroachievements.org/" + (network.gameSummaryCache[gameID]!.imageIcon)))
                { phase in
                    switch phase {
                    case .failure:
                        Image(systemName: "photo")
                            .font(.largeTitle)
                    case .success(let image):
                        image
                    default:
                        ProgressView()
                    }
                }
                .clipShape(.rect(cornerRadius: 10))
                .padding(.bottom)
                
                Text("Unlocked: " + String(hardcoreMode ? network.gameSummaryCache[gameID]!.numAwardedToUserHardcore : network.gameSummaryCache[gameID]!.numAwardedToUser) + " | " + String(network.gameSummaryCache[gameID]!.numAchievements))
                    .multilineTextAlignment(.center)
                    .font(.footnote)
                    .bold()
                
                ProgressView(value: Float(hardcoreMode ? network.gameSummaryCache[gameID]!.numAwardedToUserHardcore : network.gameSummaryCache[gameID]!.numAwardedToUser) / Float(network.gameSummaryCache[gameID]!.numAchievements))
                    .padding(.horizontal)
                
                Spacer()
                
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

