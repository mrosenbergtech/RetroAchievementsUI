//
//  AwardTier.swift
//  RetroAchievementsUI
//
//  The RetroAchievements API describes awards with two disjoint vocabularies:
//
//    GetUserAwards            → AwardType: "Mastery/Completion" | "Game Beaten" | …
//                               AwardDataExtra: 1 == hardcore, 0 == softcore
//    GetUserCompletionProgress→ HighestAwardKind: "mastered" | "completed"
//                               | "beaten-hardcore" | "beaten-softcore"
//
//  Views used to switch on those raw strings in three different places. This
//  collapses both into one ordered tier that drives card rarity.
//

import Foundation

enum AwardTier: String, CaseIterable, Comparable {
    case beatenSoftcore
    case beatenHardcore
    case completed
    case mastered
    /// Events and site milestones — no game attached.
    case site

    // MARK: - Parsing

    /// Parses `HighestAwardKind` from GetUserCompletionProgress / GetGameInfoAndUserProgress.
    init?(highestAwardKind: String?) {
        switch highestAwardKind {
        case "mastered":         self = .mastered
        case "completed":        self = .completed
        case "beaten-hardcore":  self = .beatenHardcore
        case "beaten-softcore":  self = .beatenSoftcore
        default:                 return nil
        }
    }

    /// Derives a tier from a GetUserAwards entry.
    ///
    /// `AwardType` alone cannot distinguish mastered from completed — that
    /// distinction is carried by `AwardDataExtra` (the hardcore flag), exactly
    /// as it is for beaten. A site award has no console, so it is detected
    /// first.
    init(award: VisibleUserAward) {
        guard award.consoleID != nil else {
            self = .site
            return
        }

        let isHardcore = award.awardDataExtra == 1

        switch award.awardType {
        case "Mastery/Completion":
            self = isHardcore ? .mastered : .completed
        case "Game Beaten":
            self = isHardcore ? .beatenHardcore : .beatenSoftcore
        default:
            self = .site
        }
    }

    // MARK: - Semantics

    /// Site awards are neither hardcore nor softcore; they are excluded from
    /// the hardcore-mode filter by `countsAsHardcore` rather than this.
    var isHardcore: Bool {
        self == .mastered || self == .beatenHardcore
    }

    /// Whether this tier should survive the Hardcore Mode filter.
    ///
    /// Site awards always survive — hiding a user's event trophies when they
    /// flip Hardcore Mode would be surprising.
    var survivesHardcoreFilter: Bool {
        isHardcore || self == .site
    }

    var isMasteryClass: Bool {
        self == .mastered || self == .completed
    }

    /// Short, all-caps label for the card stat block.
    var displayName: String {
        switch self {
        case .mastered:       return "MASTERED"
        case .completed:      return "COMPLETED"
        case .beatenHardcore: return "BEATEN"
        case .beatenSoftcore: return "BEATEN"
        case .site:           return "EVENT"
        }
    }

    /// Longer label for the card detail view, where the softcore/hardcore
    /// distinction is worth spelling out.
    var longDisplayName: String {
        switch self {
        case .mastered:       return "Mastered"
        case .completed:      return "Completed"
        case .beatenHardcore: return "Beaten (Hardcore)"
        case .beatenSoftcore: return "Beaten (Softcore)"
        case .site:           return "Site Award"
        }
    }

    // MARK: - Comparable

    /// Rarity order, ascending. `site` sorts below the game tiers because it is
    /// a different axis entirely and gets its own filter bucket in the UI.
    private var rank: Int {
        switch self {
        case .site:           return 0
        case .beatenSoftcore: return 1
        case .beatenHardcore: return 2
        case .completed:      return 3
        case .mastered:       return 4
        }
    }

    static func < (lhs: AwardTier, rhs: AwardTier) -> Bool {
        lhs.rank < rhs.rank
    }
}
