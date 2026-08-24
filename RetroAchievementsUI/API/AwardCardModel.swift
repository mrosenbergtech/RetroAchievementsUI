//
//  AwardCardModel.swift
//  RetroAchievementsUI
//
//  View model backing a single award trading card.
//
//  Joins the two API shapes that each hold half the card's data:
//    • VisibleUserAward (GetUserAwards)          — award kind, hardcore flag, awarded date
//    • GameCompletionProgress (GetUserCompletionProgress) — art, console, achievement counts
//
//  Both arrive from calls already made in parallel during fetchAllProfileData, so
//  building cards costs no extra requests at all — the card art is the game icon
//  that GetUserCompletionProgress already carries.
//

import Foundation

struct AwardCardModel: Identifiable, Equatable {

    /// Stable and unique even when a game appears under several award types.
    ///
    /// `VisibleUserAward` is `Identifiable` on `AwardData`, which is `nil` for
    /// every site award and duplicated across award types for the same game —
    /// using it directly made SwiftUI's diffing unstable.
    let id: String

    let gameID: Int?
    let tier: AwardTier
    let title: String
    let consoleName: String?
    let awardedAt: Date?

    /// Square game icon, always available. Used until box art is loaded, and as
    /// the permanent fallback for games that have no box art on file.
    let iconPath: String?

    let numAwarded: Int
    let numAwardedHardcore: Int
    let maxPossible: Int

    // MARK: - Derived

    var isSiteAward: Bool { tier == .site }

    /// Achievements earned, respecting the hardcore toggle.
    func earned(hardcoreMode: Bool) -> Int {
        hardcoreMode ? numAwardedHardcore : numAwarded
    }

    func completionFraction(hardcoreMode: Bool) -> Double {
        guard maxPossible > 0 else { return 0 }
        return Double(earned(hardcoreMode: hardcoreMode)) / Double(maxPossible)
    }

    var awardedYear: String? {
        guard let awardedAt else { return nil }
        return Self.yearFormatter.string(from: awardedAt)
    }

    var awardedDateText: String? {
        guard let awardedAt else { return nil }
        return Self.mediumFormatter.string(from: awardedAt)
    }

    // MARK: - Formatters

    /// GetUserAwards returns ISO8601 with a UTC offset, e.g. "2023-05-21T13:16:27+00:00".
    /// Nothing in the app parsed this before — awarded dates were simply never shown.
    private static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static let yearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy"
        return f
    }()

    private static let mediumFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    static func parseAwardDate(_ raw: String) -> Date? {
        iso8601.date(from: raw)
    }

    // MARK: - Building

    /// Joins awards to completion progress by game ID.
    ///
    /// - Parameters:
    ///   - awards: `visibleUserAwards`, already de-duplicated to the highest tier per game.
    ///   - progress: keyed by game ID for O(1) lookup.
    ///   - hardcoreMode: when true, softcore game awards are dropped entirely.
    ///     This preserves the app's existing behaviour — softcore awards are
    ///     hidden rather than dimmed. Site awards are never filtered out.
    static func build(
        awards: [VisibleUserAward],
        progress: [Int: GameCompletionProgress],
        hardcoreMode: Bool
    ) -> [AwardCardModel] {
        awards.compactMap { award in
            let tier = AwardTier(award: award)

            if hardcoreMode && !tier.survivesHardcoreFilter { return nil }

            let game = award.id.flatMap { progress[$0] }

            // Prefer the richer completion-progress record for display data,
            // falling back to whatever the award itself carries.
            let title = game?.title
                ?? award.title
                ?? "Unknown Game"

            let composite = [
                award.id.map(String.init) ?? "site",
                award.awardType,
                award.awardedAt,
            ].joined(separator: "-")

            return AwardCardModel(
                id: composite,
                gameID: award.id,
                tier: tier,
                title: title,
                consoleName: game?.consoleName ?? award.consoleName,
                awardedAt: parseAwardDate(award.awardedAt),
                iconPath: game?.imageIcon ?? award.imageIcon,
                numAwarded: game?.numAwarded ?? 0,
                numAwardedHardcore: game?.numAwardedHardcore ?? 0,
                maxPossible: game?.maxPossible ?? 0
            )
        }
    }
}
