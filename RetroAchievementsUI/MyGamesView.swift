//
//  GameSummaryView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//

import SwiftUI

struct MyGamesView: View {
    @EnvironmentObject var network: Network
    @Binding var hardcoreMode: Bool
    
    var body: some View {
        if network.userGameCompletionProgress?.results != nil {
            Form(){
                ForEach(network.userGameCompletionProgress!.results) { game in
                        VStack{
                            UserGameCompletionProgressDetailView(game: game, hardcoreMode: $hardcoreMode)
                        }
                    }
                }
        } else {
            ProgressView()
        }
    }
}

#Preview {
    @State var hardcoreMode: Bool = true
    return MyGamesView(hardcoreMode: $hardcoreMode)
        .environmentObject(Network())
}
