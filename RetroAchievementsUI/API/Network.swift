//
//  Network.swift
//  RetroAchievementsUI
//

import Foundation
import SwiftUI
import Kingfisher

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

    // MARK: - AppStorage
    @AppStorage("completeRetroAchievementsConsoleListJSONData") var completeRetroAchievementsConsoleListJSONData: Data?
    @AppStorage("completeRetroAchievementsGameListJSONData") var completeRetroAchievementsGameListJSONData: Data?
    @AppStorage("cacheDate") var cacheDate: TimeInterval?
    
    // MARK: - Published Properties
    @Published var profile: Profile? = nil
    @Published var awards: Awards? = nil
    @Published var userRecentlyPlayedGames: [RecentGame] = []
    @Published var userGameCompletionProgress: UserGamesCompletionProgressResult? = nil
    @Published var gameSummaryCache: [Int: GameSummary] = [:]
    @Published var initialWebAPIAuthenticationCheckComplete: Bool = false
    @Published var webAPIAuthenticated: Bool = false
    @Published var consolesCache: Consoles? = nil
    @Published var authenticatedWebAPIUsername: String = ""
    @Published var userRecentAchievements: [RecentAchievement] = []
    @Published var gameList: [GameListGame] = []
    @Published var isFetching: Bool = false
    
    // Tracks the long-running background game list synchronization
    @Published var isFetchingFullGameList: Bool = false
    @Published var syncProgressPercentage: Double = 0.0
    
    // MARK: - Private State
    private var authenticatedWebAPIKey: String = ""
    private var activeProfileTask: Task<Void, Never>?

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
    }
    
    func refreshGameList() async {
        self.completeRetroAchievementsGameListJSONData = nil
        self.cacheDate = nil
        self.gameList = []
        await self.getRAGameList()
    }
    
    // MARK: - Orchestration
    func fetchAllProfileData() async {
        if let existingTask = activeProfileTask {
            return await existingTask.value
        }

        activeProfileTask = Task {
            self.isFetching = true
            
            // Phase 1: Fetch core user identity and recent activity data concurrently
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.getProfile() }
                group.addTask { await self.getAwards() }
                group.addTask { await self.getUserRecentAchievements() }
                group.addTask { await self.getUserGameCompletionProgress() }
                group.addTask { await self.getUserRecentlyPlayedGames() } // Needed for Status Message
                group.addTask { await self.getGameConsoles() }
            }
            
            // Phase 2: Signal that the login/profile view can now proceed
            withAnimation(.easeInOut(duration: 0.5)) {
                self.isFetching = false
            }
            
            // Phase 3: Trigger the long-running game list fetch in the background
            await self.getRAGameList()
            
            activeProfileTask = nil
        }
    }

    // MARK: - Network Core
    nonisolated func makeAPICall(url: URL) async -> Data? {
        let request = URLRequest(url: url)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { return nil }
            
            if httpResponse.statusCode == 200 {
                return data
            } else if httpResponse.statusCode == 429 {
                return await handleRateLimit(request: request)
            }
            return nil
        } catch {
            return nil
        }
    }

    nonisolated private func handleRateLimit(request: URLRequest) async -> Data? {
        var retries = 1
        while retries < 5 {
            let retryDelay = Int(pow(2.0, Double(retries - 1))) * 1_000_000_000
            try? await Task.sleep(nanoseconds: UInt64(retryDelay))
            
            if let (data, response) = try? await URLSession.shared.data(for: request),
               (response as? HTTPURLResponse)?.statusCode == 200 {
                return data
            }
            retries += 1
        }
        return nil
    }
    
    func authenticateCredentials(webAPIUsername: String, webAPIKey: String) async {
        let auth = buildAuthenticationString(username: webAPIUsername, key: webAPIKey)
        guard let url = URL(string: "https://retroachievements.org/API/API_GetUserProfile.php?\(auth)&u=\(webAPIUsername)") else { return }
        
        if await makeAPICall(url: url) != nil {
            self.initialWebAPIAuthenticationCheckComplete = true
            self.webAPIAuthenticated = true
            self.authenticatedWebAPIUsername = webAPIUsername
            self.authenticatedWebAPIKey = webAPIKey
            await self.fetchAllProfileData()
        } else {
            self.initialWebAPIAuthenticationCheckComplete = true
            self.webAPIAuthenticated = false
            self.isFetching = false
        }
    }

    // MARK: - Game List Fetching
    func getRAGameList() async {
        let sevenDays: TimeInterval = 604800
        let currentCacheDate = Date(timeIntervalSince1970: self.cacheDate ?? 0)
        
        if let cachedData = self.completeRetroAchievementsGameListJSONData,
           Date().timeIntervalSince(currentCacheDate) < sevenDays {
            if let decoded = try? JSONDecoder().decode([GameListGame].self, from: cachedData) {
                self.gameList = decoded
                return
            }
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
                        guard let url = URL(string: urlString),
                              let data = await self.makeAPICall(url: url) else { return nil }
                        return try? JSONDecoder().decode([GameListGame].self, from: data)
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
            if let encoded = try? JSONEncoder().encode(finalAccumulatedList) {
                self.gameList = finalAccumulatedList
                self.completeRetroAchievementsGameListJSONData = encoded
                self.cacheDate = Date().timeIntervalSince1970
            }
        }
        
        self.isFetchingFullGameList = false
    }

    // MARK: - Individual Data Fetchers
    func getProfile() async {
        let auth = buildAuthenticationString(username: authenticatedWebAPIUsername, key: authenticatedWebAPIKey)
        guard let url = URL(string: "https://retroachievements.org/API/API_GetUserProfile.php?\(auth)&u=\(self.authenticatedWebAPIUsername)") else { return }
        if let data = await makeAPICall(url: url), let decoded = try? JSONDecoder().decode(Profile.self, from: data) {
            self.profile = decoded
        }
    }

    func getAwards() async {
        let auth = buildAuthenticationString(username: authenticatedWebAPIUsername, key: authenticatedWebAPIKey)
        guard let url = URL(string: "https://retroachievements.org/API/API_GetUserAwards.php?\(auth)&u=\(self.authenticatedWebAPIUsername)") else { return }
        if let data = await makeAPICall(url: url), let decoded = try? JSONDecoder().decode(Awards.self, from: data) {
            self.awards = decoded
        }
    }

    func getUserRecentlyPlayedGames() async {
        let auth = buildAuthenticationString(username: authenticatedWebAPIUsername, key: authenticatedWebAPIKey)
        guard let url = URL(string: "https://retroachievements.org/API/API_GetUserRecentlyPlayedGames.php?\(auth)&u=\(self.authenticatedWebAPIUsername)&c=3") else { return }
        if let data = await makeAPICall(url: url), let decoded = try? JSONDecoder().decode([RecentGame].self, from: data) {
            self.userRecentlyPlayedGames = decoded
        }
    }

    func getUserRecentAchievements() async {
        let auth = buildAuthenticationString(username: authenticatedWebAPIUsername, key: authenticatedWebAPIKey)
        guard let url = URL(string: "https://retroachievements.org/API/API_GetUserRecentAchievements.php?\(auth)&u=\(self.authenticatedWebAPIUsername)&m=999999999") else { return }
        if let data = await makeAPICall(url: url), let decoded = try? JSONDecoder().decode([RecentAchievement].self, from: data) {
            self.userRecentAchievements = decoded
        }
    }

    func getUserGameCompletionProgress() async {
        let auth = buildAuthenticationString(username: authenticatedWebAPIUsername, key: authenticatedWebAPIKey)
        guard let url = URL(string: "https://retroachievements.org/API/API_GetUserCompletionProgress.php?\(auth)&u=\(self.authenticatedWebAPIUsername)&c=500") else { return }
        if let data = await makeAPICall(url: url), let decoded = try? JSONDecoder().decode(UserGamesCompletionProgressResult.self, from: data) {
            self.userGameCompletionProgress = decoded
        }
    }

    func getGameSummary(gameID: Int) async {
        let auth = buildAuthenticationString(username: authenticatedWebAPIUsername, key: authenticatedWebAPIKey)
        guard let url = URL(string: "https://retroachievements.org/API/API_GetGameInfoAndUserProgress.php?\(auth)&g=\(gameID)&u=\(self.authenticatedWebAPIUsername)&a=1") else { return }
        if let data = await makeAPICall(url: url), let decoded = try? JSONDecoder().decode(GameSummary.self, from: data) {
            self.gameSummaryCache[decoded.id] = decoded
        }
    }

    func getGameConsoles() async {
        if let cached = self.completeRetroAchievementsConsoleListJSONData,
           let decoded = try? JSONDecoder().decode([Console].self, from: cached) {
            self.consolesCache = Consoles(consoles: decoded)
            return
        }
        let auth = buildAuthenticationString(username: authenticatedWebAPIUsername, key: authenticatedWebAPIKey)
        guard let url = URL(string: "https://retroachievements.org/API/API_GetConsoleIDs.php?\(auth)") else { return }
        if let data = await makeAPICall(url: url), let decoded = try? JSONDecoder().decode([Console].self, from: data) {
            self.consolesCache = Consoles(consoles: decoded)
            self.completeRetroAchievementsConsoleListJSONData = data
        }
    }

    // MARK: - Formatting Helpers
    func buildUserStatusMessage() -> String {
        guard let profile = self.profile else { return "Loading Profile..." }
        
        // Use userRecentlyPlayedGames to find the current/last game.
        // This array is small and fetched in the core login block.
        guard let lastPlayedGame = self.userRecentlyPlayedGames.first(where: { $0.id == profile.lastGameID }) else {
            return "Online"
        }
        
        guard let lastPlayedDate = Self.statusDateFormatter.date(from: lastPlayedGame.lastPlayed) else {
            return "Online"
        }
        
        // If played within last 5 minutes, assume "Playing", else "Last Seen"
        if abs(lastPlayedDate.timeIntervalSinceNow) > 300 {
            let relative = Self.relativeFormatter.localizedString(for: lastPlayedDate, relativeTo: Date.now)
            return "[Last Seen Playing '\(lastPlayedGame.title)' (\(lastPlayedGame.consoleName)) - \(relative)]"
        } else {
            return "[Playing: '\(lastPlayedGame.title)' | Game Status: \(profile.richPresenceMsg ?? "Unknown")]"
        }
    }

    func filterHighestAwardType(awards: [VisibleUserAward]) -> [VisibleUserAward] {
        var filtered = awards
        let grouped = Dictionary(grouping: awards, by: { $0.id })
        for (id, matches) in grouped where matches.count > 1 {
            let highest = matches.contains(where: { $0.awardType == "Mastery/Completion" }) ? "Mastery/Completion" : "Game Beaten"
            filtered.removeAll { $0.id == id && $0.awardType != highest }
        }
        return filtered
    }
}
