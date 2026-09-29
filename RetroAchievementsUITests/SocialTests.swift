//
//  SocialTests.swift
//  RetroAchievementsUITests
//
//  Friends, other users' profiles, Achievement of the Week, and playtime —
//  the decoding and the rules around it. Network-backed behaviour lives in
//  NetworkTests, which owns the one serialized suite allowed to drive
//  MockURLProtocol.
//

import Foundation
import Testing
@testable import RetroAchievementsUI

@Suite("Followed users")
struct FollowedUserTests {

    private func decoded() throws -> FollowedUsersResult {
        try JSONDecoder().decode(FollowedUsersResult.self, from: Fixtures.usersIFollow)
    }

    @Test("Decodes the GetUsersIFollow payload")
    func decodes() throws {
        let result = try decoded()

        #expect(result.count == 3)
        #expect(result.total == 3)
        #expect(result.results.map(\.user) == ["zuliman92", "Pawlie_", "David_io"])
        #expect(result.results[0].points == 1882)
        #expect(result.results[0].isFollowingMe == true)
        #expect(result.results[1].isFollowingMe == false)
    }

    @Test("Rows identify by username, which every other endpoint keys on")
    func identifiesByUsername() throws {
        let results = try decoded().results
        #expect(results.map(\.id) == results.map(\.user))
        #expect(Set(results.map(\.id)).count == results.count)
    }

    @Test("Points follow the hardcore/softcore switch")
    func pointsFollowMode() throws {
        // David_io has more softcore points than hardcore — the row must not
        // show the hardcore figure while the app is in softcore mode.
        let david = try #require(try decoded().results.first { $0.user == "David_io" })

        #expect(david.points(hardcoreMode: true) == 640)
        #expect(david.points(hardcoreMode: false) == 1120)
    }

    @Test("A missing ULID does not stop a row decoding")
    func toleratesMissingULID() throws {
        let json = Data(#"[{"User":"a","Points":1,"PointsSoftcore":0}]"#.utf8)
        let users = try JSONDecoder().decode([FollowedUser].self, from: json)

        #expect(users.first?.ulid == nil)
        #expect(users.first?.isFollowingMe == nil)
        #expect(users.first?.id == "a")
    }
}

@Suite("Achievement of the Week")
struct AchievementOfTheWeekTests {

    private func decoded() throws -> AchievementOfTheWeek {
        try JSONDecoder().decode(AchievementOfTheWeek.self, from: Fixtures.achievementOfTheWeek)
    }

    @Test("Decodes the nested payload")
    func decodes() throws {
        let featured = try decoded()

        #expect(featured.achievement.id == 178634)
        #expect(featured.achievement.title == "Saved Summer")
        #expect(featured.achievement.points == 10)
        #expect(featured.game.id == 2865)
        #expect(featured.console.title == "SNES")
        #expect(featured.unlocksCount == 280)
        #expect(featured.unlocks?.count == 2)
    }

    @Test("Parses the start date")
    func parsesStartDate() throws {
        let date = try #require(try decoded().startDate)
        let parts = Calendar(identifier: .gregorian)
            .dateComponents(in: TimeZone(identifier: "UTC")!, from: date)

        #expect(parts.year == 2023)
        #expect(parts.month == 10)
        #expect(parts.day == 23)
    }

    @Test("Recognises an unlock by the signed-in user, whatever the casing")
    func findsUnlock() throws {
        let featured = try decoded()

        #expect(featured.isUnlocked(by: "Agnam", hardcoreMode: true))
        // Usernames are case-insensitive on the site and arrive cased however
        // the endpoint that named them felt like.
        #expect(featured.isUnlocked(by: "agnam", hardcoreMode: true))
        #expect(!featured.isUnlocked(by: "someone else", hardcoreMode: true))
    }

    @Test("A softcore unlock does not count as unlocked in hardcore mode")
    func respectsHardcoreMode() throws {
        let featured = try decoded()

        #expect(featured.isUnlocked(by: "softcoreSam", hardcoreMode: false))
        #expect(!featured.isUnlocked(by: "softcoreSam", hardcoreMode: true))
    }

    @Test("No unlock list means not unlocked rather than a crash")
    func toleratesMissingUnlocks() throws {
        let json = Data("""
        { "Achievement": { "ID": 1, "Title": "t", "Points": 5 },
          "Console": { "ID": 1, "Title": "c" },
          "Game": { "ID": 2, "Title": "g" } }
        """.utf8)
        let featured = try JSONDecoder().decode(AchievementOfTheWeek.self, from: json)

        #expect(featured.unlocks == nil)
        #expect(featured.startDate == nil)
        #expect(!featured.isUnlocked(by: "anyone", hardcoreMode: true))
    }
}

@Suite("Playtime")
struct PlaytimeTests {

    @Test("Decodes UserTotalPlaytime from the game payload, in seconds")
    func decodesPlaytime() throws {
        let summary = try JSONDecoder().decode(
            GameSummary.self, from: Fixtures.gameInfoAndUserProgress)

        // 195 seconds, not 195 minutes. Reading this field as minutes shipped
        // in 5.0.0 and multiplied every figure by 60 — issue #8.
        #expect(summary.userTotalPlaytime == 195)
        #expect(summary.playtimeDescription == "3m")
    }

    @Test("A payload without the field decodes rather than failing")
    func toleratesMissingPlaytime() throws {
        // The field postdates parts of the API's own documentation, so a
        // response without it has to remain readable.
        let summary = try JSONDecoder().decode(
            GameSummary.self, from: Fixtures.gameInfoEventGame)

        #expect(summary.userTotalPlaytime == nil)
        #expect(summary.playtimeDescription == nil)
    }

    @Test("Reads as a human would say it")
    func formatsPlaytime() {
        #expect(GameSummary.playtimeDescription(seconds: 45 * 60) == "45m")
        #expect(GameSummary.playtimeDescription(seconds: 3_600) == "1h")
        #expect(GameSummary.playtimeDescription(seconds: 11_700) == "3h 15m")
        #expect(GameSummary.playtimeDescription(seconds: 90_000) == "25h")
    }

    @Test("The reported case: 36 minutes reads as 36 minutes, not 36 hours")
    func rendersTheReportedCase() {
        // Issue #8, opened the day after 5.0.0 shipped: "I've played Pokemon
        // blue for 36 minutes, on the app it registers as 36 hours."
        #expect(GameSummary.playtimeDescription(seconds: 36 * 60) == "36m")
    }

    @Test("A real payload lands in a plausible range")
    func realValueIsPlausible() {
        // Super Mario 64 returns 98232 for an account with 59/114 unlocked.
        // 27h is a person playing a game; 1637h is nine weeks of continuous
        // play and was what the app printed.
        #expect(GameSummary.playtimeDescription(seconds: 98_232) == "27h 17m")
    }

    @Test("Under a minute still reads as time played")
    func showsSubMinutePlaytime() {
        // "0m" reads as never played, which is a different fact.
        #expect(GameSummary.playtimeDescription(seconds: 30) == "<1m")
        #expect(GameSummary.playtimeDescription(seconds: 59) == "<1m")
        #expect(GameSummary.playtimeDescription(seconds: 60) == "1m")
    }

    @Test("Nothing played reads as nothing at all, not as zero")
    func omitsEmptyPlaytime() {
        // "0m" on a game the player has never opened looks like a measurement.
        #expect(GameSummary.playtimeDescription(seconds: 0) == nil)
        #expect(GameSummary.playtimeDescription(seconds: nil) == nil)
        #expect(GameSummary.playtimeDescription(seconds: -5) == nil)
    }
}

@Suite("Pinned users")
struct PinnedUsersTests {

    @MainActor
    private func makeNetwork() -> (Network, GameListStore) {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ra-pins-\(UUID().uuidString)", isDirectory: true)
        let defaults = UserDefaults(suiteName: "ra-pins-\(UUID().uuidString)")!
        let store = GameListStore(directory: dir, defaults: defaults)
        return (Network(session: MockURLProtocol.makeSession(), store: store), store)
    }

    @Test("Pins round-trip through the store")
    @MainActor
    func pinsPersist() {
        let (network, store) = makeNetwork()

        #expect(network.pinUser("Pawlie_"))
        #expect(network.pinUser("David_io"))
        #expect(network.pinnedUsernames == ["Pawlie_", "David_io"])

        // A fresh Network over the same store sees them.
        let reopened = Network(session: MockURLProtocol.makeSession(), store: store)
        reopened.loadPinnedUsernames()
        #expect(reopened.pinnedUsernames == ["Pawlie_", "David_io"])
    }

    @Test("Pinning the same user twice is refused rather than duplicated")
    @MainActor
    func rejectsDuplicates() {
        let (network, _) = makeNetwork()

        #expect(network.pinUser("Pawlie_"))
        #expect(!network.pinUser("Pawlie_"))
        // Usernames are case-insensitive on the site.
        #expect(!network.pinUser("pawlie_"))
        #expect(network.pinnedUsernames.count == 1)
    }

    @Test("Unpinning is case-insensitive too")
    @MainActor
    func unpinsRegardlessOfCase() {
        let (network, _) = makeNetwork()
        _ = network.pinUser("Pawlie_")

        network.unpinUser("PAWLIE_")
        #expect(network.pinnedUsernames.isEmpty)
        #expect(!network.isPinned("Pawlie_"))
    }

    @Test("Empty and whitespace names are refused")
    @MainActor
    func rejectsEmptyNames() {
        let (network, _) = makeNetwork()

        #expect(!network.pinUser(""))
        #expect(!network.pinUser("   "))
        #expect(network.pinnedUsernames.isEmpty)
    }

    @Test("Pins survive a cache clear")
    @MainActor
    func survivesCacheClear() {
        // "Refresh Game List" calls clearAll(); the reader's own list is not a
        // cache and must not go with it.
        let (network, store) = makeNetwork()
        _ = network.pinUser("Pawlie_")

        store.clearAll()

        let reopened = Network(session: MockURLProtocol.makeSession(), store: store)
        reopened.loadPinnedUsernames()
        #expect(reopened.pinnedUsernames == ["Pawlie_"])
    }

    @Test("Usernames key case-insensitively")
    func userKeyIsCaseInsensitive() {
        #expect(Network.userKey("Pawlie_") == Network.userKey("pawlie_"))
        #expect(Network.userKey("David_io") == "david_io")
    }
}

@Suite("Set claims feed")
struct SetClaimTests {

    private func completed() throws -> [SetClaim] {
        try JSONDecoder().decode([SetClaim].self, from: Fixtures.completedClaims)
    }

    private func active() throws -> [SetClaim] {
        try JSONDecoder().decode([SetClaim].self, from: Fixtures.activeClaims)
    }

    @Test("Decodes the claims payload")
    func decodes() throws {
        let claims = try completed()

        #expect(claims.count == 3)
        #expect(claims[0].gameTitle == "~Homebrew~ No Place To Hide")
        #expect(claims[0].user == "WanderingHeiho")
        #expect(claims[0].consoleName == "Nintendo DS")
    }

    @Test("SetType 0 is a new set and 1 is a revision")
    func mapsSetType() throws {
        // Values taken from RetroAchievements' own ClaimSetType enum, not
        // inferred from samples — getting these backwards would mislabel
        // every row in the feed.
        let claims = try completed()

        #expect(claims[0].kind == .newSet)
        #expect(claims[0].kind.label == "NEW SET")
        #expect(claims[1].kind == .revision)
        #expect(claims[1].kind.label == "REVISION")
        #expect(claims[1].isRevision)
    }

    @Test("An unrecognised SetType still shows, as a new set")
    func toleratesUnknownSetType() throws {
        let json = Data(#"""
        [{ "ID": 1, "User": "u", "GameID": 2, "GameTitle": "g",
           "ConsoleName": "c", "SetType": 99, "Status": 1 }]
        """#.utf8)
        let claims = try JSONDecoder().decode([SetClaim].self, from: json)

        #expect(claims.first?.kind == .newSet)
        #expect(claims.first?.gameIcon == nil)
    }

    @Test("A completed claim is dated by when it finished")
    func datesCompletedByDoneTime() throws {
        let claim = try #require(try completed().first { $0.id == 11300 })
        let parts = Calendar(identifier: .gregorian).dateComponents(
            in: TimeZone(identifier: "UTC")!, from: try #require(claim.newsDate))

        // DoneTime 2024-03-02, not Created 2024-02-01.
        #expect(parts.year == 2024)
        #expect(parts.month == 3)
        #expect(parts.day == 2)
    }

    @Test("An active claim is dated by when it was made, not when it expires")
    func datesActiveByCreated() throws {
        // DoneTime on an active claim is an expiry date in the future —
        // dating the row by it would put unstarted work at the top of a feed
        // sorted newest first.
        let claim = try #require(try active().first)
        let parts = Calendar(identifier: .gregorian).dateComponents(
            in: TimeZone(identifier: "UTC")!, from: try #require(claim.newsDate))

        #expect(claim.claimStatus == .active)
        #expect(parts.year == 2026)
        #expect(parts.month == 9)
        #expect(parts.day == 1)
    }

    @Test("The feed shows one row per game, preferring the primary claim")
    func deduplicatesByGame() throws {
        // Super Mario 64 is claimed twice — primary and collaboration. Two
        // rows for one set looks like a bug.
        let feed = try completed().asFeed()

        #expect(feed.count == 2)
        let mario = try #require(feed.first { $0.gameID == 11278 })
        #expect(mario.user == "SporyTike")
        #expect(!mario.isCollaboration)
    }

    @Test("The feed runs newest first")
    func sortsNewestFirst() throws {
        let feed = try completed().asFeed()
        let dates = feed.compactMap(\.newsDate)

        #expect(dates == dates.sorted(by: >))
        #expect(feed.first?.gameID == 11278)   // completed 2024-03, vs 2024-01
    }

    @Test("The feed is capped")
    func capsTheFeed() throws {
        let feed = try completed().asFeed(limit: 1)
        #expect(feed.count == 1)
    }

    @Test("Claims with no usable date sort last rather than dropping out")
    func undatedClaimsSortLast() throws {
        let json = Data(#"""
        [{ "ID": 1, "User": "u", "GameID": 1, "GameTitle": "undated",
           "ConsoleName": "c", "SetType": 0, "Status": 1 },
         { "ID": 2, "User": "u", "GameID": 2, "GameTitle": "dated",
           "ConsoleName": "c", "SetType": 0, "Status": 1,
           "DoneTime": "2024-03-02 10:00:00" }]
        """#.utf8)
        let feed = try JSONDecoder().decode([SetClaim].self, from: json).asFeed()

        #expect(feed.count == 2)
        #expect(feed.first?.gameTitle == "dated")
        #expect(feed.last?.gameTitle == "undated")
    }
}

@Suite("Achievement of the Week presentation")
struct AchievementOfTheWeekPresentationTests {

    /// The card pairs the AOTW payload with the parent game's summary: the
    /// payload has the description, the summary has the badge.
    @Test("The description comes straight from the AOTW payload")
    func descriptionIsInThePayload() throws {
        let featured = try JSONDecoder().decode(
            AchievementOfTheWeek.self, from: Fixtures.achievementOfTheWeek)

        #expect(featured.achievement.description == "Defeat the Flower and let Summer Get Busy")
    }

    @Test("The badge comes from the parent game's achievement, keyed by ID")
    func badgeComesFromTheGameSummary() throws {
        // The AOTW payload has no BadgeName, so the card looks the achievement
        // up in the game summary by its stringified ID — the same keying the
        // rest of the app uses for that dictionary.
        let summary = try JSONDecoder().decode(
            GameSummary.self, from: Fixtures.gameInfoAndUserProgress)
        let achievement = try #require(summary.achievements["12345"])

        #expect(!achievement.badgeName.isEmpty)
        #expect(RAImageURL.badge(achievement.badgeName, locked: false) != nil)
        // Locked art is a different URL, so an unearned AOTW does not show as
        // earned.
        #expect(RAImageURL.badge(achievement.badgeName, locked: true)
                != RAImageURL.badge(achievement.badgeName, locked: false))
    }

    @Test("A game the summary has not reached yet yields no badge rather than a wrong one")
    func missingSummaryYieldsNoBadge() throws {
        let summary = try JSONDecoder().decode(
            GameSummary.self, from: Fixtures.gameInfoAndUserProgress)

        #expect(summary.achievements["999999"] == nil)
    }
}

@Suite("Another user's game progress")
struct UserGameProgressTests {

    @Test("A summary's achievements carry the unlock dates of whoever was asked for")
    func summaryCarriesUnlockDates() throws {
        // The whole point of fetching with &u=<them>: the achievements come
        // back with that user's unlock state, which is what the visitor's page
        // renders. This asserts the dates survive decoding at all — that they
        // are *their* dates is the network test below, which checks the
        // username actually reaches the URL and the result lands in the
        // per-user cache rather than the signed-in user's.
        let summary = try JSONDecoder().decode(
            GameSummary.self, from: Fixtures.gameInfoAndUserProgress)
        let achievement = try #require(summary.achievements["12345"])

        #expect(achievement.dateEarned == "2023-05-01 10:00:00")
        #expect(achievement.dateEarnedHardcore == "2023-05-01 10:00:00")
    }

    @Test("A route identifies a game, and a game opened at one achievement")
    func routeIdentity() {
        let game = UserGameRoute(gameID: 11278)
        let achievement = UserGameRoute(gameID: 11278, achievementID: 12345)

        // Distinct ids, so pushing the same game at a different achievement
        // is a different destination rather than a no-op.
        #expect(game.id != achievement.id)
        #expect(UserGameRoute(gameID: 11278).id == game.id)
    }
}
