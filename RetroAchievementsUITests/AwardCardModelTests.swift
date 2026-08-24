//
//  AwardCardModelTests.swift
//  RetroAchievementsUITests
//
//  The join between GetUserAwards and GetUserCompletionProgress that replaced
//  the per-award N+1 fetch.
//

import Foundation
import Testing
@testable import RetroAchievementsUI

@Suite("AwardCardModel")
struct AwardCardModelTests {

    private func awards(_ data: Data) throws -> [VisibleUserAward] {
        try JSONDecoder().decode(Awards.self, from: data).visibleUserAwards
    }

    private func progress() throws -> [Int: GameCompletionProgress] {
        let result = try JSONDecoder().decode(UserGamesCompletionProgressResult.self,
                                              from: Fixtures.completionProgress)
        return Dictionary(uniqueKeysWithValues: result.results.map { ($0.id, $0) })
    }

    // MARK: - Joining

    @Test("Cards take art and counts from the matching completion-progress entry")
    func joinsProgress() throws {
        let cards = AwardCardModel.build(awards: try awards(Fixtures.userAwards),
                                         progress: try progress(),
                                         hardcoreMode: false)

        let mario = try #require(cards.first { $0.gameID == 11278 })
        #expect(mario.title == "Super Mario 64")
        #expect(mario.consoleName == "Nintendo 64")
        #expect(mario.maxPossible == 114)
        #expect(mario.numAwardedHardcore == 114)
        #expect(mario.tier == .mastered)
    }

    @Test("An award with no completion-progress entry still renders")
    func unmatchedAwardStillRenders() throws {
        let cards = AwardCardModel.build(awards: try awards(Fixtures.userAwards),
                                         progress: [:],
                                         hardcoreMode: false)

        // Falls back to the award's own Title/ImageIcon rather than vanishing.
        let mario = try #require(cards.first { $0.gameID == 11278 })
        #expect(mario.title == "Super Mario 64")
        #expect(mario.iconPath == "/Images/047942.png")
        #expect(mario.maxPossible == 0)
    }

    @Test("A site award with no title falls back rather than crashing")
    func siteAwardFallback() throws {
        let cards = AwardCardModel.build(awards: try awards(Fixtures.userAwardsSiteOnly),
                                         progress: [:],
                                         hardcoreMode: false)

        #expect(cards.count == 3)
        #expect(cards.allSatisfy { $0.tier == .site })
        #expect(cards.allSatisfy { $0.gameID == nil })
        #expect(cards.allSatisfy { $0.isSiteAward })
    }

    // MARK: - Identity

    @Test("Card ids are unique when one game holds several awards")
    func idsUniqueForDuplicateGame() throws {
        let cards = AwardCardModel.build(awards: try awards(Fixtures.userAwardsDuplicateGame),
                                         progress: try progress(),
                                         hardcoreMode: false)

        #expect(Set(cards.map(\.id)).count == cards.count)
    }

    @Test("Card ids are unique across site awards, which share a nil game id")
    func idsUniqueForSiteAwards() throws {
        let cards = AwardCardModel.build(awards: try awards(Fixtures.userAwardsSiteOnly),
                                         progress: [:],
                                         hardcoreMode: false)

        #expect(Set(cards.map(\.id)).count == 3)
    }

    // MARK: - Hardcore filtering

    @Test("Hardcore mode drops softcore game awards and keeps hardcore ones")
    func hardcoreFilter() throws {
        let all = AwardCardModel.build(awards: try awards(Fixtures.userAwardsMixedHardcore),
                                       progress: [:],
                                       hardcoreMode: false)
        let hardcore = AwardCardModel.build(awards: try awards(Fixtures.userAwardsMixedHardcore),
                                            progress: [:],
                                            hardcoreMode: true)

        #expect(all.count == 2)
        #expect(hardcore.count == 1)
        #expect(hardcore.first?.tier == .mastered)
    }

    // MARK: - Derived values

    @Test("Earned count follows the hardcore toggle")
    func earnedFollowsToggle() {
        let card = AwardCardModel(
            id: "x", gameID: 1, tier: .mastered, title: "T", consoleName: "C",
            awardedAt: nil, iconPath: nil,
            numAwarded: 50, numAwardedHardcore: 30, maxPossible: 100
        )

        #expect(card.earned(hardcoreMode: true) == 30)
        #expect(card.earned(hardcoreMode: false) == 50)
        #expect(card.completionFraction(hardcoreMode: true) == 0.3)
        #expect(card.completionFraction(hardcoreMode: false) == 0.5)
    }

    @Test("A game with no achievements does not divide by zero")
    func zeroAchievements() {
        let card = AwardCardModel(
            id: "x", gameID: 1, tier: .site, title: "T", consoleName: nil,
            awardedAt: nil, iconPath: nil,
            numAwarded: 0, numAwardedHardcore: 0, maxPossible: 0
        )

        #expect(card.completionFraction(hardcoreMode: true) == 0)
    }

    // MARK: - Dates

    @Test("Parses the ISO8601-with-offset format GetUserAwards returns")
    func parsesAwardDate() throws {
        let date = try #require(AwardCardModel.parseAwardDate("2023-05-21T13:16:27+00:00"))

        let components = Calendar(identifier: .gregorian)
            .dateComponents(in: TimeZone(identifier: "UTC")!, from: date)
        #expect(components.year == 2023)
        #expect(components.month == 5)
        #expect(components.day == 21)
    }

    @Test("An unparseable award date yields no date rather than a wrong one")
    func rejectsBadDate() {
        #expect(AwardCardModel.parseAwardDate("not a date") == nil)
        // The other RA date format ("yyyy-MM-dd HH:mm:ss") is deliberately not
        // accepted here — GetUserAwards does not use it.
        #expect(AwardCardModel.parseAwardDate("2023-05-21 13:16:27") == nil)
    }

    @Test("Awarded year is derived from the parsed date")
    func awardedYear() throws {
        let cards = AwardCardModel.build(awards: try awards(Fixtures.userAwards),
                                         progress: try progress(),
                                         hardcoreMode: false)
        let mario = try #require(cards.first { $0.gameID == 11278 })

        #expect(mario.awardedYear == "2023")
        #expect(mario.awardedDateText != nil)
    }
}
