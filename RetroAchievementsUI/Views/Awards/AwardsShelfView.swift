//
//  AwardsShelfView.swift
//  RetroAchievementsUI
//
//  The Profile page's awards section: a snapping carousel of the user's best
//  cards, with a link through to the full collection.
//
//  The carousel is the one place a horizontal scroller earns its keep — cards
//  are objects you flick through. It snaps to card boundaries and the
//  neighbours recede, so it reads as a deck rather than a scrolling strip.
//
//  Renders nothing when the user has no awards; ProfileView omits the whole
//  section in that case.
//

import SwiftUI

struct AwardsShelfView: View {
    @EnvironmentObject var network: Network
    @Environment(\.selectedGameID) private var selectedGameID: Binding<GameSheetItem?>
    @Binding var hardcoreMode: Bool
    /// Derived by ProfileView from the height the deck was given.
    var cardWidth: CGFloat = RACardMetrics.carouselWidth

    /// The shelf scrolls, so it holds a decent run of cards; "See All"
    /// remains for the full collection.
    private let shelfLimit = 30

    @State private var selected: AwardCardModel?

    private var allCards: [AwardCardModel] {
        network.awardCards(hardcoreMode: hardcoreMode)
    }

    /// Rarest first — the shelf is a highlight reel, not a history.
    private var shelfCards: [AwardCardModel] {
        allCards
            .sorted {
                $0.tier == $1.tier
                    ? ($0.awardedAt ?? .distantPast) > ($1.awardedAt ?? .distantPast)
                    : $0.tier > $1.tier
            }
            .prefix(shelfLimit)
            .map { $0 }
    }

    /// Just the carousel — ProfileView supplies the section header so the
    /// Awards heading matches the other sections and sticks the same way.
    var body: some View {
        carousel
            .sheet(item: $selected) { card in
                AwardCardDetailView(card: card, hardcoreMode: $hardcoreMode)
            }
    }

    /// A game award goes straight to that game; a site award has no game, so it
    /// opens the trading card itself.
    private func open(_ card: AwardCardModel) {
        if let gameID = card.gameID {
            selectedGameID.wrappedValue = GameSheetItem(id: gameID)
        } else {
            selected = card
        }
    }

    private var carousel: some View {
        RACardCarousel(items: shelfCards, width: cardWidth) { card in
            Button {
                open(card)
            } label: {
                AwardCardCell(card: card, hardcoreMode: hardcoreMode)
            }
            .buttonStyle(CardPressStyle())
        }
    }
}
