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
    @Binding var showUnofficial: Bool

    @State private var showSyncCompleteToast: Bool = false

    private let consoleCardWidth: CGFloat = 112
    /// ConsoleGridItemView's natural height: icon plate + two title lines +
    /// padding. A carousel row inside a List has to be told its height.
    private let consoleCardHeight: CGFloat = 154

    var body: some View {
        NavigationStack {
            Group {
                if network.consolesCache == nil {
                    loading
                } else if network.isFetchingFullGameList && network.gameList.isEmpty {
                    firstSync
                } else {
                    grid
                }
            }
            .background(Color.raSurface)
            .navigationTitle("Consoles")
            .navigationBarTitleDisplayMode(.large)
            .onChange(of: network.isFetchingFullGameList) { oldValue, newValue in
                if oldValue && !newValue {
                    withAnimation { showSyncCompleteToast = true }
                }
            }
            .toast(isShowing: $showSyncCompleteToast, message: "Game library synchronised")
            .navigationDestination(for: ConsoleRoute.self) { route in
                ConsoleGamesView(hardcoreMode: $hardcoreMode,
                                 showUnofficial: $showUnofficial,
                                 consoleID: route.consoleID)
            }
        }
    }

    // MARK: - Grid

    /// Manufacturer sections in a List, each holding a grid of console plates.
    ///
    /// Navigation is value-based (`NavigationLink(value:)` +
    /// `navigationDestination(for:)`). The eager `NavigationLink(destination:)`
    /// form built a destination for every console in the grid, and tapping one
    /// pushed several — so Back stepped through the rest of the manufacturer's
    /// consoles instead of returning here.
    private var grid: some View {
        List {
            ForEach(manufacturers, id: \.id) { manufacturer in
                Section {
                    RACardCarousel(items: consoles(in: manufacturer),
                                   width: consoleCardWidth) { console in
                        NavigationLink(value: ConsoleRoute(consoleID: console.id)) {
                            ConsoleGridItemView(console: console)
                        }
                        .buttonStyle(CardPressStyle())
                    }
                    .frame(height: consoleCardHeight)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } header: {
                    HStack {
                        Text(manufacturer.id)
                            .font(.raTitle)
                            .foregroundStyle(Color.raTextPrimary)
                        Spacer()
                        Text("\(consoles(in: manufacturer).count)")
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

    /// Resolves a manufacturer's hardcoded console IDs to the consoles the API
    /// actually returned.
    private func consoles(in manufacturer: ConsoleByManuFacturer) -> [Console] {
        manufacturer.consoleIDList.compactMap {
            network.consolesCache?.getConsoleDataByID(consoleID: $0)
        }
    }

    private var manufacturers: [ConsoleByManuFacturer] {
        (network.consolesCache?.consolesSortedByKind ?? [])
            .sorted { $0.id.lowercased() < $1.id.lowercased() }
    }

    // MARK: - Loading states

    private var loading: some View {
        VStack(spacing: 16) {
            ProgressView().controlSize(.large)
            Text("Loading consoles…")
                .font(.raBody)
                .foregroundStyle(Color.raTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// The first login syncs the entire RA catalogue, which takes minutes.
    private var firstSync: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 34))
                .foregroundStyle(Color.raAccent)

            VStack(spacing: 6) {
                Text("Building your game library")
                    .font(.raTitle)
                    .foregroundStyle(Color.raTextPrimary)
                Text("This runs once and is cached for a week.")
                    .font(.raCaption)
                    .foregroundStyle(Color.raTextSecondary)
            }

            VStack(spacing: 6) {
                ProgressView(value: network.syncProgressPercentage, total: 100)
                    .progressViewStyle(.linear)
                    .tint(.raAccent)
                Text("\(Int(network.syncProgressPercentage))%")
                    .font(.raStatSmall)
                    .foregroundStyle(Color.raTextTertiary)
            }
            .padding(.horizontal, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Typed route so console pushes cannot collide with any other destination
/// value on the stack.
struct ConsoleRoute: Hashable {
    let consoleID: Int
}

#Preview {
    @Previewable @State var hardcoreMode: Bool = true
    @Previewable @State var showUnofficial = false
    let network = Network()

    Task {
        await network.authenticateCredentials(webAPIUsername: debugWebAPIUsername, webAPIKey: debugWebAPIKey)
        await network.getGameConsoles()
    }

    return ConsolesView(hardcoreMode: $hardcoreMode, showUnofficial: $showUnofficial)
        .environmentObject(network)
        .environment(\.selectedGameID, .constant(nil))
}
