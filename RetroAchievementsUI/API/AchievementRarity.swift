//
//  AchievementRarity.swift
//  RetroAchievementsUI
//
//  How rare an achievement is, as a share of the game's players who hold it.
//
//  Needs two numbers: the achievement's `NumAwarded` and the game's
//  `NumDistinctPlayers`. Both come from GetGameInfoAndUserProgress, so rarity
//  is known anywhere a GameSummary is in hand — the game sheet and everything
//  it feeds.
//
//  It is NOT knowable from GetUserRecentAchievements, which carries no award
//  counts and no player total. Rather than colour the same achievement
//  differently on two screens, rarity is simply absent there; see
//  RACardFace.achievement(_:).
//

import Foundation
import SwiftUI

enum AchievementRarity: String, CaseIterable, Comparable {
    /// Held by more than half of the game's players.
    case common
    /// 33–50%.
    case uncommon
    /// 20–33%.
    case rare
    /// 10–20%.
    case epic
    /// The hardest tenth.
    case legendary

    /// - Parameter unlockPercentage: 0–100, the share of players holding it.
    init(unlockPercentage: Double) {
        switch unlockPercentage {
        case ..<0:      self = .common          // nonsense input, degrade quietly
        case ...10:     self = .legendary
        case ...20:     self = .epic
        case ...33:     self = .rare
        case ...50:     self = .uncommon
        default:        self = .common
        }
    }

    var displayName: String {
        switch self {
        case .common:    return "Common"
        case .uncommon:  return "Uncommon"
        case .rare:      return "Rare"
        case .epic:      return "Epic"
        case .legendary: return "Legendary"
        }
    }

    /// Compact label for the badge on a list row.
    var shortName: String {
        switch self {
        case .common:    return "COMMON"
        case .uncommon:  return "UNCOMMON"
        case .rare:      return "RARE"
        case .epic:      return "EPIC"
        case .legendary: return "LEGENDARY"
        }
    }

    /// The tier's signature colour, for badges outside the card face.
    var tint: Color { RarityMaterial.of(self).ink }

    private var rank: Int {
        switch self {
        case .common:    return 0
        case .uncommon:  return 1
        case .rare:      return 2
        case .epic:      return 3
        case .legendary: return 4
        }
    }

    static func < (lhs: AchievementRarity, rhs: AchievementRarity) -> Bool {
        lhs.rank < rhs.rank
    }
}

extension Achievement {
    /// Share of the game's players holding this achievement, 0–100.
    ///
    /// `nil` when the player count is unknown or zero — a game nobody has
    /// played yet would otherwise divide by zero.
    func unlockPercentage(totalPlayers: Int?) -> Double? {
        guard let totalPlayers, totalPlayers > 0 else { return nil }
        return min(Double(numAwarded) / Double(totalPlayers) * 100, 100)
    }

    func rarity(totalPlayers: Int?) -> AchievementRarity? {
        unlockPercentage(totalPlayers: totalPlayers).map(AchievementRarity.init(unlockPercentage:))
    }
}

extension GameSummary {
    /// Achievements ordered rarest first, then by the set's own display order.
    var achievementsByRarity: [Achievement] {
        orderedAchievements.sorted { a, b in
            let lhs = a.unlockPercentage(totalPlayers: numDistinctPlayers) ?? 100
            let rhs = b.unlockPercentage(totalPlayers: numDistinctPlayers) ?? 100
            if lhs == rhs { return a.displayOrder < b.displayOrder }
            return lhs < rhs
        }
    }
}
