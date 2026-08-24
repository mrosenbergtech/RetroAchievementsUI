//
//  GameSummaryView.swift
//  RetroAchievementsUI
//
//  The game sheet presented globally from every screen via \.selectedGameID.
//

import SwiftUI

struct GameSummaryView: View {
    @EnvironmentObject var network: Network
    @Binding var hardcoreMode: Bool
    var gameID: Int
    /// Set when arriving from the profile's Recent Achievements deck: the sheet
    /// opens and immediately surfaces this achievement's detail.
    var initialAchievementID: Int? = nil

    /// Floors the skeleton so a cached game doesn't flash content into place.
    @State private var showSkeleton: Bool = true
    @State private var selectedAchievement: Achievement?

    var body: some View {
        Group {
            if let gameSummary = network.gameSummaryCache[gameID], !showSkeleton {
                content(gameSummary)
            } else {
                skeleton
            }
        }
        .background(Color.raSurface)
        .animation(.easeInOut(duration: 0.3), value: showSkeleton)
        .task {
            if network.gameSummaryCache[gameID] == nil {
                await network.getGameSummary(gameID: gameID)
            } else {
                // Already cached — a short beat still reads better than a snap.
                try? await Task.sleep(nanoseconds: 250_000_000)
            }
            withAnimation { showSkeleton = false }
            openInitialAchievementIfNeeded()
        }
    }

    // MARK: - Content

    /// A List so the achievement rows recycle: large sets run past 200 entries,
    /// and the filter bar rides along as a sticky section header.
    private func content(_ gameSummary: GameSummary) -> some View {
        List {
            Section {
                GameSummaryHeaderView(hardcoreMode: $hardcoreMode, gameID: gameID)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            AchievementsView(hardcoreMode: $hardcoreMode,
                             gameSummary: gameSummary,
                             selectedAchievement: $selectedAchievement)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .refreshable { await network.getGameSummary(gameID: gameID) }
        .sheet(item: $selectedAchievement) { achievement in
            AchievementSheetView(achievement: achievement,
                                 gameTitle: gameSummary.title,
                                 totalPlayers: gameSummary.numDistinctPlayers,
                                 hardcoreMode: $hardcoreMode)
                .environmentObject(network)
        }
    }

    /// Surfaces the deep-linked achievement once the game's data has arrived —
    /// the achievement list does not exist before then.
    private func openInitialAchievementIfNeeded() {
        guard let initialAchievementID,
              selectedAchievement == nil,
              let summary = network.gameSummaryCache[gameID],
              let match = summary.achievements["\(initialAchievementID)"]
                  ?? summary.orderedAchievements.first(where: { $0.id == initialAchievementID })
        else { return }
        selectedAchievement = match
    }

    // MARK: - Skeleton

    private var skeleton: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Rectangle()
                        .fill(Color.raSurfaceSunken)
                        .frame(height: 128)
                    Capsule().fill(Color.raSurfaceSunken).frame(width: 180, height: 18)
                    Capsule().fill(Color.raSurfaceSunken).frame(width: 110, height: 12)
                    Capsule().fill(Color.raSurfaceSunken).frame(width: 220, height: 5)
                        .padding(.top, 4)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            Section {
                ForEach(0..<6, id: \.self) { _ in
                    SkeletonRow(imageSize: 56).raListRow()
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDisabled(true)
        .skeleton()
    }
}

#Preview {
    @Previewable @State var hardcoreMode: Bool = true
    let network = Network()

    Task {
        await network.authenticateCredentials(webAPIUsername: debugWebAPIUsername, webAPIKey: debugWebAPIKey)
    }

    return GameSummaryView(hardcoreMode: $hardcoreMode, gameID: 10003)
        .environmentObject(network)
}
