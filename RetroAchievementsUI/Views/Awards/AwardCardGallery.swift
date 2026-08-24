//
//  AwardCardGallery.swift
//  RetroAchievementsUI
//
//  Design harness for every card variant in the app.
//
//  Real accounts rarely hold all five award tiers at once, and locked
//  achievements only appear inside a game sheet, so this renders one of each
//  from fixed sample data.
//
//  Preview-only: the #Preview blocks below are the entry point, via the Xcode
//  canvas. Nothing in the shipping UI references this type.
//

import SwiftUI

struct AwardCardGallery: View {
    var hardcoreMode: Bool = true
    /// Long title, to check that nameplate clamping holds the card geometry.
    var stressTitles: Bool = false

    /// Three columns, matching the real grid widths — the cards must be judged
    /// at the size they actually ship at.
    private let columns = [GridItem(.adaptive(minimum: 104, maximum: 140), spacing: 12)]

    private func title(_ fallback: String) -> String {
        stressTitles ? "The Legend of Zelda: Majora's Mask 3D Special Edition" : fallback
    }

    // MARK: - Sample faces

    private var awardFaces: [(String, RACardFace)] {
        AwardTier.allCases.enumerated().map { index, tier in
            let card = AwardCardModel(
                id: "sample-\(tier.rawValue)",
                gameID: 1000 + index,
                tier: tier,
                title: title(Self.titles[index % Self.titles.count]),
                consoleName: tier == .site ? nil : Self.consoles[index % Self.consoles.count],
                awardedAt: Calendar.current.date(byAdding: .month, value: -index * 5, to: Date()),
                iconPath: nil,
                numAwarded: 44,
                numAwardedHardcore: 44,
                maxPossible: tier == .site ? 0 : 56
            )
            return (tier.rawValue, .award(card, hardcoreMode: hardcoreMode))
        }
    }

    private var gameFaces: [(String, RACardFace)] {
        [
            ("unbeaten", .game(title: title("Thrillville: Off the Rails"),
                               consoleName: "PlayStation Portable",
                               iconPath: nil,
                               earned: 7, total: 82,
                               highestAwardKind: nil)),
            ("in-progress-beaten", .game(title: title("Metroid Prime"),
                                         consoleName: "GameCube",
                                         iconPath: nil,
                                         earned: 3, total: 62,
                                         highestAwardKind: "beaten-hardcore")),
            ("achievement-locked", .achievement(Self.sample(numAwarded: 15, unlocked: false,
                                                            title: "Locked Epic"),
                                                gameTitle: "Super Mario 64",
                                                hardcoreMode: hardcoreMode,
                                                rarity: .epic)),
            ("achievement-unranked", .achievement(Self.recentSample)),
        ]
    }

    /// One unlocked achievement per rarity tier, side by side. Award counts are
    /// chosen to land in each band of a 100-player game — see AchievementRarity
    /// for the thresholds.
    private var rarityFaces: [(String, RACardFace)] {
        // Unlock shares of a 100-player game, one in each band.
        let samples: [(AchievementRarity, Int)] = [
            (.common, 80), (.uncommon, 45), (.rare, 25), (.epic, 15), (.legendary, 5),
        ]
        return samples.map { rarity, awarded in
            let sample = Self.sample(numAwarded: awarded, unlocked: true,
                                     title: rarity.displayName)
            return (rarity.rawValue,
                    .achievement(sample, gameTitle: "Super Mario 64",
                                 hardcoreMode: hardcoreMode,
                                 rarity: sample.rarity(totalPlayers: 100)))
        }
    }

    private static func sample(numAwarded: Int, unlocked: Bool,
                               title: String) -> Achievement {
        Achievement(
            id: abs("\(title)\(numAwarded)".hashValue % 100_000),
            numAwarded: numAwarded, numAwardedHardcore: numAwarded,
            title: title, description: "Grab 120 Power Stars.",
            points: 10, trueRatio: 10, author: "a",
            dateModified: nil, dateCreated: "", badgeName: "84225",
            displayOrder: 1, memAddr: "", type: "progression",
            dateEarnedHardcore: unlocked ? "2024-01-01 00:00:00" : nil,
            dateEarned: unlocked ? "2024-01-01 00:00:00" : nil)
    }

    /// The profile deck's shape: unlocked, but with no rarity to show.
    private static let recentSample = RecentAchievement(
        id: 9, date: "2024-01-01 00:00:00", hardcoreMode: 1,
        title: "Unranked", description: "", badgeName: "84225", points: 10,
        trueRatio: 10, type: nil, author: "a", gameTitle: "Super Mario 64",
        gameIcon: "", gameID: 1, consoleName: "N64", badgeURL: "", gameURL: "")

    private static let titles = [
        "Super Mario 64", "Mario Party", "Metroid Prime",
        "Sonic the Hedgehog 2", "Summer Event 2024",
    ]
    private static let consoles = [
        "Nintendo 64", "Nintendo 64", "GameCube", "Mega Drive", "Events",
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                group("Award tiers", faces: awardFaces)
                group("Achievement rarity", faces: rarityFaces)
                group("Games", faces: gameFaces)
            }
            .padding(.vertical, 16)
        }
        .background(Color.raSurface)
    }

    private func group(_ title: String, faces: [(String, RACardFace)]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.raTitle)
                .foregroundStyle(Color.raTextPrimary)
                .padding(.horizontal, 16)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(faces, id: \.0) { _, face in
                    RACardCell(face: face)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

#Preview("All cards") {
    AwardCardGallery()
}

#Preview("Long titles") {
    AwardCardGallery(stressTitles: true)
}
