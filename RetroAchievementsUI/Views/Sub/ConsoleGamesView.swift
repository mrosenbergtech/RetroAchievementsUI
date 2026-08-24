//
//  ConsoleGamesView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//

import SwiftUI

struct ConsoleGamesView: View {
    @EnvironmentObject var network: Network
    @Environment(\.selectedGameID) var selectedGameID: Binding<GameSheetItem?>
    @Binding var hardcoreMode: Bool
    @Binding var showUnofficial: Bool
    var consoleID: Int

    @State private var query: String = ""

    private var games: [GameListGame] {
        var list = network.gameList.filter { $0.consoleID == consoleID }
        if !showUnofficial {
            list = list.filter { !$0.title.starts(with: "~") }
        }
        if !query.isEmpty {
            list = list.filter { $0.title.localizedCaseInsensitiveContains(query) }
        }
        return list.sorted { $0.title.lowercased() < $1.title.lowercased() }
    }

    private var consoleName: String {
        network.consolesCache?.getConsoleDataByID(consoleID: consoleID)?.name ?? "Games"
    }

    private var sections: [AlphabetSection<GameListGame>] {
        AlphabetSection.build(games, key: \.title)
    }

    /// A List so rows recycle — some systems carry thousands of games — with an
    /// A–Z scrubber pinned to the trailing edge for jumping through them.
    private var gameList: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(sections) { section in
                    Section {
                        ForEach(section.items) { game in
                            Button {
                                selectedGameID.wrappedValue = GameSheetItem(id: game.id)
                            } label: {
                                ConsoleGameDetailView(gameListGame: game, hardcoreMode: $hardcoreMode)
                            }
                            .buttonStyle(RowPressStyle())
                            .listRowBackground(Color.raSurfaceRaised)
                        }
                    } header: {
                        Text(section.id)
                            .font(.raStatSmall)
                            .foregroundStyle(Color.raTextTertiary)
                    }
                    .id(section.id)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            // Room for the index so it never sits on top of the row content.
            .safeAreaPadding(.trailing, 14)
            .overlay(alignment: .trailing) {
                if sections.count > 1 {
                    RAAlphabetIndex(letters: sections.map(\.id)) { letter in
                        withAnimation(.easeInOut(duration: 0.18)) {
                            proxy.scrollTo(letter, anchor: .top)
                        }
                    }
                    .padding(.trailing, 2)
                }
            }
        }
    }

    var body: some View {
        Group {
            if network.gameList.isEmpty {
                VStack(spacing: 16) {
                    ProgressView().controlSize(.large)
                    Text("Loading games…")
                        .font(.raBody)
                        .foregroundStyle(Color.raTextSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if games.isEmpty {
                ContentUnavailableView(
                    query.isEmpty ? "No Games" : "No Matches",
                    systemImage: query.isEmpty ? "gamecontroller" : "magnifyingglass",
                    description: Text(query.isEmpty
                        ? "No supported games for this system yet."
                        : "No games match “\(query)”.")
                )
            } else {
                gameList
            }
        }
        .background(Color.raSurface)
        .navigationTitle(consoleName)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: "Filter \(consoleName) games")
    }
}

#Preview {
    @Previewable @State var hardcoreMode: Bool = true
    @Previewable @State var showUnofficial = false
    let network = Network()

    return NavigationStack {
        ConsoleGamesView(hardcoreMode: $hardcoreMode, showUnofficial: $showUnofficial, consoleID: 2)
            .environmentObject(network)
    }
    .task {
        await network.authenticateCredentials(webAPIUsername: debugWebAPIUsername, webAPIKey: debugWebAPIKey)
    }
}
