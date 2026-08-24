//
//  MyGamesView.swift
//  RetroAchievementsUI
//

import SwiftUI

struct MyGamesView: View {
    @EnvironmentObject var network: Network
    @Environment(\.selectedGameID) var selectedGameID: Binding<GameSheetItem?>
    @Binding var hardcoreMode: Bool
    @Binding var showUnofficial: Bool

    @State private var forceSkeleton: Bool = false
    @State private var query: String = ""


    // MARK: - Data

    private var games: [GameCompletionProgress] {
        let all = network.userGameCompletionProgress?.results ?? []
        // Unofficial games are prefixed with "~" by the API.
        let base = showUnofficial ? all : all.filter { !$0.title.starts(with: "~") }
        guard !query.isEmpty else { return base }
        return base.filter { $0.title.localizedCaseInsensitiveContains(query) }
    }

    /// Console name → its games, both alphabetised.
    private var grouped: [(console: String, games: [GameCompletionProgress])] {
        Dictionary(grouping: games, by: \.consoleName)
            .map { (console: $0.key,
                    games: $0.value.sorted { $0.title.lowercased() < $1.title.lowercased() }) }
            .sorted { $0.console.lowercased() < $1.console.lowercased() }
    }

    private var isLoading: Bool { network.isFetching || forceSkeleton }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    skeleton
                } else if games.isEmpty {
                    ContentUnavailableView(
                        query.isEmpty ? "No Games Found" : "No Matches",
                        systemImage: query.isEmpty ? "gamecontroller.fill" : "magnifyingglass",
                        description: Text(query.isEmpty
                            ? "Play a game with achievements and it will appear here."
                            : "No games match “\(query)”.")
                    )
                } else {
                    list
                }
            }
            .background(Color.raSurface)
            .navigationTitle("My Games")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .automatic),
                        prompt: "Filter your games")
            .refreshable { await refreshWithMinimumDuration() }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoading)
    }

    // MARK: - List

    private let cardWidth = RACardMetrics.carouselWidth

    /// One horizontal deck per console, matching the profile's decks.
    ///
    /// A List of carousels rather than a grid: each console is a single row, so
    /// the page scrolls vertically through systems and horizontally through the
    /// games in one — the same gesture model as the profile.
    private var list: some View {
        List {
            ForEach(grouped, id: \.console) { group in
                Section {
                    RACardCarousel(items: group.games, width: cardWidth) { game in
                        Button {
                            selectedGameID.wrappedValue = GameSheetItem(id: game.id)
                        } label: {
                            // Console name is omitted — the section header
                            // already names the system.
                            RACardCell(face: .game(game,
                                                   hardcoreMode: hardcoreMode,
                                                   showConsoleName: false))
                        }
                        .buttonStyle(CardPressStyle())
                    }
                    .frame(height: RACardMetrics.carouselHeight(for: cardWidth))
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } header: {
                    HStack {
                        Text(group.console)
                            .font(.raTitle)
                            .foregroundStyle(Color.raTextPrimary)
                        Spacer()
                        Text("\(group.games.count)")
                            .font(.raStatSmall)
                            .foregroundStyle(Color.raTextTertiary)
                    }
                    .textCase(nil)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .listRowInsets(EdgeInsets())
                    .background(Color.raSurface)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var skeleton: some View {
        List {
            ForEach(0..<3, id: \.self) { _ in
                Section {
                    HStack(spacing: 12) {
                        ForEach(0..<3, id: \.self) { _ in
                            SkeletonCard().frame(width: cardWidth)
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: RACardMetrics.carouselHeight(for: cardWidth),
                           alignment: .leading)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } header: {
                    Text("Console Name")
                        .font(.raTitle)
                        .foregroundStyle(Color.raTextPrimary)
                        .textCase(nil)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .listRowInsets(EdgeInsets())
                        .background(Color.raSurface)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDisabled(true)
        .skeleton()
    }

    // MARK: - Refresh

    private func refreshWithMinimumDuration() async {
        forceSkeleton = true
        let startTime = Date()
        await network.getUserGameCompletionProgress()

        let elapsed = Date().timeIntervalSince(startTime)
        let minimumDuration: TimeInterval = 1.0
        if elapsed < minimumDuration {
            try? await Task.sleep(nanoseconds: UInt64((minimumDuration - elapsed) * 1_000_000_000))
        }

        withAnimation { forceSkeleton = false }
    }
}

#Preview {
    @Previewable @State var hardcoreMode: Bool = true
    @Previewable @State var showUnofficial: Bool = false

    let network = Network()
    Task {
        await network.authenticateCredentials(webAPIUsername: debugWebAPIUsername, webAPIKey: debugWebAPIKey)
        await network.getUserGameCompletionProgress()
    }
    return MyGamesView(hardcoreMode: $hardcoreMode, showUnofficial: $showUnofficial)
        .environmentObject(network)
}
