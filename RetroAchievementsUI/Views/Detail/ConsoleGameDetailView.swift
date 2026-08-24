//
//  ConsoleGameDetailView.swift
//  RetroAchievementsUI
//
//  Game row for the Consoles and Search lists, where the user has no progress
//  data — only the catalogue entry.
//

import SwiftUI

struct ConsoleGameDetailView: View {
    var gameListGame: GameListGame
    @Binding var hardcoreMode: Bool
    /// Search shows games from every system, so it needs the console name.
    var showConsoleName: Bool = false

    var body: some View {
        RARow(
            imageURL: RAImageURL.gameIcon(gameListGame.imageIcon),
            title: gameListGame.title,
            subtitle: showConsoleName ? gameListGame.consoleName : nil
        ) {
            HStack(spacing: 10) {
                RAMeta(systemImage: "trophy.fill",
                       text: "\(gameListGame.numAchievements)")
                RAMeta(systemImage: "command.circle.fill",
                       text: "\(gameListGame.points)")
            }
            .padding(.top, 3)
        }
    }
}

#Preview {
    @Previewable @State var hardcoreMode: Bool = true
    let previewGame = GameListGame(
        title: "Super Mario 64", id: 10003, consoleID: 2,
        consoleName: "Nintendo 64", imageIcon: "/Images/047942.png",
        numAchievements: 114, numLeaderboards: 0, points: 500,
        dateModified: "N/A", forumTopicID: -1)

    return List {
        ConsoleGameDetailView(gameListGame: previewGame, hardcoreMode: $hardcoreMode)
        ConsoleGameDetailView(gameListGame: previewGame, hardcoreMode: $hardcoreMode,
                              showConsoleName: true)
    }
}
