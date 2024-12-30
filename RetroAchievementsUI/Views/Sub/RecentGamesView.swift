//
//  RecentGamesView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 12/30/24.
//

import SwiftUI

struct RecentGamesView: View {
    @EnvironmentObject var network: Network
    @Binding var hardcoreMode: Bool

    var body: some View {
        if (network.userRecentlyPlayedGames.count > 0){
            Section(header: Text("Recently Played Games")) {
                ForEach(network.userRecentlyPlayedGames) { recentlyPlayedGame in
                    NavigationLink(destination: GameSummaryView(hardcoreMode: $hardcoreMode, gameID: recentlyPlayedGame.id)){
                         GameSummaryPreviewView(hardcoreMode: $hardcoreMode, imageIconString: recentlyPlayedGame.imageIcon, gameTitle: recentlyPlayedGame.title, gameConsoleName: recentlyPlayedGame.consoleName, maxPossible: recentlyPlayedGame.numPossibleAchievements, numAwardedHardcore: recentlyPlayedGame.numAchievedHardcore, numAwarded: recentlyPlayedGame.numAchieved, highestAwardKind: network.userGameCompletionProgress?.results.filter {$0.id == recentlyPlayedGame.id}.first?.highestAwardKind ?? nil)
                    }
                }
            }
        } else {
            Text("No Recently Played Games!")
        }
    }
}

#Preview {
    @Previewable @State var hardcoreMode: Bool = true
    let network = Network()
    Task {
        await network.authenticateCredentials(webAPIUsername: debugWebAPIUsername, webAPIKey: debugWebAPIKey)
        
    }
    return RecentGamesView(hardcoreMode: $hardcoreMode).environmentObject(network)
}
