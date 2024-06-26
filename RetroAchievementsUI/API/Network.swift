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
    @Published var consolesCache: Consoles = Consoles()
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
        
    func authenticateCredentials(webAPIUsername: String, webAPIKey: String) {
        guard let url = URL(string: "https://retroachievements.org/API/API_GetUserProfile.php?z=\(webAPIUsername)&y=\(webAPIKey)&u=\(webAPIUsername)") else { fatalError("Missing URL") }
        
        let urlRequest = URLRequest(url: url)

        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                print("Request error: ", error)
                return
            }

            guard let response = response as? HTTPURLResponse else { return }
            print("RA Authentication API Call Returned Code: " + String(response.statusCode))
            
            // Authenticated -> Refresh Core Data
            if response.statusCode == 200 {
                guard let data = data else { return }
                DispatchQueue.main.async {
                    self.initialWebAPIAuthenticationCheckComplete = true
                    self.webAPIAuthenticated = true
                    self.authenticatedWebAPIUsername = webAPIUsername
                    self.authenticatedWebAPIKey = webAPIKey
                    self.getProfile()
                    self.getAwards()
                    self.getUserGameCompletionProgress()
                    self.getUserRecentGames()
                                        
                    do {
                        let decodedProfile = try JSONDecoder().decode(Profile.self, from: data)
                        self.profile = decodedProfile
                    } catch let error {
                        print("Error decoding: ", error)
                    }
                }
            } else {
                print("Bad Response Code: " + String(response.statusCode))
                DispatchQueue.main.async {
                    self.initialWebAPIAuthenticationCheckComplete = true
                    self.webAPIAuthenticated = false
                    self.authenticatedWebAPIUsername = ""
                    self.authenticatedWebAPIKey = ""
                }
            }
        }
        dataTask.resume()
    }
    
    func getProfile() {
        guard let url = URL(string: "https://retroachievements.org/API/API_GetUserProfile.php?\(buildAuthenticationString())&u=\(self.authenticatedWebAPIUsername)") else { fatalError("Missing URL") }

        let urlRequest = URLRequest(url: url)

        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                print("Request error: ", error)
                return
            }

            guard let response = response as? HTTPURLResponse else { return }
            print("RA Profile API Call Returned Code: " + String(response.statusCode))
            if response.statusCode == 200 {
                guard let data = data else { return }
                DispatchQueue.main.async {
                    do {
                        let decodedProfile = try JSONDecoder().decode(Profile.self, from: data)
                        self.profile = decodedProfile
                    } catch let error {
                        print("Error decoding: ", error)
                    }
                }
            } else {
                print("Bad Response Code: " + String(response.statusCode))
            }
        }
        dataTask.resume()
    }
    
    func getAwards() {
        guard let url = URL(string: "https://retroachievements.org/API/API_GetUserAwards.php?\(buildAuthenticationString())&u=\(self.authenticatedWebAPIUsername)") else { fatalError("Missing URL") }

        let urlRequest = URLRequest(url: url)

        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                print("Request error: ", error)
                return
            }

            guard let response = response as? HTTPURLResponse else { return }
            print("RA Awards API Call Returned Code: " + String(response.statusCode))
            if response.statusCode == 200 {
                guard let data = data else { return }
                DispatchQueue.main.async {
                    do {
                        let decodedAwards = try JSONDecoder().decode(Awards.self, from: data)
                        self.awards = decodedAwards
                    } catch let error {
                        print("Error decoding: ", error)
                    }
                }
            } else {
                print("Bad Response Code: " + String(response.statusCode))
            }
        }
        dataTask.resume()
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
    
    func getUserRecentGames() {
        guard let url = URL(string: "https://retroachievements.org/API/API_GetUserRecentlyPlayedGames.php?\(buildAuthenticationString())&u=\(self.authenticatedWebAPIUsername)&c=3") else { fatalError("Missing URL") }
        
        let urlRequest = URLRequest(url: url)

        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                print("Request error: ", error)
                return
            }

            guard let response = response as? HTTPURLResponse else { return }
            print("RA Get User Recent Games API Call Returned Code: " + String(response.statusCode))
            if response.statusCode == 200 {
                guard let data = data else { return }
                DispatchQueue.main.async {
                    do {
                        let decodedUserRecentlyPlayedGames = try JSONDecoder().decode([RecentGame].self, from: data)
                        self.userRecentlyPlayedGames = decodedUserRecentlyPlayedGames
                    } catch let error {
                        print("Error decoding: ", error)
                    }
                }
            } else {
                print("Bad Response Code: " + String(response.statusCode))
            }
        }
        dataTask.resume()
    }
    
    func getUserGameCompletionProgress() {
        guard let url = URL(string: "https://retroachievements.org/API/API_GetUserCompletionProgress.php?\(buildAuthenticationString())&u=\(self.authenticatedWebAPIUsername)&c=500") else { fatalError("Missing URL") }
        
        let urlRequest = URLRequest(url: url)

        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                print("Request error: ", error)
                return
            }

            guard let response = response as? HTTPURLResponse else { return }
            print("RA Get User Game Completion API Call Returned Code: " + String(response.statusCode))
            if response.statusCode == 200 {
                guard let data = data else { return }
                DispatchQueue.main.async {
                    do {
                        let decodedUserGameCompletionProgress = try JSONDecoder().decode(UserGamesCompletionProgressResult.self, from: data)
                        self.userGameCompletionProgress = decodedUserGameCompletionProgress
                    } catch let error {
                        print("Error decoding: ", error)
                    }
                }
            } else {
                print("Bad Response Code: " + String(response.statusCode))
            }
        }
        dataTask.resume()
    }
    
    func getGameSummary(gameID: Int) {
        guard let url = URL(string: "https://retroachievements.org/API/API_GetGameInfoAndUserProgress.php?\(buildAuthenticationString())&g=\(gameID)&u=\(self.authenticatedWebAPIUsername)&a=1") else { fatalError("Missing URL") }
        
        let urlRequest = URLRequest(url: url)

        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                print("Request error: ", error)
                return
            }

            guard let response = response as? HTTPURLResponse else { return }
            print("RA Game Summary (Game ID = '\(gameID)') API Call Returned Code: " + String(response.statusCode))
            if response.statusCode == 200 {
                guard let data = data else { return }
                DispatchQueue.main.async {
                    do {
                        let decodedGameSummary = try JSONDecoder().decode(GameSummary.self, from: data)
                        self.gameSummaryCache[decodedGameSummary.id] = decodedGameSummary
                    } catch let error {
                        print("Error decoding: ", error)
                    }
                }
            } else {
                print("Bad Response Code: " + String(response.statusCode))
            }
        }
        dataTask.resume()
    }
    
    func getGameConsoles() {
        guard let url = URL(string: "https://retroachievements.org/API/API_GetConsoleIDs.php?\(buildAuthenticationString())") else { fatalError("Missing URL") }

        let urlRequest = URLRequest(url: url)

        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                print("Request error: ", error)
                return
            }

            guard let response = response as? HTTPURLResponse else { return }
            print("RA Consoles Summary API Call Returned Code: " + String(response.statusCode))
            if response.statusCode == 200 {
                guard let data = data else { return }
                DispatchQueue.main.async {
                    do {
                        let decodedConsoleSummary = try JSONDecoder().decode([Console].self, from: data)
                        self.consoles = decodedConsoleSummary
                    } catch let error {
                        print("Error decoding: ", error)
                    }
                }
            } else {
                print("Bad Response Code: " + String(response.statusCode))
            }
        }
        dataTask.resume()
    }
    
    func getGameForConsole(consoleID: Int) {
        guard let url = URL(string: "https://retroachievements.org/API/API_GetGameList.php?\(buildAuthenticationString())&i=\(String(consoleID))&f=1)") else { fatalError("Missing URL") }

        let urlRequest = URLRequest(url: url)

        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                print("Request error: ", error)
                return
            }

            guard let response = response as? HTTPURLResponse else { return }
            print("RA Console Games API Call Returned Code: " + String(response.statusCode))
            if response.statusCode == 200 {
                guard let data = data else { return }
                DispatchQueue.main.async {
                    do {
                        let decodedConsoleGames = try JSONDecoder().decode([ConsoleGameInfo].self, from: data)
                        self.consoleGamesCache[consoleID] = decodedConsoleGames
                    } catch let error {
                        print("Error decoding: ", error)
                    }
                }
            } else {
                print("Bad Response Code: " + String(response.statusCode))
            }
        }
        dataTask.resume()
    }
}
