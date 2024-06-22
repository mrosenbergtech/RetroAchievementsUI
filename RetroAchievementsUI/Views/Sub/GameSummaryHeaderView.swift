//
//  GameSummaryHeaderView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/20/24.
//

import SwiftUI
import Kingfisher

struct GameSummaryHeaderView: View {
    @EnvironmentObject var network: Network
    @Binding var hardcoreMode: Bool
    var gameID: Int
    
    var body: some View {
        if network.gameSummaryCache[gameID] != nil {
            HStack{
                KFImage(URL(string: "https://retroachievements.org/" + (network.gameSummaryCache[gameID]!.imageIcon)))
                .resizable()
                .clipShape(.rect(cornerRadius: 10))
                .frame(width: 64, height: 64)
                
                VStack {
                    ScrollingText(text: network.gameSummaryCache[gameID]!.title, font: .boldSystemFont(ofSize: 15), leftFade: 15, rightFade: 15, startDelay: 1, alignment: .center)
                        .padding(.horizontal)
                    
                    Text(network.gameSummaryCache[gameID]!.consoleName)
                        .foregroundStyle(.gray)
                        .font(.footnote)
                        .lineLimit(1)
                        .padding(.horizontal)
                    
                    if network.gameSummaryCache[gameID]!.numAchievements > 0 {
                        Text("Unlocked: " + String(hardcoreMode ? network.gameSummaryCache[gameID]!.numAwardedToUserHardcore : network.gameSummaryCache[gameID]!.numAwardedToUser) + " | " + String(network.gameSummaryCache[gameID]!.numAchievements))
                            .multilineTextAlignment(.center)
                            .font(.footnote)
                        
                        ProgressView(value: Float(hardcoreMode ? network.gameSummaryCache[gameID]!.numAwardedToUserHardcore : network.gameSummaryCache[gameID]!.numAwardedToUser) / Float(network.gameSummaryCache[gameID]!.numAchievements))
                            .padding(.horizontal)
                    } else {
                        Text("No Achievements!")
                    }
                }
            }
            .padding(.horizontal)
        }  else {
            ProgressView()
                .onAppear {
                    network.getGameSummary(gameID: gameID)
                }
        }
    }
}
 
#Preview {
    @State var hardcoreMode: Bool = true
    let network = Network()
    network.authenticateCredentials(webAPIUsername: debugWebAPIUsername, webAPIKey: debugWebAPIKey)
    network.getGameSummary(gameID: 10003)
    return GameSummaryHeaderView(hardcoreMode: $hardcoreMode, gameID: 10003).environmentObject(network)
}

