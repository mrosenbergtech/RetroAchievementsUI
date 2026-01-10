//
//  MyGamesView.swift
//  RetroAchievementsUI
//

import SwiftUI

struct MyGamesView: View {
    @EnvironmentObject var network: Network
    @Environment(\.selectedGameID) var selectedGameID: Binding<GameSheetItem?>
    @Binding var hardcoreMode: Bool
    
    // NEW: Local state to force the skeleton visibility
    @State private var forceSkeleton: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // LAYER 1: The Actual Data
                Form {
                    if let progress = network.userGameCompletionProgress, progress.results.count > 0 {
                        ForEach(network.consolesCache?.consoles.sorted { $0.name.lowercased() < $1.name.lowercased() } ?? []) { console in
                            let consoleGames = progress.results.filter({ $0.consoleName == console.name })
                            if consoleGames.count > 0 {
                                Section(header: Text(console.name)) {
                                    ForEach(consoleGames.sorted { $0.title.lowercased() < $1.title.lowercased() }) { game in
                                        Button {
                                            selectedGameID.wrappedValue = GameSheetItem(id:game.id)
                                        } label: {
                                            GameSummaryPreviewView(
                                                hardcoreMode: $hardcoreMode,
                                                imageIconString: game.imageIcon,
                                                gameTitle: game.title,
                                                gameConsoleName: game.consoleName,
                                                maxPossible: game.maxPossible,
                                                numAwardedHardcore: game.numAwardedHardcore,
                                                numAwarded: game.numAwarded,
                                                highestAwardKind: game.highestAwardKind
                                            )
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    } else if !network.isFetching {
                        Section {
                            ContentUnavailableView("No Games Found", systemImage: "gamecontroller.fill", description: Text("Give one a try!"))
                        }
                    }
                }
                .navigationBarTitle("My Games")
                .navigationBarHidden(true)
                .refreshable {
                    await refreshWithMinimumDuration()
                }

                // LAYER 2: The Skeleton Overlay
                // We check both the network state AND our local force state
                if network.isFetching || forceSkeleton {
                    VStack(spacing: 0) {
                        Form {
                            skeletonRows
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(UIColor.systemGroupedBackground))
                    .scrollDisabled(true)
                    .navigationBarTitle("My Games")
                    .navigationBarHidden(true)
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: network.isFetching || forceSkeleton)
        }
    }
    
    private func refreshWithMinimumDuration() async {
        // 1. Manually trigger the skeleton appearance
        forceSkeleton = true
        let startTime = Date()
        
        // 2. Perform the fetch
        await network.getUserGameCompletionProgress()
        
        // 3. Calculate remaining time for the 1.5s window
        let elapsed = Date().timeIntervalSince(startTime)
        let minimumDuration: TimeInterval = 1.5
        
        if elapsed < minimumDuration {
            let delay = UInt64((minimumDuration - elapsed) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: delay)
        }
        
        // 4. Hide the skeleton
        forceSkeleton = false
    }
    
    @ViewBuilder
    private var skeletonRows: some View {
        ForEach(0..<3, id: \.self) { sectionIndex in
            Section(header: Text("Console Name")) {
                ForEach(0..<3, id: \.self) { rowIndex in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 48, height: 48)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 150, height: 14)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 100, height: 10)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .redacted(reason: .placeholder)
        .pulsing()
        .disabled(true)
    }
}

#Preview {
    @Previewable @State var hardcoreMode: Bool = true
    let network = Network()
    Task {
        await network.authenticateCredentials(webAPIUsername: "SampleUser", webAPIKey: "SampleKey")
        await network.getUserGameCompletionProgress()
    }
    return MyGamesView(hardcoreMode: $hardcoreMode)
        .environmentObject(network)
}
