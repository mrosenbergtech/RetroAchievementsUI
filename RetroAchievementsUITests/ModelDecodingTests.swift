//
//  ModelDecodingTests.swift
//  RetroAchievementsUITests
//
//  Every API model decodes from a representative payload, and survives the
//  nulls the real API actually sends.
//

import Foundation
import Testing
@testable import RetroAchievementsUI

@Suite("Model decoding")
struct ModelDecodingTests {

    private let decoder = JSONDecoder()

    // MARK: - Awards

    @Test("Awards decodes counts and visible awards")
    func awardsDecodes() throws {
        let awards = try decoder.decode(Awards.self, from: Fixtures.userAwards)

        #expect(awards.totalAwardsCount == 3)
        #expect(awards.masteryAwardsCount == 1)
        #expect(awards.siteAwardsCount == 1)
        #expect(awards.visibleUserAwards.count == 3)
    }

    @Test("Game award carries its game ID, console and hardcore flag")
    func gameAwardFields() throws {
        let awards = try decoder.decode(Awards.self, from: Fixtures.userAwards)
        let mastery = try #require(awards.visibleUserAwards.first)

        #expect(mastery.id == 11278)
        #expect(mastery.awardType == "Mastery/Completion")
        #expect(mastery.awardDataExtra == 1)
        #expect(mastery.consoleID == 2)
        #expect(mastery.consoleName == "Nintendo 64")
        #expect(mastery.imageIcon == "/Images/047942.png")
    }

    @Test("Site award decodes with null AwardData, ConsoleID, Title and ImageIcon")
    func siteAwardNulls() throws {
        let awards = try decoder.decode(Awards.self, from: Fixtures.userAwards)
        let site = try #require(awards.visibleUserAwards.last)

        #expect(site.id == nil)
        #expect(site.consoleID == nil)
        #expect(site.consoleName == nil)
        #expect(site.title == nil)
        #expect(site.imageIcon == nil)
        #expect(site.awardType == "Achievement Unlocks Yield 1000 Points")
    }

    @Test("awardIdentity is unique across awards sharing a game ID")
    func awardIdentityUnique() throws {
        let awards = try decoder.decode(Awards.self, from: Fixtures.userAwardsDuplicateGame)
        let identities = Set(awards.visibleUserAwards.map(\.awardIdentity))

        // Both awards are for game 11278, so `id` alone would collide.
        #expect(awards.visibleUserAwards.count == 2)
        #expect(identities.count == 2)
    }

    @Test("awardIdentity is unique across site awards, which all have nil id")
    func siteAwardIdentityUnique() throws {
        let awards = try decoder.decode(Awards.self, from: Fixtures.userAwardsSiteOnly)
        let identities = Set(awards.visibleUserAwards.map(\.awardIdentity))

        #expect(identities.count == 3)
    }

    // MARK: - Profile

    @Test("Profile decodes")
    func profileDecodes() throws {
        let profile = try decoder.decode(Profile.self, from: Fixtures.userProfile)

        #expect(profile.user == "mrosen97")
        #expect(profile.totalPoints == 2247)
        #expect(profile.totalSoftcorePoints == 130)
        #expect(profile.lastGameID == 11278)
        #expect(profile.richPresenceMsg == "Playing Super Mario 64")
    }

    // MARK: - Completion progress

    @Test("Completion progress decodes results and award kinds")
    func completionProgressDecodes() throws {
        let result = try decoder.decode(UserGamesCompletionProgressResult.self,
                                        from: Fixtures.completionProgress)

        #expect(result.count == 2)
        #expect(result.results.count == 2)

        let mario = try #require(result.results.first)
        #expect(mario.id == 11278)
        #expect(mario.maxPossible == 114)
        #expect(mario.numAwardedHardcore == 114)
        #expect(mario.highestAwardKind == "mastered")
    }

    @Test("Completion progress tolerates null HighestAwardKind for in-progress games")
    func completionProgressNullAward() throws {
        let result = try decoder.decode(UserGamesCompletionProgressResult.self,
                                        from: Fixtures.completionProgressNullAward)
        let game = try #require(result.results.first)

        #expect(game.highestAwardKind == nil)
        #expect(game.highestAwardDate == nil)
        #expect(game.numAwarded == 3)
    }

    // MARK: - Game summary

    @Test("GameSummary decodes, including achievements as a keyed dictionary")
    func gameSummaryDecodes() throws {
        let summary = try decoder.decode(GameSummary.self, from: Fixtures.gameInfoAndUserProgress)

        #expect(summary.id == 11278)
        #expect(summary.title == "Super Mario 64")
        #expect(summary.numAchievements == 114)
        #expect(summary.highestAwardKind == "mastered")

        // Achievements arrive keyed by stringified achievement ID, not as an array.
        #expect(summary.achievements.count == 1)
        let achievement = try #require(summary.achievements["12345"])
        #expect(achievement.id == 12345)
        #expect(achievement.title == "Bob-omb Battlefield")
        // Verified against the live API: the key is "Type", capitalised.
        #expect(achievement.type == "progression")
    }

    @Test("GameSummary decodes an event game with a null release date")
    func eventGameDecodes() throws {
        // Regression: `released` was a non-optional String, so every event game
        // — which have no release date — failed to decode. Because the rarity
        // prefetch pulls summaries for recent-achievement games, and event
        // games appear there constantly, this surfaced as a permanent
        // "Unexpected Response" banner on the profile that retry could not clear.
        let summary = try decoder.decode(GameSummary.self, from: Fixtures.gameInfoEventGame)

        #expect(summary.released == nil)
        #expect(summary.developer == nil)
        #expect(summary.genre == nil)
        #expect(summary.parentGameID == nil)
        #expect(summary.title == "Achievement of the Week 2018 - Evergreen")
        #expect(summary.achievements.count == 1)
    }

    /// The cards render the square icon, not box art — but the API still sends
    /// these, and the game sheet's backdrop uses `imageTitle`.
    @Test("GameSummary decodes all four artwork paths")
    func gameSummaryBoxArt() throws {
        let summary = try decoder.decode(GameSummary.self, from: Fixtures.gameInfoAndUserProgress)

        #expect(summary.imageBoxArt == "/Images/047945.png")
        #expect(summary.imageTitle == "/Images/047943.png")
        #expect(summary.imageIngame == "/Images/047944.png")
    }

    // MARK: - Remaining models

    @Test("Console list decodes")
    func consolesDecode() throws {
        let consoles = try decoder.decode([Console].self, from: Fixtures.consoleIDs)

        #expect(consoles.count == 3)
        #expect(consoles.first?.name == "Nintendo 64")
    }

    @Test("Game list decodes")
    func gameListDecodes() throws {
        let games = try decoder.decode([GameListGame].self, from: Fixtures.gameList)

        #expect(games.count == 1)
        #expect(games.first?.id == 11278)
        #expect(games.first?.points == 900)
    }

    @Test("Recently played games decode")
    func recentGamesDecode() throws {
        let games = try decoder.decode([RecentGame].self, from: Fixtures.recentlyPlayed)

        #expect(games.count == 1)
        #expect(games.first?.title == "Super Mario 64")
        #expect(games.first?.lastPlayed == "2024-01-02 08:00:00")
    }

    @Test("Recent achievements decode")
    func recentAchievementsDecode() throws {
        let achievements = try decoder.decode([RecentAchievement].self,
                                              from: Fixtures.recentAchievements)

        #expect(achievements.count == 1)
        #expect(achievements.first?.hardcoreMode == 1)
        #expect(achievements.first?.gameID == 11278)
    }

    @Test("Empty arrays decode to empty collections")
    func emptyArrays() throws {
        #expect(try decoder.decode([GameListGame].self, from: Fixtures.emptyArray).isEmpty)
        #expect(try decoder.decode([Console].self, from: Fixtures.emptyArray).isEmpty)
        #expect(try decoder.decode([RecentGame].self, from: Fixtures.emptyArray).isEmpty)
    }

    @Test("Malformed JSON throws rather than producing a partial model")
    func malformedThrows() {
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(Awards.self, from: Fixtures.malformed)
        }
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(Profile.self, from: Fixtures.malformed)
        }
    }
}
