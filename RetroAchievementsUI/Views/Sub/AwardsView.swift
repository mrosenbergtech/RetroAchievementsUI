//
//  ConsolesView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/10/24.
//

import SwiftUI

struct AwardsView: View {
    @EnvironmentObject var network: Network
    @Environment(\.selectedGameID) var selectedGameID: Binding<GameSheetItem?>
    @Binding var hardcoreMode: Bool

    var body: some View {
        if let awards = network.awards, !awards.visibleUserAwards.isEmpty {
            
            // Game Awards Section
            let gameAwards = network.filterHighestAwardType(awards: awards.visibleUserAwards)
                .filter { $0.consoleID != nil }
            
            if !gameAwards.isEmpty {
                ForEach(gameAwards) { award in
                    // Filter logic: if HC is on, we only show HC awards (extra == 1)
                    if (hardcoreMode && award.awardDataExtra == 1) || !hardcoreMode {
                        
                        // MARK: - Tap Action to Open Sheet
                        Button {
                            // Safe unwrap: only set the value if the ID exists
                            if let gameID = award.id {
                                selectedGameID.wrappedValue = GameSheetItem(id: gameID)
                            }
                        } label: {
                            if let gameSumm = network.gameSummaryCache[award.id!]
                            {
                                GameSummaryPreviewView(hardcoreMode: $hardcoreMode, imageIconString: gameSumm.imageIcon, gameTitle: gameSumm.title + " - " + award.awardType, gameConsoleName: gameSumm.consoleName, maxPossible: gameSumm.numAchievements, numAwardedHardcore: gameSumm.numAwardedToUserHardcore, numAwarded: gameSumm.numAwardedToUser, highestAwardKind: gameSumm.highestAwardKind)
                            }
                            else
                            {
                                AwardDetailView(award: award)
                                    .contentShape(Rectangle()) // Makes the whole row tappable
                            }
                        }
                        .buttonStyle(.plain) // Prevents the button from tinting the UI blue
                    }
                }
            }
                    
            // Non-Game Awards Section (Events, Site Milestones, etc.)
            let siteAwards = awards.visibleUserAwards.filter { $0.consoleID == nil }
            if !siteAwards.isEmpty {
                Section(header: Text("Site Awards")) {
                    ForEach(siteAwards) { award in
                        HStack {
                            Image(systemName: "star.bubble.fill")
                                .foregroundColor(.purple)
                            Text(award.awardType)
                                .font(.subheadline)
                            Spacer()
                            Text(award.title ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        } else if !network.isFetching {
            Section {
                ContentUnavailableView("No Awards Yet",
                                       systemImage: "trophy.slash",
                                       description: Text("Keep playing to earn mastery and completion awards!"))
            }
        }
    }
}

#Preview {
    @Previewable @State var hardcoreMode: Bool = true
    let network = Network()
    Task {
        await network.authenticateCredentials(webAPIUsername: debugWebAPIUsername, webAPIKey: debugWebAPIKey)
        
    }
    return AwardsView(hardcoreMode: $hardcoreMode).environmentObject(network)
}
