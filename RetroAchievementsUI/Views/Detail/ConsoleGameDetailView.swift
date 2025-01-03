//
//  ConsoleGameDetailView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/10/24.
//

import SwiftUI
import Kingfisher

struct ConsoleGameDetailView: View {
    var gameListGame: GameListGame
    @Binding var hardcoreMode: Bool
    
    var body: some View {
        HStack{
            KFImage(URL(string: "https://retroachievements.org/" + (gameListGame.imageIcon)))
            .clipShape(.rect(cornerRadius: 10))
            .frame(width: 64, height: 64)
            .scaleEffect(0.75)
                        
            VStack(alignment: .center){
                ScrollingText(text: gameListGame.title, font: .boldSystemFont(ofSize: 15), leftFade: 15, rightFade: 15, startDelay: 1, alignment: .center)
                            .padding(.horizontal)
                HStack{
                    HStack {
                        Image(systemName: "trophy.circle")
                        Text(String(gameListGame.numAchievements))
                    }
                    
                    HStack {
                        Image(systemName: "command.circle.fill")
                        Text(String(gameListGame.points))
                    }
                }
            }

        }
        .alignmentGuide(.listRowSeparatorLeading) { _ in -20 }
    }
        
}


#Preview {
    @Previewable @State var hardcoreMode: Bool = true
    let previewGame = GameListGame(title: "Super Mario 64", id: 10003, consoleID: 2, consoleName: "Nintendo 64", imageIcon: "/Images/047942.png", numAchievements: 114, numLeaderboards: 0, points: 500, dateModified: "N/A", forumTopicID: -1)
    return ConsoleGameDetailView(gameListGame: previewGame, hardcoreMode: $hardcoreMode)
}
