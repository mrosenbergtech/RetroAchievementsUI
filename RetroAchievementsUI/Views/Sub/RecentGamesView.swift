//
//  RecentGamesView.swift
//  RetroAchievementsUI
//
//  Recently played games as a card carousel, matching the awards shelf.
//

import SwiftUI

struct RecentGamesView: View {
    @EnvironmentObject var network: Network
    @Environment(\.selectedGameID) var selectedGameID: Binding<GameSheetItem?>
    @Binding var hardcoreMode: Bool
    @Binding var showUnofficial: Bool
    /// Derived by ProfileView from the height the deck was given.
    var cardWidth: CGFloat = RACardMetrics.carouselWidth

    /// Unofficial games are prefixed with "~" by the API.
    private var games: [RecentGame] {
        showUnofficial
            ? network.userRecentlyPlayedGames
            : network.userRecentlyPlayedGames.filter { !$0.title.starts(with: "~") }
    }

    private func awardKind(for gameID: Int) -> String? {
        network.userGameCompletionProgress?.results
            .first { $0.id == gameID }?
            .highestAwardKind
    }

    var body: some View {
        if games.isEmpty {
            RAEmptyRow(icon: "clock.badge.questionmark",
                       title: "No Recently Played Games",
                       message: "Games you play will show up here.")
                .raListRow()
        } else {
            RACardCarousel(items: games, width: cardWidth) { game in
                Button {
                    selectedGameID.wrappedValue = GameSheetItem(id: game.id)
                } label: {
                    // A game with no award still gets a card — plain stock,
                    // reading "UNBEATEN".
                    RACardCell(face: .game(game,
                                           hardcoreMode: hardcoreMode,
                                           highestAwardKind: awardKind(for: game.id)))
                }
                .buttonStyle(CardPressStyle())
            }
        }
    }
}

/// Row press feedback for rows outside a List, where the platform provides none.
struct RowPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .background(configuration.isPressed
                        ? Color.raTextPrimary.opacity(0.06)
                        : Color.clear)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension View {
    /// Standard List row chrome: tokenised background, inset separator.
    func raListRow() -> some View {
        self
            .listRowBackground(Color.raSurfaceRaised)
            .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
            .alignmentGuide(.listRowSeparatorLeading) { _ in 64 }
    }
}

/// Inline empty state for a section that has no rows.
struct RAEmptyRow: View {
    let icon: String
    let title: String
    var message: String?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.raTextTertiary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.raBody.weight(.semibold))
                    .foregroundStyle(Color.raTextPrimary)
                if let message {
                    Text(message)
                        .font(.raCaption)
                        .foregroundStyle(Color.raTextSecondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    @Previewable @State var hardcoreMode: Bool = true
    @Previewable @State var showUnofficial = false
    let network = Network()
    Task {
        await network.authenticateCredentials(webAPIUsername: debugWebAPIUsername, webAPIKey: debugWebAPIKey)
    }

    return List {
        RecentGamesView(hardcoreMode: $hardcoreMode, showUnofficial: $showUnofficial)
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .background(Color.raSurface)
    .environmentObject(network)
}
