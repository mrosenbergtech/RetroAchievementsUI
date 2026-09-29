//
//  UserGameProgressView.swift
//  RetroAchievementsUI
//
//  One game, as somebody else has played it: their unlocks, their completion,
//  their playtime.
//
//  This exists because tapping a game on another user's profile used to open
//  the app-wide game sheet, which is always keyed to the signed-in user — so a
//  visitor's card led to *your* progress on their game. Worse, reaching that
//  profile from inside the achievement sheet meant the tap did nothing at all:
//  the game sheet is presented by ContentView, and SwiftUI will not present a
//  second sheet over the first.
//
//  So this pushes onto the current navigation stack instead of presenting, and
//  fetches with their username (GetGameInfoAndUserProgress takes one), which
//  makes every unlock date on the page theirs.
//

import SwiftUI
import Kingfisher

struct UserGameProgressView: View {
    @EnvironmentObject var network: Network
    @Binding var hardcoreMode: Bool

    let username: String
    let gameID: Int
    /// Set when arriving from one of their recent achievements: the page opens
    /// and immediately surfaces that achievement.
    var initialAchievementID: Int?

    @State private var isLoading = true
    @State private var loadError: RANetworkError?
    @State private var selectedAchievement: Achievement?
    @State private var openedInitialAchievement = false

    private var summary: GameSummary? {
        network.otherGameSummaryCache[Network.userKey(username)]?[gameID]
    }

    var body: some View {
        Group {
            if let summary {
                content(summary)
            } else if let loadError {
                RAErrorView(error: loadError, retry: { await load() })
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.raSurface)
        .navigationTitle(summary?.title ?? "Progress")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .sheet(item: $selectedAchievement) { achievement in
            // The achievement carries their unlock dates, so the sheet's card
            // shows their state rather than the reader's.
            AchievementSheetView(achievement: achievement,
                                 gameTitle: summary?.title,
                                 totalPlayers: summary?.numDistinctPlayers,
                                 hardcoreMode: $hardcoreMode)
                .environmentObject(network)
        }
    }

    private func content(_ summary: GameSummary) -> some View {
        List {
            Section {
                header(summary)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            AchievementsView(hardcoreMode: $hardcoreMode,
                             gameSummary: summary,
                             selectedAchievement: $selectedAchievement)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .refreshable { await network.getGameSummary(gameID: gameID, username: username) }
    }

    // MARK: - Header

    private func header(_ summary: GameSummary) -> some View {
        let earned = hardcoreMode ? summary.numAwardedToUserHardcore : summary.numAwardedToUser
        let fraction = summary.numAchievements > 0
            ? Double(earned) / Double(summary.numAchievements)
            : 0
        let tier = AwardTier(highestAwardKind: summary.highestAwardKind)

        return VStack(spacing: 10) {
            KFImage(RAImageURL.gameIcon(summary.imageIcon))
                .resizable()
                .placeholder {
                    RoundedRectangle(cornerRadius: 12).fill(Color.raSurfaceSunken)
                }
                .aspectRatio(contentMode: .fill)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(spacing: 3) {
                Text(summary.title)
                    .font(.raDisplay)
                    .foregroundStyle(Color.raTextPrimary)
                    .multilineTextAlignment(.center)
                Text(summary.consoleName)
                    .font(.raCaption)
                    .foregroundStyle(Color.raTextSecondary)
            }

            // Whose progress this is, stated plainly — every unlock mark below
            // belongs to them, not to the reader.
            RAChip("\(username)’s progress", systemImage: "person.crop.circle",
                   tint: Color.raAccent)

            if let tier {
                RAChip(tier.longDisplayName.uppercased(),
                       systemImage: tier.isMasteryClass ? "rosette" : "checkmark.seal.fill",
                       tint: RarityMaterial.of(tier).ink)
            }

            if summary.numAchievements > 0 {
                VStack(spacing: 6) {
                    HStack(spacing: 14) {
                        RAMeta(systemImage: "trophy.fill",
                               text: "\(earned)/\(summary.numAchievements)")
                        if let points = summary.pointsTotal {
                            RAMeta(systemImage: "command.circle.fill", text: "\(points)")
                        }
                        if let playtime = summary.playtimeDescription {
                            RAMeta(systemImage: "clock.fill", text: playtime)
                        }
                        Text("\(Int((fraction * 100).rounded()))%")
                            .font(.raStatSmall)
                            .foregroundStyle(tier.map { RarityMaterial.of($0).ink }
                                             ?? Color.raTextSecondary)
                    }
                    RAProgressBar(value: fraction, tier: tier, height: 5)
                }
                .padding(.horizontal, 40)
            } else {
                Text("No achievements yet")
                    .font(.raCaption)
                    .foregroundStyle(Color.raTextTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }

    // MARK: - Loading

    private func load() async {
        isLoading = summary == nil
        if summary == nil {
            loadError = await network.getGameSummary(gameID: gameID, username: username)
        }
        isLoading = false
        openInitialAchievementIfNeeded()
    }

    /// Opens the achievement the reader tapped on their profile, once.
    private func openInitialAchievementIfNeeded() {
        guard !openedInitialAchievement,
              let initialAchievementID,
              let match = summary?.achievements["\(initialAchievementID)"]
        else { return }
        openedInitialAchievement = true
        selectedAchievement = match
    }
}
