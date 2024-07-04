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
                        HStack{
                            Image(systemName: "trophy.circle")
                            Text(String(hardcoreMode ? network.gameSummaryCache[gameID]!.numAwardedToUserHardcore : network.gameSummaryCache[gameID]!.numAwardedToUser) + " | " + String(network.gameSummaryCache[gameID]!.numAchievements))
                                .multilineTextAlignment(.center)
                                .font(.footnote)
                        }
                            
                        ProgressView(value: Float(hardcoreMode ? network.gameSummaryCache[gameID]!.numAwardedToUserHardcore : network.gameSummaryCache[gameID]!.numAwardedToUser) / Float(network.gameSummaryCache[gameID]!.numAchievements))
                            .padding(.horizontal)
                    } else {
                        Text("No Achievements!")
                    }
                    
                }
                
                Image(systemName: "checkmark.circle")
                    .foregroundStyle(highestAwardColor(highestAwardKind: network.gameSummaryCache[gameID]!.highestAwardKind))
            }
        }  else {
            ProgressView()
                .task {
                    await network.getGameSummary(gameID: gameID)
                }
        }
    }
}

func highestAwardColor(highestAwardKind: String?) -> Color {
    switch highestAwardKind {
    case "mastered":
        return .yellow
    case "completed":
        return .orange
    case "beaten-hardcore":
        return .green
    case "beaten-softcore":
        return .blue
    default:
        return .gray
    }
}
 
#Preview {
    @State var hardcoreMode: Bool = true
    let network = Network()
    Task {
        await network.authenticateCredentials(webAPIUsername: debugWebAPIUsername, webAPIKey: debugWebAPIKey)
        await network.getGameSummary(gameID: 10003)
    }
    
    return GameSummaryHeaderView(hardcoreMode: $hardcoreMode, gameID: 10003).environmentObject(network)
}

