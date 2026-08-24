//
//  NetworkTests.swift
//  RetroAchievementsUITests
//
//  Exercises the API layer through MockURLProtocol. No test here touches the
//  network — Network is constructed with an injected ephemeral session.
//

import Foundation
import Testing
@testable import RetroAchievementsUI

@MainActor
@Suite("Network", .serialized)
struct NetworkTests {

    /// A Network wired to the mock transport and a throwaway on-disk store.
    private func makeSubject(retryBaseDelay: TimeInterval = 0.001) -> Network {
        MockURLProtocol.reset()
        let store = GameListStore(
            directory: FileManager.default.temporaryDirectory
                .appendingPathComponent("ra-tests-\(UUID().uuidString)", isDirectory: true),
            defaults: UserDefaults(suiteName: "ra-tests-\(UUID().uuidString)")!
        )
        return Network(session: MockURLProtocol.makeSession(),
                       store: store,
                       retryBaseDelay: retryBaseDelay)
    }

    /// Routes covering every endpoint fetchAllProfileData touches.
    private var fullRoutes: [String: Data] {
        [
            "API_GetUserProfile":            Fixtures.userProfile,
            "API_GetUserAwards":             Fixtures.userAwards,
            "API_GetUserRecentAchievements": Fixtures.recentAchievements,
            "API_GetUserCompletionProgress": Fixtures.completionProgress,
            "API_GetUserRecentlyPlayedGames": Fixtures.recentlyPlayed,
            "API_GetConsoleIDs":             Fixtures.consoleIDs,
            "API_GetGameList":               Fixtures.gameList,
            "API_GetGameInfoAndUserProgress": Fixtures.gameInfoAndUserProgress,
        ]
    }

    // MARK: - Auth

    @Test("Authentication string is the documented z/y query pair")
    func authString() {
        let subject = makeSubject()
        #expect(subject.buildAuthenticationString(username: "bob", key: "secret")
                == "z=bob&y=secret")
    }

    @Test("Successful auth publishes the username and authenticated flag")
    func authSucceeds() async {
        let subject = makeSubject()
        MockURLProtocol.route(fullRoutes)

        await subject.authenticateCredentials(webAPIUsername: "mrosen97", webAPIKey: "key")
        await subject.awaitGameListSyncForTesting()
        await subject.awaitRarityPrefetchForTesting()

        #expect(subject.webAPIAuthenticated)
        #expect(subject.initialWebAPIAuthenticationCheckComplete)
        #expect(subject.authenticatedWebAPIUsername == "mrosen97")
    }

    @Test("A rejected key signs the user out and says so")
    func authFails() async {
        let subject = makeSubject()
        MockURLProtocol.respondAlways(with: Data(), status: 401)

        await subject.authenticateCredentials(webAPIUsername: "mrosen97", webAPIKey: "bad")

        #expect(subject.webAPIAuthenticated == false)
        #expect(subject.initialWebAPIAuthenticationCheckComplete)
        #expect(subject.isFetching == false)
        #expect(subject.lastError == .unauthorized)
    }

    @Test("A server outage does not sign a valid user out")
    func authSurvivesOutage() async {
        let subject = makeSubject()
        MockURLProtocol.respondAlways(with: Data(), status: 500)

        await subject.authenticateCredentials(webAPIUsername: "mrosen97", webAPIKey: "key")

        // Losing the connection is not a credential problem. Signing the user
        // out here would dump them at the login sheet every time they lost
        // signal, and they cannot sign back in while offline anyway.
        #expect(subject.webAPIAuthenticated)
        #expect(subject.lastError == .server(500))
        #expect(subject.isFetching == false)
    }

    @Test("An offline device reports being offline, not a bad key")
    func authOffline() async {
        let subject = makeSubject()
        MockURLProtocol.handler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        await subject.authenticateCredentials(webAPIUsername: "mrosen97", webAPIKey: "key")

        #expect(subject.lastError == .offline)
        #expect(subject.lastError?.requiresSignIn == false)
        #expect(subject.webAPIAuthenticated)
    }

    // MARK: - Request shape

    @Test("Each fetcher calls its documented endpoint with the expected parameters")
    func endpointShapes() async {
        let subject = makeSubject()
        MockURLProtocol.route(fullRoutes)
        await subject.authenticateCredentials(webAPIUsername: "mrosen97", webAPIKey: "key")
        await subject.awaitGameListSyncForTesting()
        await subject.awaitRarityPrefetchForTesting()

        let urls = MockURLProtocol.recordedURLs.map(\.absoluteString)

        #expect(urls.contains { $0.contains("API_GetUserProfile.php") })
        #expect(urls.contains { $0.contains("API_GetUserAwards.php") })
        #expect(urls.contains { $0.contains("API_GetUserRecentlyPlayedGames.php") && $0.contains("c=25") })
        #expect(urls.contains { $0.contains("API_GetUserRecentAchievements.php") && $0.contains("m=999999999") })
        #expect(urls.contains { $0.contains("API_GetUserCompletionProgress.php") && $0.contains("c=500") })
        #expect(urls.allSatisfy { $0.contains("z=mrosen97") && $0.contains("y=key") })
    }

    // MARK: - The N+1 guard rail

    @Test("Profile load makes no per-award game requests")
    func noPerAwardFetches() async {
        let subject = makeSubject()
        var routes = fullRoutes
        routes["API_GetUserAwards"] = Fixtures.userAwardsMany(count: 50)
        // No recent achievements, so the rarity prefetch has nothing to do and
        // awards are the only thing that could drive summary fetches.
        routes["API_GetUserRecentAchievements"] = Fixtures.emptyArray
        MockURLProtocol.route(routes)

        await subject.authenticateCredentials(webAPIUsername: "mrosen97", webAPIKey: "key")
        await subject.awaitGameListSyncForTesting()
        await subject.awaitRarityPrefetchForTesting()

        // getAwards() used to await one GetGameInfoAndUserProgress per award,
        // serially, inside the profile load. If that loop ever comes back this
        // jumps from 0 to 50.
        #expect(MockURLProtocol.callCount(containing: "API_GetGameInfoAndUserProgress") == 0)
    }

    @Test("Rarity prefetch stays bounded by games, even with many awards")
    func prefetchDoesNotScaleWithAwards() async {
        let subject = makeSubject()
        var routes = fullRoutes
        routes["API_GetUserAwards"] = Fixtures.userAwardsMany(count: 50)
        routes["API_GetUserRecentAchievements"] = Fixtures.recentAchievementsAcrossGames(
            games: [11278, 3210], perGame: 8)
        MockURLProtocol.route(routes)

        await subject.authenticateCredentials(webAPIUsername: "mrosen97", webAPIKey: "key")
        await subject.awaitGameListSyncForTesting()
        await subject.awaitRarityPrefetchForTesting()

        // 50 awards and 16 recent achievements, but only two distinct games.
        #expect(MockURLProtocol.callCount(containing: "API_GetGameInfoAndUserProgress") == 2)
    }

    @Test("Award cards are built without any extra requests")
    func awardCardsNeedNoRequests() async {
        let subject = makeSubject()
        MockURLProtocol.route(fullRoutes)
        await subject.authenticateCredentials(webAPIUsername: "mrosen97", webAPIKey: "key")
        await subject.awaitGameListSyncForTesting()
        await subject.awaitRarityPrefetchForTesting()

        let before = MockURLProtocol.recordedURLs.count
        let cards = subject.awardCards(hardcoreMode: true)

        #expect(MockURLProtocol.recordedURLs.count == before)
        #expect(cards.isEmpty == false)
    }

    // MARK: - Status codes

    @Test("Non-200, non-429 responses report the status without retrying")
    func serverErrorReturnsStatus() async {
        let subject = makeSubject()
        MockURLProtocol.respondAlways(with: Data(), status: 500)

        let url = URL(string: "https://retroachievements.org/API/API_GetUserProfile.php")!
        let result = await subject.makeAPICall(url: url)

        #expect(result == .failure(.server(500)))
        #expect(MockURLProtocol.callCount(containing: "API_GetUserProfile") == 1)
    }

    @Test("A 401 is reported as a rejected key, not a generic failure")
    func unauthorizedIsDistinct() async {
        let subject = makeSubject()
        MockURLProtocol.respondAlways(with: Data(), status: 403)

        let url = URL(string: "https://retroachievements.org/API/API_GetUserProfile.php")!
        #expect(await subject.makeAPICall(url: url) == .failure(.unauthorized))
    }

    @Test("A 200 carrying the wrong shape is a decoding failure")
    func malformedPayloadIsDecoding() async {
        let subject = makeSubject()
        MockURLProtocol.route(["API_GetUserProfile": Fixtures.malformed])

        await subject.authenticateCredentials(webAPIUsername: "mrosen97", webAPIKey: "key")

        #expect(subject.lastError == .decoding)
        #expect(subject.profile == nil)
    }

    @Test("A 429 is retried with backoff and succeeds once the limit clears")
    func rateLimitRetries() async {
        let subject = makeSubject()
        MockURLProtocol.failFirst(2, status: 429, thenRespondWith: Fixtures.userProfile)

        let url = URL(string: "https://retroachievements.org/API/API_GetUserProfile.php")!
        let result = await subject.makeAPICall(url: url)

        #expect(result.isSuccess)
        // First attempt (429) plus retries until one succeeds.
        #expect(MockURLProtocol.recordedURLs.count == 3)
    }

    @Test("A persistent 429 gives up rather than retrying forever")
    func rateLimitGivesUp() async {
        let subject = makeSubject()
        MockURLProtocol.respondAlways(with: Data(), status: 429)

        let url = URL(string: "https://retroachievements.org/API/API_GetUserProfile.php")!
        let result = await subject.makeAPICall(url: url)

        #expect(result == .failure(.rateLimited))
        // One initial attempt plus a bounded number of retries.
        #expect(MockURLProtocol.recordedURLs.count == 5)
    }

    // MARK: - Award filtering

    @Test("filterHighestAwardType keeps only the mastery when a game has both")
    func collapsesDuplicateGameAwards() async throws {
        let subject = makeSubject()
        let awards = try JSONDecoder().decode(Awards.self, from: Fixtures.userAwardsDuplicateGame)

        let filtered = subject.filterHighestAwardType(awards: awards.visibleUserAwards)

        #expect(filtered.count == 1)
        #expect(filtered.first?.awardType == "Mastery/Completion")
    }

    @Test("filterHighestAwardType preserves every site award")
    func keepsSiteAwards() async throws {
        let subject = makeSubject()
        let awards = try JSONDecoder().decode(Awards.self, from: Fixtures.userAwardsSiteOnly)

        // Site awards all have AwardData == nil. Grouping by that key used to
        // put them in one bucket and delete the lot.
        let filtered = subject.filterHighestAwardType(awards: awards.visibleUserAwards)

        #expect(filtered.count == 3)
    }

    @Test("filterHighestAwardType leaves distinct games untouched")
    func keepsDistinctGames() async throws {
        let subject = makeSubject()
        let awards = try JSONDecoder().decode(Awards.self, from: Fixtures.userAwards)

        let filtered = subject.filterHighestAwardType(awards: awards.visibleUserAwards)

        #expect(filtered.count == 3)
    }

    // MARK: - Hardcore filtering

    @Test("Hardcore mode hides softcore game awards")
    func hardcoreHidesSoftcore() async {
        let subject = makeSubject()
        var routes = fullRoutes
        routes["API_GetUserAwards"] = Fixtures.userAwardsMixedHardcore
        MockURLProtocol.route(routes)
        await subject.authenticateCredentials(webAPIUsername: "mrosen97", webAPIKey: "key")
        await subject.awaitGameListSyncForTesting()
        await subject.awaitRarityPrefetchForTesting()

        let hardcore = subject.awardCards(hardcoreMode: true)
        let all = subject.awardCards(hardcoreMode: false)

        // Locked in deliberately: the app hides softcore awards in hardcore
        // mode rather than dimming them.
        #expect(hardcore.count == 1)
        #expect(hardcore.first?.tier == .mastered)
        #expect(all.count == 2)
    }

    @Test("Hardcore mode still shows site awards")
    func hardcoreKeepsSiteAwards() async {
        let subject = makeSubject()
        var routes = fullRoutes
        routes["API_GetUserAwards"] = Fixtures.userAwardsSiteOnly
        MockURLProtocol.route(routes)
        await subject.authenticateCredentials(webAPIUsername: "mrosen97", webAPIKey: "key")
        await subject.awaitGameListSyncForTesting()
        await subject.awaitRarityPrefetchForTesting()

        #expect(subject.awardCards(hardcoreMode: true).count == 3)
    }

    // MARK: - Orchestration

    @Test("Concurrent profile fetches are coalesced into one set of requests")
    func profileFetchIsDeduplicated() async {
        let subject = makeSubject()
        MockURLProtocol.route(fullRoutes)
        await subject.authenticateCredentials(webAPIUsername: "mrosen97", webAPIKey: "key")
        await subject.awaitGameListSyncForTesting()
        await subject.awaitRarityPrefetchForTesting()

        let baseline = MockURLProtocol.callCount(containing: "API_GetUserProfile")

        async let a: Void = subject.fetchAllProfileData()
        async let b: Void = subject.fetchAllProfileData()
        _ = await (a, b)

        let after = MockURLProtocol.callCount(containing: "API_GetUserProfile")

        // Two concurrent callers share one in-flight task.
        #expect(after - baseline == 1)
        #expect(subject.isFetching == false)
    }

    @Test("Logout clears user state")
    func logoutClears() async {
        let subject = makeSubject()
        MockURLProtocol.route(fullRoutes)
        await subject.authenticateCredentials(webAPIUsername: "mrosen97", webAPIKey: "key")
        await subject.awaitGameListSyncForTesting()
        await subject.awaitRarityPrefetchForTesting()

        #expect(subject.profile != nil)
        subject.logout()

        #expect(subject.profile == nil)
        #expect(subject.awards == nil)
        #expect(subject.webAPIAuthenticated == false)
        #expect(subject.gameSummaryCache.isEmpty)
    }

    // MARK: - Error state

    @Test("A partial failure is still reported even though other calls succeeded")
    func partialFailureIsReported() async {
        let subject = makeSubject()
        var routes = fullRoutes
        routes.removeValue(forKey: "API_GetUserRecentAchievements")   // 404s
        MockURLProtocol.route(routes)

        await subject.authenticateCredentials(webAPIUsername: "mrosen97", webAPIKey: "key")
        await subject.awaitGameListSyncForTesting()
        await subject.awaitRarityPrefetchForTesting()

        // The profile loaded, so the screen stays usable — but something did
        // fail, and the user gets a banner rather than silently stale data.
        #expect(subject.profile != nil)
        #expect(subject.lastError != nil)
    }

    @Test("Throttling that recovers on retry is not reported at all")
    func recoveredThrottleIsSilent() async {
        let subject = makeSubject()
        // Rate limiting is expected against this API. A burst that the backoff
        // absorbs must leave no trace in the UI.
        let profile = Fixtures.userProfile
        let remaining = MockURLProtocol.Counter(2)
        MockURLProtocol.handler = { request in
            let url = request.url!
            if url.absoluteString.contains("API_GetUserProfile"),
               remaining.decrementIfPositive() {
                return (MockURLProtocol.response(url, status: 429), Data())
            }
            for (fragment, data) in [
                ("API_GetUserProfile", profile),
                ("API_GetUserAwards", Fixtures.userAwards),
                ("API_GetUserRecentAchievements", Fixtures.recentAchievements),
                ("API_GetUserCompletionProgress", Fixtures.completionProgress),
                ("API_GetUserRecentlyPlayedGames", Fixtures.recentlyPlayed),
                ("API_GetConsoleIDs", Fixtures.consoleIDs),
                ("API_GetGameList", Fixtures.gameList),
                ("API_GetGameInfoAndUserProgress", Fixtures.gameInfoAndUserProgress),
            ] where url.absoluteString.contains(fragment) {
                return (MockURLProtocol.response(url, status: 200), data)
            }
            return (MockURLProtocol.response(url, status: 404), Data())
        }

        await subject.authenticateCredentials(webAPIUsername: "mrosen97", webAPIKey: "key")
        await subject.awaitGameListSyncForTesting()
        await subject.awaitRarityPrefetchForTesting()

        #expect(subject.profile != nil)
        #expect(subject.lastError == nil)
    }

    @Test("Exhausted throttling stays quiet while usable data is on screen")
    func throttleDoesNotBannerOverData() {
        // It is still recorded, so an empty screen can explain itself — it just
        // does not interrupt a screen the user can still read.
        #expect(RANetworkError.rateLimited.deservesBannerOverExistingData == false)
        #expect(RANetworkError.offline.deservesBannerOverExistingData)
        #expect(RANetworkError.unauthorized.deservesBannerOverExistingData)
        #expect(RANetworkError.server(500).deservesBannerOverExistingData)
    }

    @Test("A real failure outranks a throttle so it cannot be hidden by it")
    func realErrorBeatsThrottle() {
        // rateLimited is suppressed over existing data, so if it also outranked
        // other errors it would take the slot and silence them.
        #expect(RANetworkError.server(500).severity > RANetworkError.rateLimited.severity)
        #expect(RANetworkError.offline.severity > RANetworkError.rateLimited.severity)
        #expect(RANetworkError.timedOut.severity > RANetworkError.rateLimited.severity)
        #expect(RANetworkError.decoding.severity > RANetworkError.rateLimited.severity)
        #expect(RANetworkError.unauthorized.severity > RANetworkError.offline.severity)
    }

    @Test("A successful fetch clears a previous error")
    func errorClearsOnSuccess() async {
        let subject = makeSubject()
        MockURLProtocol.respondAlways(with: Data(), status: 500)
        await subject.authenticateCredentials(webAPIUsername: "mrosen97", webAPIKey: "key")
        #expect(subject.lastError != nil)

        MockURLProtocol.route(fullRoutes)
        await subject.fetchAllProfileData()
        await subject.awaitGameListSyncForTesting()
        await subject.awaitRarityPrefetchForTesting()

        #expect(subject.lastError == nil)
        #expect(subject.profile != nil)
    }

    @Test("Logging out clears the error")
    func logoutClearsError() async {
        let subject = makeSubject()
        MockURLProtocol.respondAlways(with: Data(), status: 500)
        await subject.authenticateCredentials(webAPIUsername: "mrosen97", webAPIKey: "key")

        subject.logout()
        #expect(subject.lastError == nil)
    }

    @Test("When several requests fail at once the most actionable one wins")
    func mostActionableErrorWins() async {
        let subject = makeSubject()
        // Sign in cleanly first, then make one endpoint reject the key while
        // others merely fail. A rejected key must outrank a transient server
        // error, because it is the only one the user can act on.
        MockURLProtocol.route(fullRoutes)
        await subject.authenticateCredentials(webAPIUsername: "mrosen97", webAPIKey: "key")
        await subject.awaitGameListSyncForTesting()
        await subject.awaitRarityPrefetchForTesting()

        MockURLProtocol.handler = { request in
            let url = request.url!
            let status = url.absoluteString.contains("API_GetUserAwards") ? 401 : 500
            return (MockURLProtocol.response(url, status: status), Data())
        }
        await subject.fetchAllProfileData()
        await subject.awaitGameListSyncForTesting()
        await subject.awaitRarityPrefetchForTesting()

        #expect(subject.lastError == .unauthorized)
    }

    // MARK: - Rarity index

    @Test("A fetched game summary indexes every achievement's unlock share")
    func summaryPopulatesIndex() async {
        let subject = makeSubject()
        MockURLProtocol.route(fullRoutes)
        await subject.authenticateCredentials(webAPIUsername: "mrosen97", webAPIKey: "key")
        await subject.awaitGameListSyncForTesting()
        await subject.awaitRarityPrefetchForTesting()

        await subject.getGameSummary(gameID: 11278)

        // Fixture: 1 achievement, NumAwarded 900 of 1000 distinct players.
        #expect(subject.rarityIndex[12345] == 90)
        #expect(subject.rarity(forAchievement: 12345) == .common)
    }

    @Test("The profile deck's rarity comes from the index, not extra requests")
    func rarityServedFromIndex() async {
        let subject = makeSubject()
        MockURLProtocol.route(fullRoutes)
        await subject.authenticateCredentials(webAPIUsername: "mrosen97", webAPIKey: "key")
        await subject.awaitGameListSyncForTesting()
        await subject.awaitRarityPrefetchForTesting()

        let before = MockURLProtocol.recordedURLs.count
        _ = subject.rarity(forAchievement: 12345)

        #expect(MockURLProtocol.recordedURLs.count == before)
    }

    @Test("Prefetch fetches one summary per distinct game, not per achievement")
    func prefetchIsPerGame() async {
        let subject = makeSubject()
        var routes = fullRoutes
        // Ten recent achievements spread over two games.
        routes["API_GetUserRecentAchievements"] = Fixtures.recentAchievementsAcrossGames(
            games: [11278, 3210], perGame: 5)
        MockURLProtocol.route(routes)

        await subject.authenticateCredentials(webAPIUsername: "mrosen97", webAPIKey: "key")
        await subject.awaitGameListSyncForTesting()
        await subject.awaitRarityPrefetchForTesting()

        // Two games, so two summaries — not ten.
        #expect(MockURLProtocol.callCount(containing: "API_GetGameInfoAndUserProgress") == 2)
    }

    @Test("Prefetch is capped, even across a long achievement history")
    func prefetchIsCapped() async {
        let subject = makeSubject()
        var routes = fullRoutes
        // GetUserRecentAchievements is requested with m=999999999 — the whole
        // history. A real account had 453 unlocks across 40 distinct games;
        // walking all of them was both wasteful and enough to get throttled.
        routes["API_GetUserRecentAchievements"] = Fixtures.recentAchievementsAcrossGames(
            games: Array(1...40), perGame: 3)
        MockURLProtocol.route(routes)

        await subject.authenticateCredentials(webAPIUsername: "mrosen97", webAPIKey: "key")
        await subject.awaitGameListSyncForTesting()
        await subject.awaitRarityPrefetchForTesting()

        #expect(MockURLProtocol.callCount(containing: "API_GetGameInfoAndUserProgress") <= 8)
    }

    @Test("An event game's summary no longer poisons the profile with an error")
    func eventGameDoesNotError() async {
        let subject = makeSubject()
        var routes = fullRoutes
        routes["API_GetGameInfoAndUserProgress"] = Fixtures.gameInfoEventGame
        MockURLProtocol.route(routes)

        await subject.authenticateCredentials(webAPIUsername: "mrosen97", webAPIKey: "key")
        await subject.awaitGameListSyncForTesting()
        await subject.awaitRarityPrefetchForTesting()

        // The prefetch pulls event games; a decode failure there used to record
        // .decoding and leave a banner no retry could clear.
        #expect(subject.lastError == nil)
        #expect(subject.rarity(forAchievement: 77) == .legendary)   // 50 of 500 = 10%
    }

    @Test("A warm index makes no requests at all")
    func warmIndexIsFree() async {
        let subject = makeSubject()
        MockURLProtocol.route(fullRoutes)
        await subject.authenticateCredentials(webAPIUsername: "mrosen97", webAPIKey: "key")
        await subject.awaitGameListSyncForTesting()
        await subject.awaitRarityPrefetchForTesting()

        let afterFirstRun = MockURLProtocol.callCount(containing: "API_GetGameInfoAndUserProgress")

        // Second pass over the same recent achievements: everything the deck
        // needs is already indexed, so the prefetch is a no-op.
        subject.prefetchRarityForRecentAchievements()
        await subject.awaitRarityPrefetchForTesting()

        #expect(MockURLProtocol.callCount(containing: "API_GetGameInfoAndUserProgress")
                == afterFirstRun)
    }

    @Test("A game nobody has played does not divide by zero")
    func zeroPlayersIsSafe() async {
        let subject = makeSubject()
        var routes = fullRoutes
        routes["API_GetGameInfoAndUserProgress"] = Fixtures.gameInfoZeroPlayers
        MockURLProtocol.route(routes)
        await subject.authenticateCredentials(webAPIUsername: "mrosen97", webAPIKey: "key")
        await subject.awaitGameListSyncForTesting()
        await subject.awaitRarityPrefetchForTesting()

        await subject.getGameSummary(gameID: 11278)
        #expect(subject.rarity(forAchievement: 12345) == nil)
    }

    // MARK: - Comments

    @Test("Requests the achievement comment endpoint with t=2")
    func commentRequestShape() async {
        let subject = makeSubject()
        MockURLProtocol.route(["API_GetComments": Fixtures.achievementComments])

        let error = await subject.getComments(achievementID: 48638)

        #expect(error == nil)
        let url = MockURLProtocol.recordedURLs.first?.absoluteString
        #expect(url?.contains("API_GetComments.php") == true)
        #expect(url?.contains("i=48638") == true)
        #expect(url?.contains("t=2") == true)      // CommentTarget.achievement
    }

    @Test("Comments are cached by achievement id")
    func commentsCached() async {
        let subject = makeSubject()
        MockURLProtocol.route(["API_GetComments": Fixtures.achievementComments])

        await subject.getComments(achievementID: 48638)

        #expect(subject.commentsCache[48638]?.count == 4)
        #expect(subject.commentsCache[999] == nil)
    }

    @Test("A comment failure is returned to the caller, not raised app-wide")
    func commentFailureIsScoped() async {
        let subject = makeSubject()
        MockURLProtocol.respondAlways(with: Data(), status: 500)

        let error = await subject.getComments(achievementID: 48638)

        #expect(error == .server(500))
        // The sheet shows its own message; the profile banner stays quiet,
        // because a comment thread failing says nothing about the profile.
        #expect(subject.lastError == nil)
        #expect(subject.commentsCache[48638] == nil)
    }

    // MARK: - Status message

    @Test("A game played moments ago reports as playing")
    func statusPlaying() async {
        let subject = makeSubject()
        let now = DateFormatter.raStatus.string(from: Date())
        var routes = fullRoutes
        routes["API_GetUserRecentlyPlayedGames"] = Fixtures.data("""
        [{ "GameID": 11278, "ConsoleID": 2, "ConsoleName": "Nintendo 64",
           "Title": "Super Mario 64", "ImageIcon": "/i.png", "ImageTitle": "/t.png",
           "ImageIngame": "/g.png", "ImageBoxArt": "/b.png",
           "LastPlayed": "\(now)",
           "AchievementsTotal": 1, "NumPossibleAchievements": 1, "PossibleScore": 1,
           "NumAchieved": 1, "ScoreAchieved": 1, "NumAchievedHardcore": 1,
           "ScoreAchievedHardcore": 1 }]
        """)
        MockURLProtocol.route(routes)
        await subject.authenticateCredentials(webAPIUsername: "mrosen97", webAPIKey: "key")
        await subject.awaitGameListSyncForTesting()
        await subject.awaitRarityPrefetchForTesting()

        #expect(subject.buildUserStatusMessage().contains("[Playing"))
        #expect(subject.isUserOnline)
    }

    @Test("A game played hours ago reports as last seen")
    func statusLastSeen() async {
        let subject = makeSubject()
        MockURLProtocol.route(fullRoutes)   // fixture LastPlayed is in 2024
        await subject.authenticateCredentials(webAPIUsername: "mrosen97", webAPIKey: "key")
        await subject.awaitGameListSyncForTesting()
        await subject.awaitRarityPrefetchForTesting()

        #expect(subject.buildUserStatusMessage().contains("Last Seen"))
        #expect(subject.isUserOnline == false)
    }

    @Test("No matching recent game reports offline")
    func statusOffline() async {
        let subject = makeSubject()
        var routes = fullRoutes
        routes["API_GetUserRecentlyPlayedGames"] = Fixtures.emptyArray
        MockURLProtocol.route(routes)
        await subject.authenticateCredentials(webAPIUsername: "mrosen97", webAPIKey: "key")
        await subject.awaitGameListSyncForTesting()
        await subject.awaitRarityPrefetchForTesting()

        #expect(subject.buildUserStatusMessage() == "Offline")
        #expect(subject.isUserOnline == false)
    }
}

// Mirrors Network's private status formatter so tests can build a matching
// LastPlayed timestamp.
extension DateFormatter {
    static let raStatus: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        f.timeZone = TimeZone(abbreviation: "UTC")
        return f
    }()
}

extension Result {
    /// Small readability helper for the rate-limit tests.
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}
