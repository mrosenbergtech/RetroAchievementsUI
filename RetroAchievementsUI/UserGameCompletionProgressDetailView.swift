//
//  UserGameCompletionDetailView.swift
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
                        
            VStack(alignment: .center){
                ScrollingText(text: game.title, font: .boldSystemFont(ofSize: 15), leftFade: 15, rightFade: 15, startDelay: 1, alignment: .center)
                    .padding(.horizontal)
                
                Text(game.consoleName)
                    .lineLimit(1)
                    .font(.footnote)
                    .foregroundColor(.gray)
                
                VStack{
                    Text("Unlocked: " + (hardcoreMode ? String(game.numAwardedHardcore) : String(game.numAwarded)) + " | " + String(game.maxPossible))
                        .multilineTextAlignment(.center)
                        .font(.footnote)

                    ProgressView(value: Float(hardcoreMode ? game.numAwardedHardcore : game.numAwarded) / Float(game.maxPossible))
                        .padding(.horizontal)
                }
                
            }
        }.alignmentGuide(.listRowSeparatorLeading) { _ in -20 }
    }
}

#Preview {
    @ObservedObject var network = Network()
    network.authenticateRACredentials(webAPIUsername: debugWebAPIUsername, webAPIKey: debugWebAPIKey)
    let previewGame = network.userGameCompletionProgress?.results.first ?? GameDetails(id: 1, title: "Test", imageIcon: "Test", consoleID: 1, consoleName: "Test", maxPossible: 99, numAwarded: 3, numAwardedHardcore: 2, mostRecentAwardedDate: "Test", highestAwardKind: nil, highestAwardDate: nil)

    @State var hardcoreMode: Bool = true
    return UserGameCompletionProgressDetailView(game: previewGame, hardcoreMode: $hardcoreMode)
        .environmentObject(network)
}
