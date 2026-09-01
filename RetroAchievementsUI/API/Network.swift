//
//  Network.swift
//  RetroAchievementsUI
//

import Foundation
import SwiftUI

@MainActor
class Network: ObservableObject {
    
    // MARK: - Static Formatters
    private static let statusDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        df.timeZone = TimeZone(abbreviation: "UTC")
        return df
    }()

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let rf = RelativeDateTimeFormatter()
        rf.unitsStyle = .full
        return rf
    }()

    // MARK: - Storage
    /// Game and console lists live on disk in Application Support, not in
    /// UserDefaults — they are multi-megabyte, rebuildable payloads.
    private let store: GameListStore

    /// Injectable so tests can drive the API layer through MockURLProtocol
    /// instead of the network.
    private let session: URLSession

    /// Base delay for 429 backoff. Injectable so rate-limit tests don't sleep
    /// for real.
    private let retryBaseDelay: TimeInterval

    init(session: URLSession = .shared,
         store: GameListStore = GameListStore(),
         retryBaseDelay: TimeInterval = 1.0) {
        self.session = session
        self.store = store
        self.retryBaseDelay = retryBaseDelay

        // One-time moves off the legacy UserDefaults storage.
        store.migrateLegacyBlobIfNeeded(.gameList, as: [GameListGame].self)
        store.migrateLegacyBlobIfNeeded(.consoleList, as: [Console].self)

        rarityIndex = store.load(.rarityIndex, as: [Int: Double].self,
                                 ttl: GameListStore.rarityIndexTTL) ?? [:]
        recentWindowByUser = store.load(.recentWindow, as: [String: Int].self) ?? [:]
    }

    // MARK: - Achievement rarity

    /// Rarity for an achievement the app has seen the parent game for.
    func rarity(forAchievement id: Int) -> AchievementRarity? {
        rarityIndex[id].map(AchievementRarity.init(unlockPercentage:))
    }

    /// Folds a game's achievement set into the index. Called for every summary
    /// the app fetches, whoever asked for it.
    private func indexRarities(from summary: GameSummary) {
        let players = summary.numDistinctPlayers
        guard players > 0 else { return }

        var changed = false
        for achievement in summary.achievements.values {
            let share = min(Double(achievement.numAwarded) / Double(players) * 100, 100)
            if rarityIndex[achievement.id] != share {
                rarityIndex[achievement.id] = share
                changed = true
            }
        }
        if changed { store.save(rarityIndex, to: .rarityIndex) }
    }

    /// Fills in rarity for the profile's Recent Achievements deck.
    ///
    /// Deliberately keyed on *distinct games*, not achievements: thirty recent
    /// unlocks usually come from a handful of games, and anything already in
    /// the index costs nothing. On a warm index this makes no requests.
    private var rarityPrefetchTask: Task<Void, Never>?

    /// Hard ceiling on how many games one prefetch may fetch.
    ///
    /// GetUserRecentAchievements is requested with m=999999999 — the user's
    /// entire history. Walking all of it looked for 40 distinct games on a
    /// modest account, which is both wasteful and enough for the API to start
    /// throttling. The deck only ever shows its newest handful, so the newest
    /// distinct games are all that is worth warming.
    private static let maxRarityPrefetchGames = 8

    func prefetchRarityForRecentAchievements() {
        guard rarityPrefetchTask == nil else { return }

        // Ordered-distinct, newest first, then capped.
        var missing: [Int] = []
        for achievement in userRecentAchievements
        where rarityIndex[achievement.id] == nil && !missing.contains(achievement.gameID) {
            missing.append(achievement.gameID)
            if missing.count == Self.maxRarityPrefetchGames { break }
        }
        guard !missing.isEmpty else { return }

        rarityPrefetchTask = Task { @MainActor in
            // Small batches: this runs behind an already-rendered screen and
            // must not contend with anything the user is waiting on.
            for batch in Array(missing).chunked(into: 4) {
                await withTaskGroup(of: Void.self) { group in
                    for gameID in batch {
                        group.addTask { await self.getGameSummary(gameID: gameID) }
                    }
                }
            }
            self.rarityPrefetchTask = nil
        }
    }

    /// Awaits any in-flight rarity prefetch. Tests only.
    func awaitRarityPrefetchForTesting() async {
        await rarityPrefetchTask?.value
    }

    var gameListLastSynced: Date? { store.cachedAt(.gameList) }

    // MARK: - Published Properties
    @Published var profile: Profile? = nil
    @Published var awards: Awards? = nil
    @Published var userRecentlyPlayedGames: [RecentGame] = []
    @Published var userGameCompletionProgress: UserGamesCompletionProgressResult? = nil
    @Published var gameSummaryCache: [Int: GameSummary] = [:]
    /// Comments keyed by achievement ID, fetched on demand by the achievement
    /// detail sheet.
    @Published var commentsCache: [Int: [Comment]] = [:]

    /// Achievement ID → share of the game's players holding it, 0–100.
    ///
    /// GetUserRecentAchievements carries no award counts, so the profile deck
    /// cannot work rarity out on its own. Every GameSummary the app fetches —
    /// for any reason — contributes its whole achievement set here, and the
    /// index is persisted, so after the first run the profile shows rarity with
    /// no extra requests at all.
    @Published private(set) var rarityIndex: [Int: Double] = [:]
    @Published var initialWebAPIAuthenticationCheckComplete: Bool = false
    @Published var webAPIAuthenticated: Bool = false
    @Published var consolesCache: Consoles? = nil
    @Published var authenticatedWebAPIUsername: String = ""
    @Published var userRecentAchievements: [RecentAchievement] = []
    @Published var gameList: [GameListGame] = []
    @Published var isFetching: Bool = false

    /// Why the most recent fetch failed, if it did. Cleared as soon as anything
    /// succeeds, so it never lingers after the connection comes back.
    @Published var lastError: RANetworkError? = nil
    
    // Tracks the long-running background game list synchronization
    @Published var isFetchingFullGameList: Bool = false
    @Published var syncProgressPercentage: Double = 0.0
    
    // MARK: - Private State
    private var authenticatedWebAPIKey: String = ""
    private var activeProfileTask: Task<Void, Never>?

    /// True when a screen has nothing to show and a failure explains why.
    var hasNoProfileData: Bool { profile == nil }

    /// Records a failure for the current fetch cycle, keeping the most
    /// actionable one when several concurrent requests fail together.
    ///
    /// Errors are cleared once at the start of a cycle rather than on each
    /// individual success: the fetchers run concurrently, so clearing per
    /// success made the surviving error depend on which request happened to
    /// finish last.
    private func record(_ error: RANetworkError) {
        guard let existing = lastError else {
            lastError = error
            return
        }
        if error.severity > existing.severity { lastError = error }
    }

    var isUserOnline: Bool {
        buildUserStatusMessage().contains("[Playing")
    }
    
    nonisolated func buildAuthenticationString(username: String, key: String) -> String {
        return "z=\(username)&y=\(key)"
    }
    
    // MARK: - Session Management
    func logout() {
        self.authenticatedWebAPIUsername = ""
        self.authenticatedWebAPIKey = ""
        self.webAPIAuthenticated = false
        self.gameSummaryCache = [:]
        self.userGameCompletionProgress = nil
        self.userRecentlyPlayedGames = []
        self.awards = nil
        self.profile = nil
        self.isFetching = false
        self.isFetchingFullGameList = false
        self.syncProgressPercentage = 0.0
        self.lastError = nil
    }

    func refreshGameList() async {
        store.clearAll()
        self.gameList = []
        await self.getGameConsoles()
        await self.getRAGameList()
    }
    
    // MARK: - Orchestration

    /// Fetches everything the profile screen needs, and returns once it has
    /// arrived.
    ///
    /// This used to assign `activeProfileTask` and return immediately without
    /// awaiting it, so only a *second* concurrent caller ever waited for the
    /// data. The first caller — login, and pull-to-refresh — returned before a
    /// single response landed.
    func fetchAllProfileData() async {
        if let existingTask = activeProfileTask {
            return await existingTask.value
        }

        let task = Task { @MainActor in
            self.isFetching = true
            // One cycle, one verdict — see record(_:).
            self.lastError = nil

            // Fetch core user identity and recent activity concurrently.
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.getProfile() }
                group.addTask { await self.getAwards() }
                group.addTask { await self.getUserRecentAchievements() }
                group.addTask { await self.getUserGameCompletionProgress() }
                group.addTask { await self.getUserRecentlyPlayedGames() } // Needed for Status Message
                group.addTask { await self.getGameConsoles() }
            }

            withAnimation(.easeInOut(duration: 0.5)) {
                self.isFetching = false
            }
        }

        activeProfileTask = task
        await task.value
        activeProfileTask = nil

        // Both of these run behind the rendered screen and are not awaited:
        // the game-list sync takes minutes, and the rarity prefetch only fires
        // for games the index has never seen.
        startGameListSyncIfNeeded()
        prefetchRarityForRecentAchievements()
    }

    private var gameListSyncTask: Task<Void, Never>?

    private func startGameListSyncIfNeeded() {
        guard gameListSyncTask == nil else { return }
        gameListSyncTask = Task { @MainActor in
            await self.getRAGameList()
            self.gameListSyncTask = nil
        }
    }

    /// Awaits any in-flight background game-list sync. Tests use this to keep
    /// stray requests from bleeding into the next case; the app never needs it.
    func awaitGameListSyncForTesting() async {
        await gameListSyncTask?.value
    }

    // MARK: - Network Core

    /// Performs a request, reporting *why* it failed rather than collapsing
    /// every outcome into `nil`.
    nonisolated func makeAPICall(url: URL) async -> Result<Data, RANetworkError> {
        let request = URLRequest(url: url)
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.transport("The server sent an invalid response."))
            }

            switch httpResponse.statusCode {
            case 200...299:
                return .success(data)
            case 401, 403:
                // The Web API rejected the key — no amount of retrying helps.
                return .failure(.unauthorized)
            case 429:
                if let retried = await handleRateLimit(request: request) {
                    return .success(retried)
                }
                return .failure(.rateLimited)
            default:
                return .failure(.server(httpResponse.statusCode))
            }
        } catch {
            return .failure(.from(error))
        }
    }

    /// Fetches and decodes in one step, so a malformed payload is reported as a
    /// decoding failure instead of silently leaving the screen empty.
    nonisolated private func fetch<T: Decodable>(
        _ url: URL?, as type: T.Type
    ) async -> Result<T, RANetworkError> {
        guard let url else {
            return .failure(.transport("Could not build a valid request URL."))
        }

        switch await makeAPICall(url: url) {
        case .success(let data):
            guard let decoded = try? JSONDecoder().decode(T.self, from: data) else {
                return .failure(.decoding)
            }
            return .success(decoded)
        case .failure(let error):
            return .failure(error)
        }
    }

    nonisolated private func handleRateLimit(request: URLRequest) async -> Data? {
        var retries = 1
        while retries < 5 {
            let retryDelay = pow(2.0, Double(retries - 1)) * retryBaseDelay
            try? await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))

            if let (data, response) = try? await session.data(for: request),
               (response as? HTTPURLResponse)?.statusCode == 200 {
                return data
            }
            retries += 1
        }
        return nil
    }
    
    func authenticateCredentials(webAPIUsername: String, webAPIKey: String) async {
        let auth = buildAuthenticationString(username: webAPIUsername, key: webAPIKey)
        let url = URL(string: "https://retroachievements.org/API/API_GetUserProfile.php?\(auth)&u=\(webAPIUsername)")

        switch await fetch(url, as: Profile.self) {
        case .success(let profile):
            self.profile = profile
            self.webAPIAuthenticated = true
            self.authenticatedWebAPIUsername = webAPIUsername
            self.authenticatedWebAPIKey = webAPIKey
            self.lastError = nil
            self.initialWebAPIAuthenticationCheckComplete = true
            await self.fetchAllProfileData()

        case .failure(.unauthorized):
            // The key really was rejected — sign the user out and say so.
            self.webAPIAuthenticated = false
            self.lastError = .unauthorized
            self.initialWebAPIAuthenticationCheckComplete = true
            self.isFetching = false

        case .failure(let error):
            // Could not reach the server. That is NOT a credential problem, so
            // don't dump a signed-in user at the login sheet every time they
            // lose signal — keep them in and let the screen offer a retry.
            self.authenticatedWebAPIUsername = webAPIUsername
            self.authenticatedWebAPIKey = webAPIKey
            self.webAPIAuthenticated = !webAPIUsername.isEmpty && !webAPIKey.isEmpty
            self.lastError = error
            self.initialWebAPIAuthenticationCheckComplete = true
            self.isFetching = false
        }
    }

    // MARK: - Game List Fetching
    func getRAGameList() async {
        if let cached = store.load(.gameList, as: [GameListGame].self, ttl: GameListStore.gameListTTL) {
            self.gameList = cached
            return
        }

        guard let consoles = self.consolesCache?.consoles else { return }
        self.isFetchingFullGameList = true
        self.syncProgressPercentage = 0.0
        
        let authString = buildAuthenticationString(username: authenticatedWebAPIUsername, key: authenticatedWebAPIKey)
        var finalAccumulatedList: [GameListGame] = []
        let batchSize = 8
        
        for i in stride(from: 0, to: consoles.count, by: batchSize) {
            let end = min(i + batchSize, consoles.count)
            let batch = Array(consoles[i..<end])
            
            let fetchedBatch = await withTaskGroup(of: [GameListGame]?.self) { group in
                for console in batch {
                    group.addTask {
                        let urlString = "https://retroachievements.org/API/API_GetGameList.php?\(authString)&i=\(console.id)&f=1"
                        // One console failing must not abandon the whole sync.
                        return try? await self.fetch(URL(string: urlString),
                                                     as: [GameListGame].self).get()
                    }
                }
                
                var batchCollection: [GameListGame] = []
                for await consoleGames in group {
                    if let games = consoleGames {
                        batchCollection.append(contentsOf: games)
                    }
                }
                return batchCollection
            }
            
            finalAccumulatedList.append(contentsOf: fetchedBatch)
            self.syncProgressPercentage = (Double(end) / Double(consoles.count)) * 100
            
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        
        if !finalAccumulatedList.isEmpty {
            self.gameList = finalAccumulatedList
            store.save(finalAccumulatedList, to: .gameList)
        }

        self.isFetchingFullGameList = false
    }

    // MARK: - Individual Data Fetchers
    func getProfile() async {
        let auth = buildAuthenticationString(username: authenticatedWebAPIUsername, key: authenticatedWebAPIKey)
        let url = URL(string: "https://retroachievements.org/API/API_GetUserProfile.php?\(auth)&u=\(self.authenticatedWebAPIUsername)")
        switch await fetch(url, as: Profile.self) {
        case .success(let decoded): self.profile = decoded
        case .failure(let error): record(error)
        }
    }

    func getAwards() async {
        let auth = buildAuthenticationString(username: authenticatedWebAPIUsername, key: authenticatedWebAPIKey)
        let url = URL(string: "https://retroachievements.org/API/API_GetUserAwards.php?\(auth)&u=\(self.authenticatedWebAPIUsername)")
        switch await fetch(url, as: Awards.self) {
        case .success(let decoded): self.awards = decoded
        case .failure(let error): record(error)
        }

        // NOTE: this method used to loop over every game award and serially
        // await getGameSummary(gameID:) — one full GetGameInfoAndUserProgress
        // round-trip per award, inside the profile load. An account with 200
        // masteries paid 200 sequential requests before the profile could
        // finish. Everything the award cards need already arrives in the single
        // GetUserCompletionProgress call that runs in parallel with this one,
        // so the loop is gone. See awardCards(hardcoreMode:).
    }

    /// Award cards for the profile/collection screens, joined from the awards
    /// and completion-progress responses. No additional requests.
    func awardCards(hardcoreMode: Bool) -> [AwardCardModel] {
        guard let awards else { return [] }

        let progressByGameID = Dictionary(
            (userGameCompletionProgress?.results ?? []).map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        return AwardCardModel.build(
            awards: filterHighestAwardType(awards: awards.visibleUserAwards),
            progress: progressByGameID,
            hardcoreMode: hardcoreMode
        )
    }

    func getUserRecentlyPlayedGames() async {
        let auth = buildAuthenticationString(username: authenticatedWebAPIUsername, key: authenticatedWebAPIKey)
        // c=25, not the previous c=3: Recently Played is a scrollable carousel
        // now, so three games no longer fills it. This also makes the profile
        // status message far more likely to find the user's last-played game.
        let url = URL(string: "https://retroachievements.org/API/API_GetUserRecentlyPlayedGames.php?\(auth)&u=\(self.authenticatedWebAPIUsername)&c=25")
        switch await fetch(url, as: [RecentGame].self) {
        case .success(let decoded): self.userRecentlyPlayedGames = decoded
        case .failure(let error): record(error)
        }
    }

    /// GetUserRecentAchievements caps its response at 500 rows — and when the
    /// cap is hit it does **not** return the newest 500. It returns an older
    /// slice.
    ///
    /// `nonisolated` because tests read it from `MockURLProtocol`'s request
    /// handler, which is a Sendable closure running off the main actor. Both
    /// constants are immutable value types, so this is free of risk — and
    /// without it the reference is an error under the Swift 6 language mode.
    nonisolated static let recentAchievementResultCap = 500

    /// Look-back windows in minutes: 1 day, 7 days, 30 days, 180 days, 2 years.
    nonisolated static let recentAchievementWindows = [1_440, 10_080, 43_200, 259_200, 1_051_200]

    /// Index of the window to try first for a user never seen before. 30 days
    /// suits an active player: one request, comfortably under the cap.
    private static let defaultRecentWindowIndex = 2

    /// The window that last worked, per username, persisted across launches.
    ///
    /// How much history a player has does not change between refreshes, so
    /// re-deriving the window every time is wasted work: only the first refresh
    /// for a given account should pay for narrowing or widening. Keyed by
    /// username so switching accounts — or viewing someone else — cannot
    /// inherit the wrong starting point.
    private var recentWindowByUser: [String: Int] = [:]

    /// Remembers the window that settled, if it is not what we already had.
    private func rememberRecentWindow(_ index: Int, for user: String) {
        guard recentWindowByUser[user] != index else { return }
        recentWindowByUser[user] = index
        store.save(recentWindowByUser, to: .recentWindow)
    }

    /// Below this many rows the window is widened, provided widening does not
    /// hit the cap.
    ///
    /// The deck shows 30 achievements *after* the Hardcore Mode and unofficial
    /// filters run, so the raw list needs headroom: a player who mixes softcore
    /// and hardcore could see most of a small window filtered away. Four times
    /// the deck's size leaves room for that without chasing history nobody
    /// looks at.
    private static let comfortableRecentCount = 120

    /// Recent achievements, over the widest window that stays under the API's cap.
    ///
    /// This used to ask for `m=999999999` — "everything". For any player with
    /// more than 500 achievements in range that hits the cap, and the API then
    /// answers with an *old* slice rather than the newest rows. A real account
    /// (x1b2, ~19.5k points) got achievements ending 2025-10-27 while actively
    /// playing in August 2026 — ten months stale, and nothing to do with
    /// hardcore/softcore.
    ///
    /// The goal is the widest window that is still under the cap: capped rows
    /// are wrong, and a too-narrow window starves the filtered deck. Rather
    /// than start at the widest and discard two 500-row (~230 KB) responses on
    /// the way down, this starts where an active player usually lands, then
    /// narrows if capped or widens if there is room. Common case: one request.
    func getUserRecentAchievements() async {
        let windows = Self.recentAchievementWindows
        let user = authenticatedWebAPIUsername
        // Start where this account settled last time; a first-time account
        // starts at the default and pays the search once.
        var index = recentWindowByUser[user] ?? Self.defaultRecentWindowIndex
        var visited = Set<Int>()
        var best: [RecentAchievement]?
        var bestIndex = index

        while !visited.contains(index) {
            visited.insert(index)

            let auth = buildAuthenticationString(username: authenticatedWebAPIUsername, key: authenticatedWebAPIKey)
            let url = URL(string: "https://retroachievements.org/API/API_GetUserRecentAchievements.php?\(auth)&u=\(self.authenticatedWebAPIUsername)&m=\(windows[index])")

            switch await fetch(url, as: [RecentAchievement].self) {
            case .failure(let error):
                // Keep anything a narrower window already produced rather than
                // discarding good rows over a failed widening attempt.
                if let best { self.userRecentAchievements = best } else { record(error) }
                return

            case .success(let decoded):
                if decoded.count >= Self.recentAchievementResultCap {
                    // Capped: these rows are an old slice, not the newest, so
                    // they can never be the answer. Narrow and retry.
                    guard index > 0 else {
                        // Even the narrowest window is capped — a player with
                        // 500+ unlocks in a day. Best effort.
                        self.userRecentAchievements = best ?? decoded
                        rememberRecentWindow(best == nil ? index : bestIndex, for: user)
                        return
                    }
                    index -= 1
                    continue
                }

                // Under the cap, so trustworthy. Keep the largest such result.
                if decoded.count >= (best?.count ?? -1) {
                    best = decoded
                    bestIndex = index
                }

                if decoded.count < Self.comfortableRecentCount, index < windows.count - 1 {
                    // Room for more history without risking the cap.
                    index += 1
                    continue
                }

                self.userRecentAchievements = best ?? decoded
                rememberRecentWindow(bestIndex, for: user)
                return
            }
        }

        if let best {
            self.userRecentAchievements = best
            rememberRecentWindow(bestIndex, for: user)
        }
    }

    func getUserGameCompletionProgress() async {
        let auth = buildAuthenticationString(username: authenticatedWebAPIUsername, key: authenticatedWebAPIKey)
        let url = URL(string: "https://retroachievements.org/API/API_GetUserCompletionProgress.php?\(auth)&u=\(self.authenticatedWebAPIUsername)&c=500")
        switch await fetch(url, as: UserGamesCompletionProgressResult.self) {
        case .success(let decoded): self.userGameCompletionProgress = decoded
        case .failure(let error): record(error)
        }
    }

    func getGameSummary(gameID: Int) async {
        let auth = buildAuthenticationString(username: authenticatedWebAPIUsername, key: authenticatedWebAPIKey)
        let url = URL(string: "https://retroachievements.org/API/API_GetGameInfoAndUserProgress.php?\(auth)&g=\(gameID)&u=\(self.authenticatedWebAPIUsername)&a=1")
        switch await fetch(url, as: GameSummary.self) {
        case .success(let decoded):
            self.gameSummaryCache[decoded.id] = decoded
            indexRarities(from: decoded)
        case .failure(let error):
            record(error)
        }
    }

    /// Comments for one achievement.
    ///
    /// Fetched on demand — the profile load must not pay for comments on every
    /// achievement the user might tap.
    ///
    /// - Returns: the failure, if any, so the sheet can show its own error
    ///   without disturbing the app-wide banner. A comment thread failing to
    ///   load is not a reason to tell the user their profile is broken.
    @discardableResult
    func getComments(achievementID: Int, limit: Int = 50) async -> RANetworkError? {
        let auth = buildAuthenticationString(username: authenticatedWebAPIUsername, key: authenticatedWebAPIKey)
        let url = URL(string: "https://retroachievements.org/API/API_GetComments.php?\(auth)&i=\(achievementID)&t=\(CommentTarget.achievement.rawValue)&c=\(limit)")

        switch await fetch(url, as: CommentsResult.self) {
        case .success(let decoded):
            self.commentsCache[achievementID] = decoded.results
            return nil
        case .failure(let error):
            return error
        }
    }

    func getGameConsoles() async {
        // Console list shares the game list's TTL — it was previously cached
        // forever, so a newly supported console never appeared until the user
        // manually hit "Refresh Game List".
        if let cached = store.load(.consoleList, as: [Console].self, ttl: GameListStore.gameListTTL) {
            self.consolesCache = Consoles(consoles: cached)
            return
        }

        let auth = buildAuthenticationString(username: authenticatedWebAPIUsername, key: authenticatedWebAPIKey)
        let url = URL(string: "https://retroachievements.org/API/API_GetConsoleIDs.php?\(auth)")
        switch await fetch(url, as: [Console].self) {
        case .success(let decoded):
            self.consolesCache = Consoles(consoles: decoded)
            store.save(decoded, to: .consoleList)
        case .failure(let error):
            record(error)
        }
    }

    // MARK: - Formatting Helpers
    func buildUserStatusMessage() -> String {
        guard let profile = self.profile else { return "Loading Profile..." }
        
        // Use userRecentlyPlayedGames to find the current/last game.
        // This array is small and fetched in the core login block.
        guard let lastPlayedGame = self.userRecentlyPlayedGames.first(where: { $0.id == profile.lastGameID }) else {
            return "Offline"
        }
        
        guard let lastPlayedDate = Self.statusDateFormatter.date(from: lastPlayedGame.lastPlayed) else {
            return "Offline"
        }
        
        // If played within last 5 minutes, assume "Playing", else "Last Seen"
        if abs(lastPlayedDate.timeIntervalSinceNow) > 300 {
            let relative = Self.relativeFormatter.localizedString(for: lastPlayedDate, relativeTo: Date.now)
            return "[Last Seen Playing '\(lastPlayedGame.title)' (\(lastPlayedGame.consoleName)) - \(relative)]"
        } else {
            return "[Playing: '\(lastPlayedGame.title)' | Game Status: \(profile.richPresenceMsg ?? "Unknown")]"
        }
    }

    /// Collapses a user's awards to the single highest tier per game.
    ///
    /// A game the user mastered also carries a "Game Beaten" award; only the
    /// mastery should be shown.
    ///
    /// Site awards are passed through untouched. The previous implementation
    /// grouped by `AwardData` (the game ID), which is `nil` for *every* site
    /// award — so all of them landed in one group and were then deleted
    /// wholesale. That went unnoticed because AwardsView read site awards from
    /// the unfiltered array.
    func filterHighestAwardType(awards: [VisibleUserAward]) -> [VisibleUserAward] {
        var highestPerGame: [Int: VisibleUserAward] = [:]
        var passthrough: [VisibleUserAward] = []

        for award in awards {
            guard let gameID = award.id, award.consoleID != nil else {
                passthrough.append(award)
                continue
            }

            guard let existing = highestPerGame[gameID] else {
                highestPerGame[gameID] = award
                continue
            }

            // Ranking by AwardTier also resolves the hardcore/softcore duplicate
            // of the same award type, which the old string comparison did not.
            if AwardTier(award: award) > AwardTier(award: existing) {
                highestPerGame[gameID] = award
            }
        }

        // Preserve the API's original ordering rather than the dictionary's.
        let kept = Set(highestPerGame.values.map(\.awardIdentity))
        return awards.filter { award in
            award.id == nil || award.consoleID == nil || kept.contains(award.awardIdentity)
        }
    }
}
