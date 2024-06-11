//
//  ConsoleGameDetailView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/10/24.
//

import SwiftUI

struct ConsoleGameDetailView: View {
    var consoleGame: ConsoleGameInfo
    @Binding var hardcoreMode: Bool
    
    var body: some View {
        HStack{
            AsyncImage(url: URL(string: "https://retroachievements.org/" + (consoleGame.imageIcon)))
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
            .scaleEffect(0.75)
                        
            VStack(alignment: .center){
                ScrollingText(text: consoleGame.title, font: .boldSystemFont(ofSize: 15), leftFade: 15, rightFade: 15, startDelay: 1, alignment: .center)
                            .padding(.horizontal)
                HStack{
                    HStack {
                        Image(systemName: "trophy.circle")
                        Text(String(consoleGame.numAchievements))
                    }
                    
                    HStack {
                        Image(systemName: "command.circle.fill")
                        Text(String(consoleGame.points))
                    }
                }
            }

        }
        .alignmentGuide(.listRowSeparatorLeading) { _ in -20 }
    }
        
}


#Preview {
    let previewGame = ConsoleGameInfo(title: "Super Mario 64", id: 10003, consoleID: 2, consoleName: "Nintendo 64", imageIcon: "/Images/047942.png", numAchievements: 114, numLeaderboards: 0, points: 500, dateModified: "N/A", forumTopicID: -1, hashes: nil)
    @State var hardcoreMode: Bool = true
    return ConsoleGameDetailView(consoleGame: previewGame, hardcoreMode: $hardcoreMode)
}