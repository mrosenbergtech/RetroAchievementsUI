//
//  ProfileView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//
//  The profile is designed to fit one screen with no vertical scrolling.
//
//  Rather than hardcoding a card size that happens to fit one device, the three
//  deck rows are flexible: the header and section headings take their natural
//  height and the rows split whatever is left, deriving card size from it. That
//  fits by construction on any screen, and adapts when a section is absent (a
//  user with no awards gets two larger decks) or when Dynamic Type grows the
//  chrome. On a screen too short to honour the minimum card size the page
//  scrolls rather than clipping.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var network: Network
    @Environment(\.selectedGameID) var selectedGameID: Binding<GameSheetItem?>
    @Binding var hardcoreMode: Bool
    @Binding var showUnofficial: Bool

    // Settings is presented from here rather than living in a tab. The
    // credential bindings are passed through so the sheet can own login/logout.
    @Binding var webAPIUsername: String
    @Binding var webAPIKey: String
    @Binding var shouldShowLoginSheet: Bool

    @Environment(\.scenePhase) private var scenePhase
    @State private var forceSkeleton: Bool = false
    @State private var showSettings: Bool = false
    @State private var showAllAwards: Bool = false

    /// Below this the decks stop shrinking and the page starts scrolling.
    private let minimumCardHeight: CGFloat = 132
    @Environment(\.horizontalSizeClass) private var sizeClass

    /// Upper bound on card width.
    ///
    /// A single cap sized for iPhone left large dead gaps under every deck on
    /// iPad, where each row is given far more height than a 168pt card needs.
    /// The regular-width cap lets the cards actually fill the row.
    private var maximumCardWidth: CGFloat {
        sizeClass == .regular ? 260 : 168
    }

    private var isLoading: Bool {
        if network.isFetching || forceSkeleton { return true }
        // No data AND no explanation means the first response hasn't landed.
        // Once there is an error, stop showing the skeleton — it would other-
        // wise spin forever on a failure, which is the bug this replaced.
        return network.profile == nil && network.lastError == nil
    }

    private var awardCount: Int {
        network.awardCards(hardcoreMode: hardcoreMode).count
    }

    private var hasAwards: Bool { awardCount > 0 }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ScrollView {
                    VStack(spacing: 10) {
                        ProfileHeaderView(hardcoreMode: $hardcoreMode) {
                            showSettings = true
                        }

                        if isLoading {
                            skeletonDecks
                        } else if let error = network.lastError, network.hasNoProfileData {
                            // Nothing to show and a reason why — take the
                            // screen over and offer the way out.
                            RAErrorView(
                                error: error,
                                retry: { await network.fetchAllProfileData() },
                                openSettings: { showSettings = true }
                            )
                            .frame(minHeight: geo.size.height * 0.5)
                        } else {
                            decks
                        }
                    }
                    // Breathing room so the last deck doesn't sit flush against
                    // the tab bar. Inside the minHeight frame, so the flexible
                    // rows give this height up rather than overflowing.
                    .padding(.bottom, 16)
                    // At least a full screen, so the flexible rows have a
                    // definite height to divide between them.
                    .frame(minHeight: geo.size.height, alignment: .top)
                }
                // The page is sized to fit exactly, so it must not move at all.
                // `.basedOnSize` disables the bounce when content fits, which
                // also means no pull-to-refresh here — refreshing happens on
                // return to foreground instead (see scenePhase below). On a
                // screen too small to fit, content overflows, scrolling becomes
                // real, and pull-to-refresh comes back with it.
                .scrollBounceBehavior(.basedOnSize)
                .refreshable { await refreshWithMinimumDuration() }
            }
            .background(Color.raSurface)
            .overlay(alignment: .top) {
                // Data on screen but the last refresh failed: report it without
                // hiding content the user can still read.
                if let error = network.lastError, !network.hasNoProfileData, !isLoading,
                   error.deservesBannerOverExistingData {
                    RAErrorBanner(error: error) {
                        await network.fetchAllProfileData()
                    }
                }
            }
            .animation(.easeInOut(duration: 0.25), value: network.lastError)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showAllAwards) {
                AwardsCollectionView(hardcoreMode: $hardcoreMode)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: isLoading)
        .sheet(isPresented: $showSettings) {
            SettingsView(webAPIUsername: $webAPIUsername,
                         webAPIKey: $webAPIKey,
                         hardcoreMode: $hardcoreMode,
                         showUnofficial: $showUnofficial,
                         shouldShowLoginSheet: $shouldShowLoginSheet)
                .environmentObject(network)
        }
        .task {
            if network.profile == nil {
                await network.fetchAllProfileData()
            }
        }
        // Stands in for the pull-to-refresh the fixed layout gives up: coming
        // back to the app is when the data is most likely to be stale.
        .onChange(of: scenePhase) { previous, phase in
            guard phase == .active, previous == .background,
                  network.webAPIAuthenticated else { return }
            Task { await network.fetchAllProfileData() }
        }
    }

    // MARK: - Decks

    @ViewBuilder
    private var decks: some View {
        // Omitted entirely for a user with no awards — an empty trophy shelf is
        // worse than no shelf, and the other two decks get the space.
        if hasAwards {
            deck("Awards", icon: "trophy") {
                Button {
                    showAllAwards = true
                } label: {
                    HStack(spacing: 2) {
                        Text("See All \(awardCount)")
                            .font(.raCaption.weight(.semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(Color.raAccent)
                }
                .buttonStyle(.plain)
            } content: { width in
                AwardsShelfView(hardcoreMode: $hardcoreMode, cardWidth: width)
            }
        }

        deck("Recently Played", icon: "clock.arrow.circlepath") { width in
            RecentGamesView(hardcoreMode: $hardcoreMode,
                            showUnofficial: $showUnofficial,
                            cardWidth: width)
        }

        deck("Recent Achievements", icon: "medal") { width in
            RecentAchievementsView(hardcoreMode: $hardcoreMode,
                                   showUnofficial: $showUnofficial,
                                   cardWidth: width)
        }
    }

    private var skeletonDecks: some View {
        ForEach(["Awards", "Recently Played", "Recent Achievements"], id: \.self) { title in
            deck(title, icon: "square.dashed") { width in
                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { _ in
                        SkeletonCard().frame(width: width)
                    }
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .skeleton()
    }

    /// A titled row whose card width is derived from the height it is given.
    private func deck<Trailing: View, Content: View>(
        _ title: String,
        icon: String,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() },
        @ViewBuilder content: @escaping (CGFloat) -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Label(title, systemImage: icon)
                    .font(.raTitle)
                    .foregroundStyle(Color.raTextPrimary)
                Spacer(minLength: 8)
                trailing()
            }
            .padding(.horizontal, 16)

            GeometryReader { row in
                content(min(row.size.height * RACardMetrics.aspectRatio, maximumCardWidth))
                    .frame(height: row.size.height, alignment: .top)
            }
            .frame(minHeight: minimumCardHeight, maxHeight: .infinity)
        }
    }

    // MARK: - Refresh

    private func refreshWithMinimumDuration() async {
        forceSkeleton = true
        let startTime = Date()
        await network.fetchAllProfileData()

        // Floor the spinner so a warm cache doesn't flash the skeleton.
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
    @Previewable @State var showUnofficial = false
    @Previewable @State var username = debugWebAPIUsername
    @Previewable @State var key = debugWebAPIKey
    @Previewable @State var showLogin = false

    let network = Network()
    Task {
        await network.authenticateCredentials(webAPIUsername: debugWebAPIUsername, webAPIKey: debugWebAPIKey)
        await network.fetchAllProfileData()
    }
    return ProfileView(hardcoreMode: $hardcoreMode, showUnofficial: $showUnofficial,
                       webAPIUsername: $username, webAPIKey: $key,
                       shouldShowLoginSheet: $showLogin)
        .environmentObject(network)
}
