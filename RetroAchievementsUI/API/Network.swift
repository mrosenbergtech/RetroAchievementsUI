//
//  Network.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//

import Foundation
import SwiftUI

class Network: ObservableObject {
    // Cache "Stable" Data in AppStorage
    @AppStorage("completeRetroAchievementsConsoleListJSONData") var completeRetroAchievementsConsoleListJSONData: Data?
    @AppStorage("completeRetroAchievementsGameListJSONData") var completeRetroAchievementsGameListJSONData: Data?
    
    // Store Dynamic Data in Memory
    @Published var profile: Profile? = nil
    @Published var awards: Awards? = nil
    @Published var userRecentlyPlayedGames: [RecentGame] = []
    @Published var userGameCompletionProgress: UserGamesCompletionProgressResult? = nil
    @Published var consoleGamesCache: [Int : [ConsoleGameInfo]] = [:]
    @Published var gameSummaryCache: [Int: GameSummary] = [:]
    @Published var initialWebAPIAuthenticationCheckComplete: Bool = false
    @Published var webAPIAuthenticated: Bool = false
    @Published var consolesCache: Consoles? = nil
    @Published var authenticatedWebAPIUsername: String = ""
    @Published var userRecentAchievements: [RecentAchievement] = []
    @Published var gameList: [GameListGame] = []
    
    // Keep Validated RA API Key Private
    private var authenticatedWebAPIKey: String = ""
    
    func buildAuthenticationString() -> String {
        return "z=\(authenticatedWebAPIUsername)&y=\(authenticatedWebAPIKey)"
    }
    
    func logout() {
        // Clear All But Console Cache
        DispatchQueue.main.async {
            self.authenticatedWebAPIUsername = ""
            self.authenticatedWebAPIKey = ""
            self.webAPIAuthenticated = false
            self.gameSummaryCache = [:]
            self.userGameCompletionProgress = nil
            self.userRecentlyPlayedGames = []
            self.awards = nil
            self.profile = nil
            print("Data Cache Cleared")
        }
    }
    
    func refreshGameList() async {
        print("Clearing Cached Game List...")
        
        DispatchQueue.main.sync {
            self.completeRetroAchievementsGameListJSONData = nil
        }
        
        print("Done. Fetching Game List...")
        
        await self.getRAGameList()
        
        print("Game List Refreshed!")
    }
    
    func makeAPICall(url: URL) async -> Data? {
        let request = URLRequest(url: url)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { return nil }
            
            // Good Response - Return Data
            if response.statusCode == 200 {
                return data
            } else if response.statusCode == 401 {
                print("Returned Code 401: Unauthorized")
                return nil
            
            } else if response.statusCode == 429 {
                print("Returned Code 429: Too Many Requests")
                
                var retries = 1
                while retries < 5 {
                    let retryDelay = Int(pow(Double(2), Double(retries-1))) * 500000000
                    print(" Retrying (# \(retries)) after \(retryDelay/1000000) ms")
                    try await Task.sleep(nanoseconds: UInt64(retryDelay))
                    
                    do {
                        let (data, response) = try await URLSession.shared.data(for: request)
                        guard let response = response as? HTTPURLResponse else { return nil }
                        
                        // Good Response - Return Data
                        if response.statusCode == 200 {
                            print("Success on Retry #\(retries)!")
                            return data
                        } else if response.statusCode == 401 {
                            print(" Returned Code 401: Unauthorized")
                            return nil
                        } else if response.statusCode == 429 {
                            print(" Failed on Retry #\(retries)!")
                            retries += 1
                        }
                        
                    } catch {
                        print(error)
                        return nil
                    }
                }
            } else {
                print("Returned Other Status Code: " + String(response.statusCode))
                return nil
            }
        } catch {
            print(error)
            return nil
        }
        
        return nil
    }
        
    func authenticateCredentials(webAPIUsername: String, webAPIKey: String) async {
        guard let url = URL(string: "https://retroachievements.org/API/API_GetUserProfile.php?z=\(webAPIUsername)&y=\(webAPIKey)&u=\(webAPIUsername)") else { fatalError("Missing URL") }
        
        if ((await makeAPICall(url: url)) != nil) {
            DispatchQueue.main.sync {
                self.initialWebAPIAuthenticationCheckComplete = true
                self.webAPIAuthenticated = true
                self.authenticatedWebAPIUsername = webAPIUsername
                self.authenticatedWebAPIKey = webAPIKey
            }
            
            await self.getProfile()
            await self.getAwards()
            await self.getUserRecentAchievements()
            await self.getUserGameCompletionProgress()
            await self.getUserRecentGames()
            await self.getGameConsoles()
            await self.getRAGameList()
            
        } else {
            print("Bad Response Code!")
            DispatchQueue.main.sync {
                self.initialWebAPIAuthenticationCheckComplete = true
                self.webAPIAuthenticated = false
                self.authenticatedWebAPIUsername = ""
                self.authenticatedWebAPIKey = ""
            }
        }
    }
    
    func getProfile() async {
        guard let url = URL(string: "https://retroachievements.org/API/API_GetUserProfile.php?\(buildAuthenticationString())&u=\(self.authenticatedWebAPIUsername)") else { fatalError("Missing URL") }
        
        if let raAPIResponse: Data = await makeAPICall(url: url) {
            DispatchQueue.main.sync {
                do {
                    let decodedProfile = try JSONDecoder().decode(Profile.self, from: raAPIResponse)
                    self.profile = decodedProfile
                } catch let error {
                    print("Error decoding: ", error)
                }
            }
        } else {
            print("Bad Response Code!")
        }
    }
    
    func getAwards() async {
        guard let url = URL(string: "https://retroachievements.org/API/API_GetUserAwards.php?\(buildAuthenticationString())&u=\(self.authenticatedWebAPIUsername)") else { fatalError("Missing URL") }
        
        if let raAPIResponse: Data = await makeAPICall(url: url) {
            DispatchQueue.main.sync {
                do {
                    let decodedAwards = try JSONDecoder().decode(Awards.self, from: raAPIResponse)
                    self.awards = decodedAwards
                } catch let error {
                    print("Error decoding: ", error)
                }
            }
        } else {
            print("Bad Response Code!")
        }
    }
    
    func filterHighestAwardType(awards: [VisibleUserAward]) -> [VisibleUserAward] {
        var filteredAwardList: [VisibleUserAward] = awards
        var filteredAwardIDList: [Int] = []
        for award in filteredAwardList {
            
            // Find Matching Award IDs
            if !filteredAwardIDList.contains(award.id ?? -1) {
                let matchingAwards = filteredAwardList.filter { $0.id == award.id }
                
                // Find Highest Award
                if matchingAwards.count > 1 {
                    var highestAward: String?
                    
                    for matchingAward in matchingAwards {
                        if matchingAward.awardType == "Game Beaten" && highestAward != "Mastery/Completion" {
                            highestAward = "Game Beaten"
                        } else if matchingAward.awardType == "Mastery/Completion" {
                            highestAward = "Mastery/Completion"
                        }
                    }
                                                                        
                    // Remove Lower Awards
                    let lowerAwards = matchingAwards.filter { $0.awardType != highestAward }
                    if lowerAwards.count > 0 {
                        for lowerAward in lowerAwards {
                            filteredAwardList.removeAll(where: { $0.id == lowerAward.id && $0.awardType == lowerAward.awardType })
                        }
                    }
                    
                    filteredAwardIDList.append(award.id!)
                }
            }
        }
        
        return filteredAwardList
    }
    
    func getUserRecentGames() async {
        guard let url = URL(string: "https://retroachievements.org/API/API_GetUserRecentlyPlayedGames.php?\(buildAuthenticationString())&u=\(self.authenticatedWebAPIUsername)&c=3") else { fatalError("Missing URL") }
        
        if let raAPIResponse: Data = await makeAPICall(url: url) {
            DispatchQueue.main.sync {
                do {
                    let decodedUserRecentlyPlayedGames = try JSONDecoder().decode([RecentGame].self, from: raAPIResponse)
                    self.userRecentlyPlayedGames = decodedUserRecentlyPlayedGames
                } catch let error {
                    print("Error decoding: ", error)
                }
            }
        } else {
            print("Bad Response Code!")
        }
    }
    
    func getUserRecentAchievements() async {
        guard let url = URL(string: "https://retroachievements.org/API/API_GetUserRecentAchievements.php?\(buildAuthenticationString())&u=\(self.authenticatedWebAPIUsername)&m=999999999") else { fatalError("Missing URL") }
        
        if let raAPIResponse: Data = await makeAPICall(url: url) {
            DispatchQueue.main.sync {
                do {
                    let decodedRecentAchievements = try JSONDecoder().decode([RecentAchievement].self, from: raAPIResponse)
                    self.userRecentAchievements = decodedRecentAchievements
                } catch let error {
                    print("Error decoding: ", error)
                }
            }
        } else {
            print("Bad Response Code!")
        }
    }
    
    func getUserGameCompletionProgress() async {
        guard let url = URL(string: "https://retroachievements.org/API/API_GetUserCompletionProgress.php?\(buildAuthenticationString())&u=\(self.authenticatedWebAPIUsername)&c=500") else { fatalError("Missing URL") }
        
        if let raAPIResponse: Data = await makeAPICall(url: url) {
            DispatchQueue.main.sync {
                do {
                    let decodedUserGameCompletionProgress = try JSONDecoder().decode(UserGamesCompletionProgressResult.self, from: raAPIResponse)
                    self.userGameCompletionProgress = decodedUserGameCompletionProgress
                } catch let error {
                    print("Error decoding: ", error)
                }
            }
        } else {
            print("Bad Response Code!")
        }
    }
    
    func getGameSummary(gameID: Int) async {
        guard let url = URL(string: "https://retroachievements.org/API/API_GetGameInfoAndUserProgress.php?\(buildAuthenticationString())&g=\(gameID)&u=\(self.authenticatedWebAPIUsername)&a=1") else { fatalError("Missing URL") }
        
        if let raAPIResponse: Data = await makeAPICall(url: url) {
            DispatchQueue.main.sync {
                do {
                    let decodedGameSummary = try JSONDecoder().decode(GameSummary.self, from: raAPIResponse)
                    self.gameSummaryCache[decodedGameSummary.id] = decodedGameSummary
                } catch let error {
                    print("Error decoding: ", error)
                }
            }
        } else {
            print("Bad Response Code!")
        }
    }
    
    func getRAGameList() async {
        var validatedGameListJSONData: Data?
        var validatedGameList: [GameListGame]?
        
        // Check For Cached Data Before Making API Call
        if self.completeRetroAchievementsGameListJSONData != nil {
            validatedGameListJSONData = self.completeRetroAchievementsGameListJSONData
            print("Cached Game List Data Found - Attempting to Load Into Memory...")
        } else {
            print("No Cached Game List! Fetching New Data...")
            // Use Each ConsoleID & Get Game List from API
            var temporaryGameList: [GameListGame] = []
            if self.consolesCache?.consoles != nil {
                for console in self.consolesCache!.consoles {
                    // URL Arguments: f=1 (Only Return Games w/ Achievements) | i=n (Return Games for ConsoleID 'n')
                    guard let url = URL(string: "https://retroachievements.org/API/API_GetGameList.php?\(buildAuthenticationString())&f=1&i=\(String(console.id))") else { fatalError("Missing URL") }
                    if let raAPIResponse: Data = await makeAPICall(url: url) {
                        
                        do {
                            let decodedConsoleGames = try JSONDecoder().decode([GameListGame].self, from: raAPIResponse)
                            temporaryGameList += decodedConsoleGames
                        } catch {
                            print("Error Appending Console Game List JSON String to Local Var")
                            print(error)
                        }
                        
                        // DEBUG: Only Get Data for ONE Console
                        //break
                    }
                        
                }
            } else {
                print("getRAGameList() - Console List Missing!")
            }
            
            
            // Encode Game List
            do {
                let encodedGameList = try JSONEncoder().encode(temporaryGameList)
                validatedGameListJSONData = encodedGameList
            } catch {
                print("Error Encoding Game List JSON for Caching!")
            }
            
            print("Game List Fetched from API!")

        }
        
        // Cache Encoded Game List JSON Data & Store Decoded List in Memory
        if validatedGameListJSONData != nil {
            do {
                let decodedGameList = try JSONDecoder().decode([GameListGame].self, from: validatedGameListJSONData!)
                validatedGameList = decodedGameList
            } catch {
                print("Error Appending Console Game List JSON String to Local Var")
            }
            
            DispatchQueue.main.sync {
                self.gameList = validatedGameList ?? []
                self.completeRetroAchievementsGameListJSONData = validatedGameListJSONData
            }
            
            print("Game List Loaded!")
        }
    }
    
    func getGameConsoles() async {
        var validatedRAConsoleListJSONData: Data?
        
        // Check For Cached Data Before Making API Call
        if self.completeRetroAchievementsConsoleListJSONData != nil {
            print("Cached Console Data Found - Attempting to Load Into Memory...")
            validatedRAConsoleListJSONData = self.completeRetroAchievementsConsoleListJSONData
        } else { // TODO: Cache Expiration
            // Get Console Data from RA API
            print("No Cached Console Data! Fetching New Data...")
            guard let url = URL(string: "https://retroachievements.org/API/API_GetConsoleIDs.php?\(buildAuthenticationString())") else { fatalError("Missing URL") }
            if let raAPIResponse: Data = await makeAPICall(url: url) {
                validatedRAConsoleListJSONData = raAPIResponse
                print("Console List Fetched from API!")
            } else {
                print("Bad Response Code!")
            }
        }
        
        // Cache Encoded Console List JSON Data & Store Decoded List in Memory
        if validatedRAConsoleListJSONData != nil {
            DispatchQueue.main.sync {
                do {
                    let decodedConsoleSummary = try JSONDecoder().decode([Console].self, from: validatedRAConsoleListJSONData!)
                    self.consolesCache = Consoles(consoles: decodedConsoleSummary)
                    self.completeRetroAchievementsConsoleListJSONData = validatedRAConsoleListJSONData
                    return
                } catch {
                    print("Error Decoding Console List JSON Data!")
                }
            }
            
            print("Console Data Loaded!")
        
        }
    }
    
    func getGameForConsole(consoleID: Int) async {
        guard let url = URL(string: "https://retroachievements.org/API/API_GetGameList.php?\(buildAuthenticationString())&i=\(String(consoleID))&f=1)") else { fatalError("Missing URL") }
        
        if let raAPIResponse: Data = await makeAPICall(url: url) {
            DispatchQueue.main.sync {
                do {
                    let decodedConsoleGames = try JSONDecoder().decode([ConsoleGameInfo].self, from: raAPIResponse)
                    self.consoleGamesCache[consoleID] = decodedConsoleGames
                } catch let error {
                    print("Error decoding: ", error)
                }
            }
        } else {
            print("Bad Response Code!")
        }
    }
}
