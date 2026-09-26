//
//  UserProfileView.swift
//  RetroAchievementsUI
//
//  Somebody else's profile: who they are, what they are playing, what they
//  have earned lately.
//
//  Deliberately not a parameterised ProfileView. That screen is the app's
//  centrepiece and is built to fit one page without scrolling, with loading
//  rules tuned around the signed-in user's own data; bending it to take an
//  arbitrary username would put all of that at risk to save a few rows of
//  layout. This is the visitor's view — it scrolls, it is read-only, and it
//  shows only what one round of requests can honestly fill in.
//

import SwiftUI
import Kingfisher

struct UserProfileView: View {
    @EnvironmentObject var network: Network
    @Environment(\.selectedGameID) var selectedGameID: Binding<GameSheetItem?>
    @Binding var hardcoreMode: Bool

    let username: String

    @State private var isLoading = true
    @State private var loadError: RANetworkError?

    private var key: String { Network.userKey(username) }
    private var profile: Profile? { network.otherProfileCache[key] }
    private var awards: Awards? { network.otherAwardsCache[key] }
    private var recentGames: [RecentGame] { network.otherRecentGamesCache[key] ?? [] }

    /// Newest first, and softcore unlocks dropped in hardcore mode — the same
    /// rule the signed-in user's deck follows.
    private var recentAchievements: [RecentAchievement] {
        (network.otherRecentAchievementsCache[key] ?? [])
            .filter { !hardcoreMode || $0.hardcoreMode == 1 }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header

                if isLoading && profile == nil {
                    ProgressView()
                        .padding(.top, 40)
                } else if let loadError, profile == nil {
                    RAErrorView(error: loadError, retry: { await load() })
                        .padding(.top, 20)
                } else {
                    if !recentAchievements.isEmpty { recentAchievementsSection }
                    if !recentGames.isEmpty { recentGamesSection }
                    if let awards { awardsSummary(awards) }
                }
            }
            .padding(.bottom, 28)
        }
        .background(Color.raSurface)
        .navigationTitle(profile?.user ?? username)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { pinButton }
        }
        .task { await load() }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 10) {
            KFImage(RAImageURL.avatar(profile?.userPic))
                .resizable()
                .placeholder { Circle().fill(Color.raSurfaceSunken) }
                .aspectRatio(contentMode: .fill)
                .frame(width: 88, height: 88)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(Color.raSeparator, lineWidth: 1))

            Text(profile?.user ?? username)
                .font(.raDisplay)
                .foregroundStyle(Color.raTextPrimary)

            if let motto = profile?.motto, !motto.isEmpty {
                Text(motto)
                    .font(.raCaption)
                    .foregroundStyle(Color.raTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if let presence = presenceText {
                RAChip(presence, systemImage: "dot.radiowaves.left.and.right",
                       tint: Color.raAccent)
            }

            if let profile { statsRow(profile) }
        }
        .padding(.top, 8)
    }

    /// What they are playing, when the API says anything at all.
    ///
    /// RichPresenceMsg is free text written by each game's set, so it is shown
    /// verbatim rather than parsed — it reads as "Playing Super Mario 64" on
    /// some sets and as a live score on others.
    private var presenceText: String? {
        guard let message = profile?.richPresenceMsg?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !message.isEmpty,
              message.caseInsensitiveCompare("Unknown") != .orderedSame
        else { return nil }
        return message
    }

    private func statsRow(_ profile: Profile) -> some View {
        HStack(spacing: 0) {
            stat("\(hardcoreMode ? profile.totalPoints : profile.totalSoftcorePoints)",
                 label: hardcoreMode ? "POINTS" : "SOFTCORE PTS")
            divider
            stat("\(profile.totalTruePoints)", label: "TRUE PTS")
            if let since = Self.memberSince(profile.memberSince) {
                divider
                stat(since, label: "MEMBER SINCE")
            }
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color.raSurfaceRaised, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 16)
    }

    private func stat(_ value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                .foregroundStyle(Color.raTextPrimary)
            Text(label)
                .font(.raStatSmall)
                .foregroundStyle(Color.raTextTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.raSeparator)
            .frame(width: 1, height: 26)
    }

    private var pinButton: some View {
        Button {
            if network.isPinned(username) {
                network.unpinUser(username)
            } else {
                _ = network.pinUser(username)
            }
        } label: {
            Image(systemName: network.isPinned(username) ? "pin.fill" : "pin")
                .foregroundStyle(Color.raAccent)
        }
        .accessibilityLabel(network.isPinned(username) ? "Unpin \(username)" : "Pin \(username)")
    }

    // MARK: - Sections

    private var recentAchievementsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeading("Recent Achievements")
            RACardCarousel(items: recentAchievements) { achievement in
                Button {
                    selectedGameID.wrappedValue = GameSheetItem(id: achievement.gameID)
                } label: {
                    RACardCell(face: .achievement(
                        achievement,
                        rarity: network.rarity(forAchievement: achievement.id)))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var recentGamesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeading("Recently Played")
            RACardCarousel(items: recentGames) { game in
                Button {
                    selectedGameID.wrappedValue = GameSheetItem(id: game.id)
                } label: {
                    RACardCell(face: .game(game,
                                           hardcoreMode: hardcoreMode,
                                           highestAwardKind: nil))
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// Counts rather than the award cards themselves: the cards are built from
    /// the signed-in user's own award list and its game lookups, which a
    /// visitor's page has not loaded.
    private func awardsSummary(_ awards: Awards) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeading("Awards")
            HStack(spacing: 10) {
                awardTile("\(awards.masteryAwardsCount)", "MASTERED")
                awardTile("\(awards.completionAwardsCount)", "COMPLETED")
                awardTile("\(awards.beatenHardcoreAwardsCount)", "BEATEN")
                awardTile("\(awards.totalAwardsCount)", "TOTAL")
            }
            .padding(.horizontal, 16)
        }
    }

    private func awardTile(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                .foregroundStyle(Color.raTextPrimary)
            Text(label)
                .font(.raStatSmall)
                .foregroundStyle(Color.raTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.raSurfaceRaised, in: RoundedRectangle(cornerRadius: 12))
    }

    private func sectionHeading(_ text: String) -> some View {
        Text(text)
            .font(.raTitle)
            .foregroundStyle(Color.raTextPrimary)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Loading

    private func load() async {
        isLoading = profile == nil
        loadError = await network.getUserOverview(username: username)
        isLoading = false
    }

    /// "Jan 2016" from the API's "2016-01-02 00:43:04".
    static func memberSince(_ raw: String) -> String? {
        guard let date = apiFormatter.date(from: raw) else { return nil }
        return monthYearFormatter.string(from: date)
    }

    private static let apiFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()

    private static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM yyyy")
        return formatter
    }()
}
