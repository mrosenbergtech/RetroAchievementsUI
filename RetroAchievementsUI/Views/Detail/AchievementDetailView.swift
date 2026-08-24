//
//  AchievementDetailView.swift
//  RetroAchievementsUI
//
//  One achievement row inside the game sheet.
//

import SwiftUI

struct AchievementDetailView: View {
    @Binding var hardcoreMode: Bool
    var achievement: Achievement
    /// Supplied by the game sheet, which knows the game's player count.
    var rarity: AchievementRarity?

    private var isUnlocked: Bool {
        hardcoreMode ? achievement.dateEarnedHardcore != nil
                     : achievement.dateEarned != nil
    }

    /// The typed-achievement chip, if this achievement carries a type.
    private var typeChip: (label: String, icon: String, tint: Color)? {
        switch achievement.type {
        case "missable":
            return ("Missable", "exclamationmark.triangle.fill", .orange)
        case "progression":
            return ("Progression", "arrow.forward.circle.fill", .blue)
        case "win_condition":
            return ("Win Condition", "flag.checkered", .green)
        default:
            return nil
        }
    }

    var body: some View {
        RARow(
            // The API serves a separate greyed-out "_lock" badge for
            // unearned achievements.
            imageURL: RAImageURL.badge(achievement.badgeName, locked: !isUnlocked),
            title: achievement.title,
            subtitle: achievement.description,
            thumbnailSize: 56,
            thumbnailContentMode: .fit
        ) {
            Image(systemName: isUnlocked ? "lock.open.fill" : "lock.fill")
                .font(.system(size: 12))
                .foregroundStyle(isUnlocked ? Color.raAccent : Color.raTextTertiary)
                .accessibilityLabel(isUnlocked ? "Unlocked" : "Locked")
        } footer: {
            HStack(spacing: 6) {
                RAMeta(systemImage: "command.circle.fill",
                       text: "\(achievement.points)",
                       tint: isUnlocked ? .raAccent : .raTextSecondary)

                if let rarity {
                    RAChip(rarity.shortName, tint: rarity.tint)
                }

                if let chip = typeChip {
                    RAChip(chip.label, systemImage: chip.icon, tint: chip.tint)
                }
            }
            .padding(.top, 3)
        }
        // Unearned achievements recede rather than disappearing.
        .opacity(isUnlocked ? 1 : 0.62)
    }
}

#Preview {
    @Previewable @State var hardcoreMode: Bool = true
    let unlocked = Achievement(
        id: 48643, numAwarded: 2709, numAwardedHardcore: 2180,
        title: "Full Power", description: "Grab 120 Power Stars.",
        points: 25, trueRatio: 0, author: "SamuraiGoroh",
        dateModified: "06 Dec, 2021 23:01", dateCreated: "25 May, 2017 17:37",
        badgeName: "84225", displayOrder: 1, memAddr: "N/A",
        type: "progression",
        dateEarnedHardcore: "27 Jan, 2024, 19:45", dateEarned: "27 Jan, 2024, 19:45")
    let locked = Achievement(
        id: 48644, numAwarded: 100, numAwardedHardcore: 50,
        title: "Bob-omb Battlefield", description: "Collect every star in the first course.",
        points: 10, trueRatio: 0, author: "SamuraiGoroh",
        dateModified: nil, dateCreated: "25 May, 2017 17:37",
        badgeName: "84226", displayOrder: 2, memAddr: "N/A",
        type: "missable", dateEarnedHardcore: nil, dateEarned: nil)

    return List {
        AchievementDetailView(hardcoreMode: $hardcoreMode, achievement: unlocked)
        AchievementDetailView(hardcoreMode: $hardcoreMode, achievement: locked)
    }
}
