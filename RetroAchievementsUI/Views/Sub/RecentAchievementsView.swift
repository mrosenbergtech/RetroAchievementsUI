//
//  RecentAchievementsView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 12/28/24.
//

import SwiftUI

struct RecentAchievementsView: View {
    @EnvironmentObject var network: Network
    @Environment(\.selectedGameID) var selectedGameID: Binding<GameSheetItem?>
    @Binding var hardcoreMode: Bool
    @Binding var showUnofficial: Bool

    var body: some View {
        let baseList = showUnofficial ? network.userRecentAchievements : network.userRecentAchievements.filter { !$0.gameTitle.starts(with: "~") }
        if ((baseList.count) > 0) {
            ForEach(baseList.prefix(upTo: 3)) { recentAchievement in
                // Logic to determine if we should show this achievement based on Hardcore toggle
                let shouldShow = (hardcoreMode && recentAchievement.hardcoreMode == 1) || !hardcoreMode
                
                if shouldShow {
                    // Change NavigationLink to Button to trigger the global sheet
                    Button {
                        selectedGameID.wrappedValue = GameSheetItem(id: recentAchievement.gameID)
                    } label: {
                        RecentAchievementDetailView(hardcoreMode: $hardcoreMode, achievement: recentAchievement)
                            .contentShape(Rectangle()) // Ensures the whole row area is tappable
                    }
                    .buttonStyle(.plain) // Removes default blue button tinting
                }
            }
        } else {
            Text("No Recent Achievements!")
        }
    }
}

#Preview {
    @Previewable @State var hardcoreMode: Bool = true
    @Previewable @State var showUnofficial: Bool = false
    let network = Network()
    Task {
        await network.authenticateCredentials(webAPIUsername: debugWebAPIUsername, webAPIKey: debugWebAPIKey)
    }
    return Form {
        RecentAchievementsView(hardcoreMode: $hardcoreMode, showUnofficial: $showUnofficial)
    }
    .environmentObject(network)
    .environment(\.selectedGameID, .constant(nil))
}
