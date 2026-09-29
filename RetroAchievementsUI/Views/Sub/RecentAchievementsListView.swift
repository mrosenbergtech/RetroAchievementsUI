//
//  RecentAchievementsListView.swift
//  RetroAchievementsUI
//
//  Everything behind the profile's Achievements stat.
//
//  The deck on the profile is a highlight reel that holds a handful of cards;
//  tapping the count should show the rest. A List rather than more cards:
//  this is a history to read down, not objects to flick through, and the run
//  can be hundreds long.
//

import SwiftUI
import Kingfisher

struct RecentAchievementsListView: View {
    @EnvironmentObject var network: Network
    @Environment(\.selectedGameID) private var selectedGameID: Binding<GameSheetItem?>
    @Binding var hardcoreMode: Bool
    @Binding var showUnofficial: Bool

    /// Same filtering the deck applies, so the list cannot disagree with the
    /// count that opened it.
    private var achievements: [RecentAchievement] {
        var list = network.userRecentAchievements
        if hardcoreMode { list = list.filter { $0.hardcoreMode == 1 } }
        if !showUnofficial { list = list.filter { !$0.gameTitle.starts(with: "~") } }
        return list
    }

    var body: some View {
        List {
            if achievements.isEmpty {
                ContentUnavailableView(
                    "No recent achievements",
                    systemImage: "medal",
                    description: Text(hardcoreMode
                        ? "Nothing unlocked in hardcore lately."
                        : "Nothing unlocked lately.")
                )
                .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(achievements) { achievement in
                        row(achievement)
                    }
                } header: {
                    Text("\(achievements.count) unlocked")
                        .font(.raStatSmall)
                        .foregroundStyle(Color.raTextTertiary)
                }
                .listRowBackground(Color.raSurfaceRaised)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.raSurface)
        .navigationTitle("Recent Achievements")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ achievement: RecentAchievement) -> some View {
        Button {
            selectedGameID.wrappedValue = GameSheetItem(id: achievement.gameID,
                                                        achievementID: achievement.id)
        } label: {
            HStack(spacing: 12) {
                KFImage(RAImageURL.badge(achievement.badgeName, locked: false))
                    .resizable()
                    .placeholder {
                        RoundedRectangle(cornerRadius: 8).fill(Color.raSurfaceSunken)
                    }
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(achievement.title)
                        .font(.raBody.weight(.semibold))
                        .foregroundStyle(Color.raTextPrimary)
                        .lineLimit(1)
                    Text(achievement.gameTitle)
                        .font(.raCaption)
                        .foregroundStyle(Color.raTextSecondary)
                        .lineLimit(1)
                    if let relative = RecentAchievement.relativeDate(achievement.date) {
                        Text(relative)
                            .font(.raStatSmall)
                            .foregroundStyle(Color.raTextTertiary)
                    }
                }

                Spacer(minLength: 8)

                Text("\(achievement.points)")
                    .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                    .foregroundStyle(Color.raTextPrimary)
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
