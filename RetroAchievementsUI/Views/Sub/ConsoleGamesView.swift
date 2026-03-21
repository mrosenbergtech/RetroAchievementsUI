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
    
    var body: some View {
        let baseList = showUnofficial ? network.gameList : network.gameList.filter { !$0.title.starts(with: "~") }
        if network.gameList.count > 0 {
            Form {
                ForEach(baseList.filter { $0.consoleID == consoleID }.sorted { $0.title.lowercased() < $1.title.lowercased() }) { game in
                    // We use a Button instead of NavigationLink to trigger the sheet in ContentView
                    Button {
                        selectedGameID.wrappedValue = GameSheetItem(id: game.id)
                    } label: {
                        ConsoleGameDetailView(gameListGame: game, hardcoreMode: $hardcoreMode)
                            .contentShape(Rectangle()) // Makes the entire row area tappable
                    }
                    .buttonStyle(.plain) // Prevents the text from turning blue
                }
            }
            .navigationBarTitle(network.consolesCache?.getConsoleDataByID(consoleID: consoleID).name ?? "Games")
            
        } else {
            VStack(spacing: 20) {
                ProgressView()
                Text("Loading games list...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var hardcoreMode: Bool = true
    @Previewable @State var showUnofficial = false
    let network = Network()
    
    // Wrapping in NavigationView for preview to show title behavior
    return NavigationView {
        ConsoleGamesView(hardcoreMode: $hardcoreMode, showUnofficial: $showUnofficial, consoleID: 2)
            .environmentObject(network)
    }
    .onAppear {
        Task {
            await network.authenticateCredentials(webAPIUsername: debugWebAPIUsername, webAPIKey: debugWebAPIKey)
        }
    }
}
