//
//  GameSummaryView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//

import SwiftUI

struct UserGameCompletionProgressDetailView: View {
    var game: GameDetails
    @Binding var hardcoreMode: Bool
    
    var body: some View {
        HStack{
            AsyncImage(url: URL(string: "https://retroachievements.org/" + (game.imageIcon)))
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
            .frame(maxHeight: .infinity)
            .scaleEffect(0.75)
            
            Spacer()
            
            VStack(alignment: .center){
                Spacer()
                Text(game.title)
                    .bold()
                    .lineLimit(1)
                
                Text(game.consoleName)
                    .bold()
                    .lineLimit(1)
                    .foregroundColor(.gray)
                
                Spacer()
                
                VStack{
                    Text("Unlocked: " + (hardcoreMode ? String(game.numAwardedHardcore) : String(game.numAwarded)) + " | " + String(game.maxPossible)).multilineTextAlignment(.center)
                    ProgressView(value: Float(hardcoreMode ? game.numAwardedHardcore : game.numAwarded) / Float(game.maxPossible))
                    .padding(.horizontal)
                    .frame(maxHeight: .infinity)
                }
                
                Spacer()
                
            }
        }
    }
}

#Preview {
    let previewGame = GameDetails(id: 1, title: "Test", imageIcon: "test", consoleID: 1, consoleName: "Test", maxPossible: 99, numAwarded: 2, numAwardedHardcore: 1, mostRecentAwardedDate: "test", highestAwardKind: "test", highestAwardDate: "test")
    @State var hardcoreMode: Bool = true
    return UserGameCompletionProgressDetailView(game: previewGame, hardcoreMode: $hardcoreMode)
}
