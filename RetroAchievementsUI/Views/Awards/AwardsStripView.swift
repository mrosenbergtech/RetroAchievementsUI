//
//  AwardsStripView.swift
//  RetroAchievementsUI
//
//  The compact form of the awards shelf, for the profile.
//
//  Three full-size card decks stacked down the profile all read the same, so
//  the page had no entry point — nothing said "look here first". Awards
//  become a strip of badges at a third of the height: still a highlight reel,
//  rarest first, but it gives its height to Recently Played and Recent
//  Achievements and stops the three rows looking identical.
//
//  The full-size cards still exist: "See All" opens the collection, and a
//  site award opens its trading card.
//

import SwiftUI
import Kingfisher

struct AwardsStripView: View {
    @EnvironmentObject var network: Network
    @Environment(\.selectedGameID) private var selectedGameID: Binding<GameSheetItem?>
    @Binding var hardcoreMode: Bool

    var diameter: CGFloat = 52

    private let stripLimit = 30

    @State private var selected: AwardCardModel?

    /// Rarest first, matching the shelf it replaces.
    private var cards: [AwardCardModel] {
        network.awardCards(hardcoreMode: hardcoreMode)
            .sorted {
                $0.tier == $1.tier
                    ? ($0.awardedAt ?? .distantPast) > ($1.awardedAt ?? .distantPast)
                    : $0.tier > $1.tier
            }
            .prefix(stripLimit)
            .map { $0 }
    }

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                ForEach(cards) { card in
                    Button { open(card) } label: { badge(card) }
                        .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
        .sheet(item: $selected) { card in
            AwardCardDetailView(card: card, hardcoreMode: $hardcoreMode)
        }
    }

    /// Game icon in a tier-coloured ring — the tier is the whole point of the
    /// strip, and a ring carries it at this size where a nameplate cannot.
    private func badge(_ card: AwardCardModel) -> some View {
        let ink = RarityMaterial.of(card.tier).ink

        return KFImage(RAImageURL.gameIcon(card.iconPath))
            .resizable()
            .placeholder {
                RoundedRectangle(cornerRadius: diameter * 0.26)
                    .fill(Color.raSurfaceSunken)
                    .overlay(
                        Image(systemName: card.isSiteAward ? "rosette" : "trophy.fill")
                            .font(.system(size: diameter * 0.34))
                            .foregroundStyle(ink)
                    )
            }
            .aspectRatio(contentMode: .fill)
            .frame(width: diameter, height: diameter)
            .clipShape(RoundedRectangle(cornerRadius: diameter * 0.26, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: diameter * 0.26, style: .continuous)
                    .strokeBorder(ink, lineWidth: 2)
            )
            .accessibilityLabel("\(card.title), \(card.tier.longDisplayName)")
    }

    private func open(_ card: AwardCardModel) {
        if let gameID = card.gameID {
            selectedGameID.wrappedValue = GameSheetItem(id: gameID)
        } else {
            selected = card
        }
    }
}
