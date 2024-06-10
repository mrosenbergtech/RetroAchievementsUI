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
    @State var gameSummary: GameSummary?
    var gameDetails: GameDetails
    
    var body: some View {

            VStack {
//                ScrollingText(text: gameDetails.title, font: .boldSystemFont(ofSize: 30), leftFade: 15, rightFade: 15, startDelay: 5, alignment: .center)
//                    .padding(.horizontal)
                
                Text(gameDetails.title)
                    .bold()
                    .scaledToFill()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .padding(.horizontal)
                
                AsyncImage(url: URL(string: "https://retroachievements.org/" + (gameDetails.imageIcon)))
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
                
                Text("Unlocked: " + String(hardcoreMode ? gameDetails.numAwardedHardcore : gameDetails.numAwarded) + " | " + String(gameDetails.maxPossible))
                    .multilineTextAlignment(.center)
                    .font(.footnote)
                    .bold()
                
                ProgressView(value: Float(hardcoreMode ? gameDetails.numAwardedHardcore : gameDetails.numAwarded) / Float(gameDetails.maxPossible))
                    .padding(.horizontal)
                Spacer()
                    
                if let gameSummary = network.gameSummaries.filter({ $0.id == gameDetails.id}).first {
                    AchievementsView(hardcoreMode: $hardcoreMode, gameSummary: gameSummary)
                } else {
                    ProgressView()
                }
            }
            .onAppear {
                network.getRAGameSummary(gameID: gameDetails.id)
            }
        }
        
}


#Preview {
    Text("Hello World!")
//    GameSummaryView()
//        .environmentObject(Network())
}
