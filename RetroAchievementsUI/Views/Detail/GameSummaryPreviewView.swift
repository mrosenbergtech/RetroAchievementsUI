//
//  GameSummaryPreviewView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/20/24.
//

import SwiftUI
import Kingfisher

struct GameSummaryPreviewView: View {
    @EnvironmentObject var network: Network
    @Binding var hardcoreMode: Bool
    let imageIconString: String
    let gameTitle: String
    let gameConsoleName: String
    let maxPossible: Int
    let numAwardedHardcore: Int
    let numAwarded: Int
    let highestAwardKind: String?
    
    var body: some View {
        HStack{
            KFImage(URL(string: "https://retroachievements.org/" + imageIconString))
            .resizable()
            .clipShape(.rect(cornerRadius: 10))
            .frame(width: 64, height: 64)
            
            VStack {
                ScrollingText(text: gameTitle, font: .boldSystemFont(ofSize: 15), leftFade: 15, rightFade: 15, startDelay: 1, alignment: .center)
                    .padding(.horizontal)
                
                Text(gameConsoleName)
                    .foregroundStyle(.gray)
                    .font(.footnote)
                    .lineLimit(1)
                    .padding(.horizontal)
                
                if maxPossible > 0 {
                    HStack{
                        Image(systemName: "trophy.circle")
                        Text(String(hardcoreMode ? numAwardedHardcore : numAwarded) + " | " + String(maxPossible))
                            .multilineTextAlignment(.center)
                            .font(.footnote)
                    }
                        
                    ProgressView(value: Float(hardcoreMode ? numAwardedHardcore : numAwarded) / Float(maxPossible)
                    )
                    .padding(.horizontal)
                } else {
                    Text("No Achievements!")
                }
                
            }
            
            Image(systemName: "checkmark.circle")
                .foregroundStyle(highestAwardColor(highestAwardKind: highestAwardKind))
        }
    }
}
 
#Preview {
    @State var hardcoreMode: Bool = true
    let network = Network()
    Task {
        await network.authenticateCredentials(webAPIUsername: debugWebAPIUsername, webAPIKey: debugWebAPIKey)
        await network.getGameSummary(gameID: 10003)
    }
    
    return GameSummaryPreviewView(hardcoreMode: $hardcoreMode, imageIconString: "/Images/047942.png", gameTitle: "Super Mario 64", gameConsoleName: "Nintendo 64", maxPossible: 114, numAwardedHardcore: 59, numAwarded: 59, highestAwardKind: "beaten-hardcore")
        .environmentObject(network)
}

