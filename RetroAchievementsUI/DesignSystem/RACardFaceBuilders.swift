//
//  RACardFaceBuilders.swift
//  RetroAchievementsUI
//
//  Turns each domain model into a card face. Keeping these together means the
//  tagline vocabulary — MASTERED / BEATEN / UNBEATEN / UNLOCKED — is defined
//  once rather than restated in every screen.
//

import Foundation

extension RACardFace {

    // MARK: - Awards

    static func award(_ card: AwardCardModel, hardcoreMode: Bool) -> RACardFace {
        RACardFace(
            artPath: card.iconPath,
            placeholderSymbol: card.tier == .site ? "star.circle" : "gamecontroller",
            title: card.title,
            subtitle: subtitle(console: card.consoleName, trailing: card.awardedYear),
            tagline: card.tier.displayName,
            trailingStat: card.maxPossible > 0
                ? "\(card.earned(hardcoreMode: hardcoreMode))/\(card.maxPossible)"
                : nil,
            material: .of(card.tier)
        )
    }

    // MARK: - Games

    /// A game card, for Recently Played and My Games.
    ///
    /// A game the user has not beaten still gets a card — it just wears the
    /// plainest stock and reads "UNBEATEN", so progress is visible without
    /// diluting what an award means.
    static func game(
        title: String,
        consoleName: String?,
        iconPath: String?,
        earned: Int,
        total: Int,
        highestAwardKind: String?,
        showConsoleName: Bool = true
    ) -> RACardFace {
        let tier = AwardTier(highestAwardKind: highestAwardKind)

        return RACardFace(
            artPath: iconPath,
            title: title,
            subtitle: showConsoleName ? consoleName : nil,
            tagline: tier?.displayName ?? "UNBEATEN",
            trailingStat: total > 0 ? "\(earned)/\(total)" : nil,
            material: tier.map(RarityMaterial.of) ?? .unbeaten
        )
    }

    static func game(_ progress: GameCompletionProgress,
                     hardcoreMode: Bool,
                     showConsoleName: Bool = true) -> RACardFace {
        game(
            title: progress.title,
            consoleName: progress.consoleName,
            iconPath: progress.imageIcon,
            earned: hardcoreMode ? progress.numAwardedHardcore : progress.numAwarded,
            total: progress.maxPossible,
            highestAwardKind: progress.highestAwardKind,
            showConsoleName: showConsoleName
        )
    }

    static func game(_ recent: RecentGame,
                     hardcoreMode: Bool,
                     highestAwardKind: String?) -> RACardFace {
        game(
            title: recent.title,
            consoleName: recent.consoleName,
            iconPath: recent.imageIcon,
            earned: hardcoreMode ? recent.numAchievedHardcore : recent.numAchieved,
            total: recent.numPossibleAchievements,
            highestAwardKind: highestAwardKind
        )
    }

    // MARK: - Achievements

    static func achievement(_ achievement: RecentAchievement,
                            rarity: AchievementRarity? = nil) -> RACardFace {
        RACardFace(
            // Recent achievements are always unlocked, so never the "_lock" art.
            artPath: "/Badge/\(achievement.badgeName).png",
            artIsBadge: true,
            placeholderSymbol: "medal",
            title: achievement.title,
            // Game title only. Appending the relative date pushed the line past
            // the card width and truncated both halves.
            subtitle: achievement.gameTitle,
            tagline: "UNLOCKED",
            trailingStat: "\(achievement.points)",
            // GetUserRecentAchievements carries no award counts, so rarity has
            // to come from Network's persisted index (see rarity(forAchievement:)).
            // Until that index has seen the parent game, the card wears the
            // neutral "earned" frame rather than guessing at a tier.
            material: rarity.map(RarityMaterial.of) ?? .achievementUnranked
        )
    }

    static func achievement(_ achievement: Achievement,
                            gameTitle: String? = nil,
                            hardcoreMode: Bool,
                            rarity: AchievementRarity? = nil) -> RACardFace {
        let unlocked = hardcoreMode
            ? achievement.dateEarnedHardcore != nil
            : achievement.dateEarned != nil

        return RACardFace(
            artPath: "/Badge/\(achievement.badgeName)\(unlocked ? "" : "_lock").png",
            artIsBadge: true,
            placeholderSymbol: "medal",
            title: achievement.title,
            subtitle: gameTitle ?? achievement.description,
            tagline: unlocked ? "UNLOCKED" : "LOCKED",
            trailingStat: "\(achievement.points)",
            // Rarity is a property of the achievement, not of your progress, so
            // a locked Legendary still wears its frame — dimmed, and with the
            // "_lock" badge art, so it cannot be mistaken for earned.
            material: rarity.map(RarityMaterial.of) ?? .achievementUnranked,
            dimmed: !unlocked
        )
    }

    // MARK: - Helpers

    /// "Nintendo 64 · 2023", collapsing gracefully when either half is missing.
    private static func subtitle(console: String?, trailing: String?) -> String? {
        switch (console, trailing) {
        case let (console?, trailing?): return "\(console) · \(trailing)"
        case let (console?, nil):       return console
        case let (nil, trailing?):      return trailing
        default:                        return nil
        }
    }
}
