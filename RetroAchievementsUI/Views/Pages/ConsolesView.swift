//
//  ConsolesView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/10/24.
//

import SwiftUI

struct ConsolesView: View {
    @EnvironmentObject var network: Network
    @Binding var hardcoreMode: Bool
    
    // Controls the visibility of the toast notification
    @State private var showSyncCompleteToast: Bool = false
        
    var body: some View {
        NavigationStack {
            Group {
                // CASE 1: Full screen loading state if we have NO consoles yet
                if network.consolesCache == nil {
                    VStack(spacing: 20) {
                        ProgressView()
                            .controlSize(.large)
                        Text("Loading Consoles...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                // CASE 2: Background fetching is active AND we have no games list yet
                // This replaces the view during the very first login sync
                else if network.isFetchingFullGameList && network.gameList.isEmpty {
                    VStack(spacing: 24) {
                        // Use a determinate ProgressView to show the percentage
                        ProgressView(value: network.syncProgressPercentage, total: 100.0) {
                            Text("Fetching Complete Game Library")
                                .font(.headline)
                        } currentValueLabel: {
                            Text("\(Int(network.syncProgressPercentage))%")
                                .font(.subheadline.monospacedDigit())
                                .foregroundColor(.secondary)
                        }
                        .progressViewStyle(.linear)
                        .padding(.horizontal, 40)
                        
                        Text("This may take a moment...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                // CASE 3: We have data! Show the list.
                else {
                    Form {
                        if let consoleKinds = network.consolesCache?.consolesSortedByKind {
                            ForEach(consoleKinds.sorted { $0.id.lowercased() < $1.id.lowercased() }) { consoleKind in
                                Section(header: Text(consoleKind.id)) {
                                    ForEach(consoleKind.consoleIDList, id: \.self) { consoleID in
                                        let consoleData = network.consolesCache?.getConsoleDataByID(consoleID: consoleID) ?? Console(id: -1, name: "Unknown", iconURL: "", active: false, isGameSystem: false)
                                        
                                        NavigationLink(destination: ConsoleGamesView(hardcoreMode: $hardcoreMode, consoleID: consoleID)) {
                                            ConsoleDetailView(console: consoleData, hardcoreMode: $hardcoreMode)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Consoles")
            .navigationBarTitleDisplayMode(.large)
            // MARK: - Notification Logic
            .onChange(of: network.isFetchingFullGameList) { oldValue, newValue in
                // If it just finished (flipped from true to false)
                if oldValue == true && newValue == false {
                    withAnimation {
                        showSyncCompleteToast = true
                    }
                }
            }
            // Use the toast modifier to show the success message over the list
            .toast(isShowing: $showSyncCompleteToast, message: "Game Library Synchronized!")
        }
    }
}

#Preview {
    @Previewable @State var hardcoreMode: Bool = true
    let network = Network()
    // Mock some progress for the preview
    network.syncProgressPercentage = 45.0
    network.isFetchingFullGameList = true
    return ConsolesView(hardcoreMode: $hardcoreMode).environmentObject(network)
}
