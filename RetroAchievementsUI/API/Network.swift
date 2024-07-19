//
//  Network.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//

import Foundation
import SwiftUI

class Network: ObservableObject {
    @Published var profile: Profile? = nil
    @Published var awards: Awards? = nil
    @Published var userRecentlyPlayedGames: [RecentGame] = []
    @Published var userGameCompletionProgress: UserGamesCompletionProgressResult? = nil
    @Published var consoles: [Console] = []
    @Published var consoleGamesCache: [Int : [ConsoleGameInfo]] = [:]
    @Published var gameSummaryCache: [Int: GameSummary] = [:]
    @Published var initialWebAPIAuthenticationCheckComplete: Bool = false
    @Published var webAPIAuthenticated: Bool = false
    @Published var consolesCache: Consoles? = nil
    @Published var authenticatedWebAPIUsername: String = ""
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
            }
        } catch {
            print(error)
            return nil
        }
        
        return nil
    }
        
    func authenticateCredentials(webAPIUsername: String, webAPIKey: String) async {
        guard let url = URL(string: "https://retroachievements.org/API/API_GetUserProfile.php?z=\(webAPIUsername)&y=\(webAPIKey)&u=\(webAPIUsername)") else { fatalError("Missing URL") }
        
        if let raAPIResponse: Data = await makeAPICall(url: url) {
            DispatchQueue.main.async {
                self.initialWebAPIAuthenticationCheckComplete = true
                self.webAPIAuthenticated = true
                self.authenticatedWebAPIUsername = webAPIUsername
                self.authenticatedWebAPIKey = webAPIKey
                
                Task {
                    await self.getProfile()
                }
                
                Task {
                    await self.getAwards()

                }
                
                Task {
                    await self.getUserGameCompletionProgress()
                }
                
                Task {
                    await self.getUserRecentGames()
                }
                
                Task {
                    await self.getGameConsoles()
                }
                                    
                do {
                    let decodedProfile = try JSONDecoder().decode(Profile.self, from: raAPIResponse)
                    self.profile = decodedProfile
                } catch let error {
                    print("Error decoding: ", error)
                }
            }
        } else {
            print("Bad Response Code!")
            DispatchQueue.main.async {
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
            DispatchQueue.main.async {
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
            DispatchQueue.main.async {
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
            DispatchQueue.main.async {
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
    
    func getUserGameCompletionProgress() async {
        guard let url = URL(string: "https://retroachievements.org/API/API_GetUserCompletionProgress.php?\(buildAuthenticationString())&u=\(self.authenticatedWebAPIUsername)&c=500") else { fatalError("Missing URL") }
        
        if let raAPIResponse: Data = await makeAPICall(url: url) {
            DispatchQueue.main.async {
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
            DispatchQueue.main.async {
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
    
    func getGameConsoles() async {
        guard let url = URL(string: "https://retroachievements.org/API/API_GetConsoleIDs.php?\(buildAuthenticationString())") else { fatalError("Missing URL") }
        
        if let raAPIResponse: Data = await makeAPICall(url: url) {
            DispatchQueue.main.async {
                do {
                    let decodedConsoleSummary = try JSONDecoder().decode([Console].self, from: raAPIResponse)
                    self.consoles = decodedConsoleSummary
                    self.consolesCache = Consoles(consoles: self.consoles)
                } catch let error {
                    print("Error decoding: ", error)
                }
            }
        } else {
            print("Bad Response Code!")
        }
    }
    
    func getGameForConsole(consoleID: Int) async {
        guard let url = URL(string: "https://retroachievements.org/API/API_GetGameList.php?\(buildAuthenticationString())&i=\(String(consoleID))&f=1)") else { fatalError("Missing URL") }
        
        if let raAPIResponse: Data = await makeAPICall(url: url) {
            DispatchQueue.main.async {
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
