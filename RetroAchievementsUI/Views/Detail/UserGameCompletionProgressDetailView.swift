//
//  UserGameCompletionDetailView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//

import SwiftUI

struct UserGameCompletionProgressDetailView: View {
    var game: GameCompletionProgress
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
                        
            VStack(alignment: .center){
                HStack{
                    VStack{
                        ScrollingText(text: game.title, font: .boldSystemFont(ofSize: 15), leftFade: 15, rightFade: 15, startDelay: 1, alignment: .center)
                            .padding(.horizontal)
                        
                        Text(game.consoleName)
                            .lineLimit(1)
                            .font(.footnote)
                            .foregroundColor(.gray)
                        
                        
                        Text("Unlocked: " + (hardcoreMode ? String(game.numAwardedHardcore) : String(game.numAwarded)) + " | " + String(game.maxPossible))
                            .multilineTextAlignment(.center)
                            .font(.footnote)
                    }
                }
                
                ProgressView(value: Float(hardcoreMode ? game.numAwardedHardcore : game.numAwarded) / Float(game.maxPossible))
                    .padding(.horizontal)
            }
            
            Image(systemName: "checkmark.circle")
                .foregroundStyle(highestAwardColor(highestAwardKind: game.highestAwardKind))
                .padding(.horizontal)
        }
        .alignmentGuide(.listRowSeparatorLeading) { _ in -20 }
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
    let previewGame = GameCompletionProgress(id: 10003, title: "Super Mario 64", imageIcon: "/Images/047942.png", consoleID: 2, consoleName: "Nintendo 64", maxPossible: 114, numAwarded: 59, numAwardedHardcore: 59, mostRecentAwardedDate: "N/A", highestAwardKind: "beaten-hardcore", highestAwardDate: nil)
    @State var hardcoreMode: Bool = true
    return UserGameCompletionProgressDetailView(game: previewGame, hardcoreMode: $hardcoreMode)
}
