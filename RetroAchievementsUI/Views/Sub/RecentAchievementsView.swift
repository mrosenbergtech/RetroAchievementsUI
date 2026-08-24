//
//  RecentAchievementsView.swift
//  RetroAchievementsUI
//

import SwiftUI

struct RecentAchievementsView: View {
    @EnvironmentObject var network: Network
    @Environment(\.selectedGameID) var selectedGameID: Binding<GameSheetItem?>
    @Binding var hardcoreMode: Bool
    @Binding var showUnofficial: Bool
    /// Derived by ProfileView from the height the deck was given.
    var cardWidth: CGFloat = RACardMetrics.carouselWidth

    /// The carousel scrolls, so this is far above the old three-row list.
    var limit: Int = 30

    private var achievements: [RecentAchievement] {
        var list = network.userRecentAchievements

        if !showUnofficial {
            list = list.filter { !$0.gameTitle.starts(with: "~") }
        }

        // Filter BEFORE limiting. Taking three and then dropping the softcore
        // ones meant hardcore mode could show two rows, or none.
        if hardcoreMode {
            list = list.filter { $0.hardcoreMode == 1 }
        }

        // `prefix(_:)`, not `prefix(upTo:)` — the latter traps when the user
        // has fewer than `limit` achievements.
        return Array(list.prefix(limit))
    }

    var body: some View {
        if achievements.isEmpty {
            RAEmptyRow(icon: "medal",
                       title: "No Recent Achievements",
                       message: hardcoreMode
                            ? "Achievements you unlock in hardcore mode will show up here."
                            : "Achievements you unlock will show up here.")
                .raListRow()
        } else {
            RACardCarousel(items: achievements, width: cardWidth) { achievement in
                Button {
                    // Open the game sheet, which then surfaces this
                    // achievement's detail on top of it.
                    selectedGameID.wrappedValue = GameSheetItem(id: achievement.gameID,
                                                                achievementID: achievement.id)
                } label: {
                    RACardCell(face: .achievement(
                        achievement,
                        rarity: network.rarity(forAchievement: achievement.id)))
                }
                .buttonStyle(CardPressStyle())
            }
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
    return List {
        RecentAchievementsView(hardcoreMode: $hardcoreMode, showUnofficial: $showUnofficial)
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .background(Color.raSurface)
    .environmentObject(network)
    .environment(\.selectedGameID, .constant(nil))
}
