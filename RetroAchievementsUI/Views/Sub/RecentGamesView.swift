//
//  RecentGamesView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 12/30/24.
//

import SwiftUI

struct RecentGamesView: View {
    @EnvironmentObject var network: Network
    @Environment(\.selectedGameID) var selectedGameID: Binding<GameSheetItem?>
    @Binding var hardcoreMode: Bool

    var body: some View {
        if (network.userRecentlyPlayedGames.count > 0){
            ForEach(network.userRecentlyPlayedGames) { recentlyPlayedGame in
                // Change NavigationLink to Button to trigger the global sheet
                Button {
                    selectedGameID.wrappedValue = GameSheetItem(id: recentlyPlayedGame.id)
                } label: {
                    GameSummaryPreviewView(
                        hardcoreMode: $hardcoreMode,
                        imageIconString: recentlyPlayedGame.imageIcon,
                        gameTitle: recentlyPlayedGame.title,
                        gameConsoleName: recentlyPlayedGame.consoleName,
                        maxPossible: recentlyPlayedGame.numPossibleAchievements,
                        numAwardedHardcore: recentlyPlayedGame.numAchievedHardcore,
                        numAwarded: recentlyPlayedGame.numAchieved,
                        highestAwardKind: network.userGameCompletionProgress?.results.filter {$0.id == recentlyPlayedGame.id}.first?.highestAwardKind ?? nil
                    )
                    .contentShape(Rectangle()) // Ensures the whole row area is tappable
                }
                .buttonStyle(.plain) // Removes the default blue button tint
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
    return Form {
        RecentGamesView(hardcoreMode: $hardcoreMode)
    }
    .environmentObject(network)
}
