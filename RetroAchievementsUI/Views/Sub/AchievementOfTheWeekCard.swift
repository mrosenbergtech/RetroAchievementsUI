//
//  AchievementOfTheWeekCard.swift
//  RetroAchievementsUI
//
//  This week's featured achievement, at the top of the Community tab.
//
//  A single row rather than a trading card: the AOTW payload carries no badge
//  name, so there is no badge art to build a card face from — only the game
//  icon, which the row shows instead.
//

import SwiftUI

struct AchievementOfTheWeekCard: View {
    @EnvironmentObject var network: Network
    @Environment(\.selectedGameID) var selectedGameID: Binding<GameSheetItem?>
    @Binding var hardcoreMode: Bool

    private var featured: AchievementOfTheWeek? { network.achievementOfTheWeek }

    /// Whether the signed-in user appears in the unlock list the API returned.
    ///
    /// That list is capped, so this can only ever say "yes, they have it" —
    /// a miss is shown as nothing at all rather than as "not unlocked", which
    /// would be a claim the data cannot support.
    private var isUnlocked: Bool {
        featured?.isUnlocked(by: network.authenticatedWebAPIUsername,
                             hardcoreMode: hardcoreMode) ?? false
    }

    var body: some View {
        if let featured {
            Button {
                selectedGameID.wrappedValue = GameSheetItem(id: featured.game.id)
            } label: {
                content(featured)
            }
            .buttonStyle(.plain)
        }
    }

    private func content(_ featured: AchievementOfTheWeek) -> some View {
        HStack(spacing: 12) {
            // No art to load: the AOTW payload names the game and console but
            // carries no badge or icon path, so the tile is a symbol rather
            // than an image request that would 404.
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.raSurfaceSunken)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.raAccent)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text("ACHIEVEMENT OF THE WEEK")
                    .font(.raStatSmall)
                    .foregroundStyle(Color.raAccent)

                Text(featured.achievement.title)
                    .font(.raBody.weight(.semibold))
                    .foregroundStyle(Color.raTextPrimary)
                    .lineLimit(1)

                Text(featured.game.title)
                    .font(.raCaption)
                    .foregroundStyle(Color.raTextSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(featured.achievement.points)")
                    .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                    .foregroundStyle(Color.raTextPrimary)
                if isUnlocked {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.raAccent)
                        .accessibilityLabel("Unlocked")
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.raSurfaceRaised, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.raAccent.opacity(0.35), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
}
