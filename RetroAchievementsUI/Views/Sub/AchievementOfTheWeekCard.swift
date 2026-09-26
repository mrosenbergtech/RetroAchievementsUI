//
//  AchievementOfTheWeekCard.swift
//  RetroAchievementsUI
//
//  This week's featured achievement, at the top of the Community tab.
//
//  The AOTW payload names the achievement and its game but carries no badge
//  name, so the art cannot come from that response alone. The card fetches the
//  parent game's summary — a call the app already makes everywhere, and caches
//  — and takes the badge from the achievement inside it. Until that lands the
//  tile is a symbol rather than a broken image.
//

import SwiftUI
import Kingfisher

struct AchievementOfTheWeekCard: View {
    @EnvironmentObject var network: Network
    @Environment(\.selectedGameID) var selectedGameID: Binding<GameSheetItem?>
    @Binding var hardcoreMode: Bool

    private var featured: AchievementOfTheWeek? { network.achievementOfTheWeek }

    /// The full achievement record, once the parent game's summary is cached.
    /// Carries the badge name; the description comes from the AOTW payload
    /// itself, so the text does not wait on this.
    private var detail: Achievement? {
        guard let featured else { return nil }
        return network.gameSummaryCache[featured.game.id]?
            .achievements["\(featured.achievement.id)"]
    }

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
                // Straight to the achievement rather than the top of the game.
                selectedGameID.wrappedValue = GameSheetItem(
                    id: featured.game.id, achievementID: featured.achievement.id)
            } label: {
                content(featured)
            }
            .buttonStyle(.plain)
            .task(id: featured.game.id) {
                guard network.gameSummaryCache[featured.game.id] == nil else { return }
                await network.getGameSummary(gameID: featured.game.id)
            }
        }
    }

    private func content(_ featured: AchievementOfTheWeek) -> some View {
        HStack(spacing: 12) {
            badge
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text("ACHIEVEMENT OF THE WEEK")
                    .font(.raStatSmall)
                    .foregroundStyle(Color.raAccent)

                Text(featured.achievement.title)
                    .font(.raBody.weight(.semibold))
                    .foregroundStyle(Color.raTextPrimary)
                    .lineLimit(1)

                if let description = featured.achievement.description,
                   !description.isEmpty {
                    Text(description)
                        .font(.raCaption)
                        .foregroundStyle(Color.raTextSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text(featured.game.title)
                    .font(.raStatSmall)
                    .foregroundStyle(Color.raTextTertiary)
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

    @ViewBuilder
    private var badge: some View {
        if let badgeName = detail?.badgeName {
            // Locked art when the reader hasn't earned it, matching every
            // other badge in the app.
            KFImage(RAImageURL.badge(badgeName, locked: !isUnlocked))
                .resizable()
                .placeholder { placeholderTile }
                .aspectRatio(contentMode: .fit)
        } else {
            placeholderTile
        }
    }

    private var placeholderTile: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.raSurfaceSunken)
            .overlay(
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.raAccent)
            )
    }
}
