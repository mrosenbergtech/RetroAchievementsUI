//
//  RecentAchievementsView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 12/28/24.
//

import SwiftUI

struct RecentAchievementsView: View {
    @EnvironmentObject var network: Network
    @Binding var hardcoreMode: Bool

    var body: some View {
        if ((network.userRecentAchievements.count) > 0){
            Section(header: Text("Recently Unlocked Achievements")){
                ForEach(network.userRecentAchievements.prefix(upTo: 5)) { recentAchievement in
                    if (hardcoreMode && recentAchievement.hardcoreMode == 1){
                        NavigationLink(destination: GameSummaryView(hardcoreMode: $hardcoreMode, gameID: recentAchievement.gameID)){
                            RecentAchievementDetailView(hardcoreMode: $hardcoreMode, achievement: recentAchievement)
                        }
                    } else if (!hardcoreMode) {
                        NavigationLink(destination: GameSummaryView(hardcoreMode: $hardcoreMode, gameID: recentAchievement.gameID)){
                            RecentAchievementDetailView(hardcoreMode: $hardcoreMode, achievement: recentAchievement)
                        }
                    }
                }
            }
        } else {
            Text("No Recent Achievements!")
        }
    }
}

#Preview {
    @Previewable @State var hardcoreMode: Bool = true
    let network = Network()
    Task {
        await network.authenticateCredentials(webAPIUsername: debugWebAPIUsername, webAPIKey: debugWebAPIKey) 
    }
    return RecentAchievementsView(hardcoreMode: $hardcoreMode).environmentObject(network)
}
