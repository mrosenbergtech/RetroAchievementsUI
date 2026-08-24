//
//  AchievementSheetView.swift
//  RetroAchievementsUI
//
//  Everything about one achievement: the trading card, its stats, and the
//  community comment thread from API_GetComments.
//
//  Leads with the card rather than a plain badge-and-title header, so an
//  achievement is presented the way an award is — the card is this app's
//  vocabulary for "a thing you earned".
//
//  Named "…SheetView" because AchievementDetailView is already the compact row
//  inside the game sheet's achievement list.
//

import SwiftUI

struct AchievementSheetView: View {
    @EnvironmentObject var network: Network
    @Environment(\.dismiss) private var dismiss

    let achievement: Achievement
    var gameTitle: String?
    /// Total players of the parent game, used to express rarity as a share.
    var totalPlayers: Int?
    @Binding var hardcoreMode: Bool

    @State private var isLoadingComments = true
    @State private var commentsError: RANetworkError?
    /// Comments routinely spell out how to earn the achievement, so they stay
    /// behind a tap until the reader asks for them.
    @State private var commentsRevealed = false

    private var unlockedDate: String? {
        hardcoreMode ? achievement.dateEarnedHardcore : achievement.dateEarned
    }

    /// Player comments, newest first — see Array.playerComments.
    private var comments: [Comment] {
        (network.commentsCache[achievement.id] ?? []).playerComments
    }

    var body: some View {
        NavigationStack {
            List {
                Section { showcase }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                detailsSection
                commentsSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.raSurface)
            .navigationTitle("Achievement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task { await loadComments() }
    }

    // MARK: - Card

    /// The card carries badge, title, game and unlock state, so only the
    /// description and the typed-achievement chip need repeating beneath it.
    private var showcase: some View {
        VStack(spacing: 16) {
            RACardShowcase(
                face: .achievement(achievement,
                                   gameTitle: gameTitle,
                                   hardcoreMode: hardcoreMode,
                                   rarity: rarity),
                maxWidth: 220
            )
            .padding(.top, 14)

            VStack(spacing: 10) {
                Text(achievement.description)
                    .font(.raBody)
                    .foregroundStyle(Color.raTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                if let chip = typeChip {
                    RAChip(chip.label, systemImage: chip.icon, tint: chip.tint)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 8)
    }

    private var typeChip: (label: String, icon: String, tint: Color)? {
        switch achievement.type {
        case "missable":      return ("Missable", "exclamationmark.triangle.fill", .orange)
        case "progression":   return ("Progression", "arrow.forward.circle.fill", .blue)
        case "win_condition": return ("Win Condition", "flag.checkered", .green)
        default:              return nil
        }
    }

    // MARK: - Details

    private var detailsSection: some View {
        Section("Details") {
            if let unlockedDate {
                detailRow(hardcoreMode ? "Unlocked (Hardcore)" : "Unlocked", unlockedDate)
            }
            if let rarity {
                detailRow("Rarity", rarity.displayName)
            }
            if let unlockShare {
                detailRow("Earned By", unlockShare)
            }
            detailRow("Unlocks", "\(achievement.numAwarded)")
            detailRow("Hardcore Unlocks", "\(achievement.numAwardedHardcore)")
            detailRow("RetroPoints", "\(achievement.trueRatio)")
            detailRow("Author", achievement.author)
            if let created = Self.shortDate(achievement.dateCreated) {
                detailRow("Created", created)
            }
        }
        .listRowBackground(Color.raSurfaceRaised)
    }

    /// Share of the game's players holding this achievement. Only available
    /// when a GameSummary supplied the player count — see AchievementRarity for
    /// why the rarity tier itself is derived from TrueRatio instead.
    private var rarity: AchievementRarity? {
        achievement.rarity(totalPlayers: totalPlayers)
    }

    private var unlockShare: String? {
        guard let totalPlayers, totalPlayers > 0 else { return nil }
        let share = Double(achievement.numAwarded) / Double(totalPlayers) * 100
        return String(format: "%.1f%% of players", min(share, 100))
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.raBody)
                .foregroundStyle(Color.raTextSecondary)
            Spacer(minLength: 12)
            Text(value)
                .font(.raBody.weight(.semibold))
                .foregroundStyle(Color.raTextPrimary)
                .multilineTextAlignment(.trailing)
        }
    }

    // MARK: - Comments

    @ViewBuilder
    private var commentsSection: some View {
        Section {
            if isLoadingComments {
                HStack(spacing: 10) {
                    ProgressView().controlSize(.small)
                    Text("Loading comments…")
                        .font(.raBody)
                        .foregroundStyle(Color.raTextSecondary)
                }
            } else if let commentsError {
                // Scoped to this section: a comment thread failing is no reason
                // to tell the user their whole profile is broken.
                HStack(spacing: 10) {
                    Image(systemName: commentsError.systemImage)
                        .foregroundStyle(Color.raTextTertiary)
                    Text(commentsError.title)
                        .font(.raBody)
                        .foregroundStyle(Color.raTextSecondary)
                    Spacer()
                    Button("Retry") { Task { await loadComments() } }
                        .font(.raCaption.weight(.bold))
                        .buttonStyle(.plain)
                        .foregroundStyle(Color.raAccent)
                }
            } else if comments.isEmpty {
                Text("No comments yet.")
                    .font(.raBody)
                    .foregroundStyle(Color.raTextTertiary)
            } else if !commentsRevealed {
                spoilerBanner
            } else {
                ForEach(comments) { comment in
                    commentRow(comment)
                }
            }
        } header: {
            HStack {
                Text("Comments")
                Spacer()
                if !isLoadingComments && !comments.isEmpty && commentsRevealed {
                    Button("Hide") {
                        withAnimation(.easeInOut(duration: 0.2)) { commentsRevealed = false }
                    }
                    .font(.raCaption.weight(.semibold))
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.raAccent)
                    .textCase(nil)
                }
            }
        }
        .listRowBackground(Color.raSurfaceRaised)
    }

    /// Tappable cover over the thread.
    private var spoilerBanner: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { commentsRevealed = true }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "eye.slash.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.raTextTertiary)
                    .frame(width: 26)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(comments.count) comment\(comments.count == 1 ? "" : "s") hidden")
                        .font(.raBody.weight(.semibold))
                        .foregroundStyle(Color.raTextPrimary)
                    Text("May contain hints or spoilers.")
                        .font(.raCaption)
                        .foregroundStyle(Color.raTextSecondary)
                }

                Spacer(minLength: 8)

                Text("Show")
                    .font(.raCaption.weight(.bold))
                    .foregroundStyle(Color.raAccent)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func commentRow(_ comment: Comment) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Text(comment.user)
                    .font(.raBody.weight(.semibold))
                    .foregroundStyle(Color.raTextPrimary)
                Spacer(minLength: 8)
                if let relative = comment.relativeSubmitted {
                    Text(relative)
                        .font(.raStatSmall)
                        .foregroundStyle(Color.raTextTertiary)
                }
            }

            Text(comment.text)
                .font(.raBody)
                .foregroundStyle(Color.raTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 3)
    }

    /// The API dates these "yyyy-MM-dd HH:mm:ss".
    private static let apiFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        f.timeZone = TimeZone(abbreviation: "UTC")
        return f
    }()

    static func shortDate(_ raw: String) -> String? {
        guard let date = apiFormatter.date(from: raw) else { return nil }
        return date.formatted(date: .abbreviated, time: .omitted)
    }

    // MARK: - Loading

    private func loadComments() async {
        isLoadingComments = network.commentsCache[achievement.id] == nil
        commentsError = await network.getComments(achievementID: achievement.id)
        isLoadingComments = false
    }
}

#Preview {
    @Previewable @State var hardcoreMode = true
    let achievement = Achievement(
        id: 48638, numAwarded: 26359, numAwardedHardcore: 14360,
        title: "A New Journey", description: "Grab your first Power Star.",
        points: 1, trueRatio: 1, author: "SamuraiGoroh",
        dateModified: "2023-06-18 14:47:41", dateCreated: "2017-05-25 17:37:31",
        badgeName: "84220", displayOrder: 1, memAddr: "x", type: "progression",
        dateEarnedHardcore: "2023-01-14 21:24:32", dateEarned: "2023-01-14 21:24:32")

    return AchievementSheetView(achievement: achievement,
                                gameTitle: "Super Mario 64",
                                totalPlayers: 30000,
                                hardcoreMode: $hardcoreMode)
        .environmentObject(Network())
}
