//
//  AwardTierTests.swift
//  RetroAchievementsUITests
//
//  The tier enum reconciles the API's two award vocabularies and drives card
//  rarity, so its mapping is worth pinning down precisely.
//

import Foundation
import Testing
@testable import RetroAchievementsUI

@Suite("AwardTier")
struct AwardTierTests {

    // MARK: - HighestAwardKind (GetUserCompletionProgress)

    @Test("Parses every documented HighestAwardKind",
          arguments: [
            ("mastered", AwardTier.mastered),
            ("completed", AwardTier.completed),
            ("beaten-hardcore", AwardTier.beatenHardcore),
            ("beaten-softcore", AwardTier.beatenSoftcore),
          ])
    func parsesAwardKind(raw: String, expected: AwardTier) {
        #expect(AwardTier(highestAwardKind: raw) == expected)
    }

    @Test("Unknown or missing HighestAwardKind yields no tier")
    func unknownAwardKind() {
        #expect(AwardTier(highestAwardKind: nil) == nil)
        #expect(AwardTier(highestAwardKind: "") == nil)
        #expect(AwardTier(highestAwardKind: "platinum") == nil)
    }

    // MARK: - AwardType + AwardDataExtra (GetUserAwards)

    private func award(type: String, extra: Int, consoleID: Int? = 2) -> VisibleUserAward {
        VisibleUserAward(
            awardedAt: "2023-05-21T13:16:27+00:00",
            awardType: type,
            id: consoleID == nil ? nil : 11278,
            awardDataExtra: extra,
            displayOrder: 0,
            title: "Game",
            consoleID: consoleID,
            consoleName: consoleID == nil ? nil : "Nintendo 64",
            flags: nil,
            imageIcon: "/Images/047942.png"
        )
    }

    @Test("Mastery with the hardcore flag is mastered; without it, completed")
    func masteryVsCompletion() {
        #expect(AwardTier(award: award(type: "Mastery/Completion", extra: 1)) == .mastered)
        #expect(AwardTier(award: award(type: "Mastery/Completion", extra: 0)) == .completed)
    }

    @Test("Game Beaten splits on the same hardcore flag")
    func beatenSplit() {
        #expect(AwardTier(award: award(type: "Game Beaten", extra: 1)) == .beatenHardcore)
        #expect(AwardTier(award: award(type: "Game Beaten", extra: 0)) == .beatenSoftcore)
    }

    @Test("An award with no console is a site award regardless of its type")
    func siteAward() {
        #expect(AwardTier(award: award(type: "Mastery/Completion", extra: 1, consoleID: nil)) == .site)
        #expect(AwardTier(award: award(type: "Some Site Milestone", extra: 0, consoleID: nil)) == .site)
    }

    // MARK: - Semantics

    @Test("Only mastered and beaten-hardcore count as hardcore")
    func hardcoreFlags() {
        #expect(AwardTier.mastered.isHardcore)
        #expect(AwardTier.beatenHardcore.isHardcore)
        #expect(AwardTier.completed.isHardcore == false)
        #expect(AwardTier.beatenSoftcore.isHardcore == false)
        #expect(AwardTier.site.isHardcore == false)
    }

    @Test("Site awards survive the hardcore filter; softcore game awards do not")
    func hardcoreFilterSurvival() {
        #expect(AwardTier.mastered.survivesHardcoreFilter)
        #expect(AwardTier.beatenHardcore.survivesHardcoreFilter)
        #expect(AwardTier.site.survivesHardcoreFilter)
        #expect(AwardTier.completed.survivesHardcoreFilter == false)
        #expect(AwardTier.beatenSoftcore.survivesHardcoreFilter == false)
    }

    @Test("Rarity orders mastered highest and softcore lowest of the game tiers")
    func rarityOrdering() {
        #expect(AwardTier.mastered > AwardTier.completed)
        #expect(AwardTier.completed > AwardTier.beatenHardcore)
        #expect(AwardTier.beatenHardcore > AwardTier.beatenSoftcore)
        #expect(AwardTier.beatenSoftcore > AwardTier.site)

        #expect(AwardTier.allCases.max() == .mastered)
    }

    @Test("Every tier has a display name")
    func displayNames() {
        for tier in AwardTier.allCases {
            #expect(tier.displayName.isEmpty == false)
            #expect(tier.longDisplayName.isEmpty == false)
        }
    }

    @Test("Every tier has a distinct rarity material")
    func materialsDiffer() {
        let inks = AwardTier.allCases.map { RarityMaterial.of($0).ink }
        #expect(Set(inks.map(String.init(describing:))).count == AwardTier.allCases.count)

        // Only the top two tiers are foiled; the ladder needs a floor.
        #expect(RarityMaterial.of(.mastered).isFoil)
        #expect(RarityMaterial.of(.completed).isFoil)
        #expect(RarityMaterial.of(.beatenHardcore).isFoil == false)
        #expect(RarityMaterial.of(.beatenSoftcore).isFoil == false)
        #expect(RarityMaterial.of(.site).isFoil == false)
    }
}
