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
    @Published var userGameCompletionProgress: UserGamesCompletionProgressResult? = nil
    @Published var consoles: [Console] = []
    @Published var consoleGamesCache: [Int : [ConsoleGameInfo]] = [:]
    @Published var gameSummaryCache: [Int: GameSummary] = [:]
    @Published var initialWebAPIAuthenticationCheckComplete: Bool = false
    @Published var webAPIAuthenticated: Bool = false
    @Published var consolesCache: Consoles = Consoles()
    private var authenticatedWebAPIUsername: String = ""
    private var authenticatedWebAPIKey: String = ""
    
    func buildAuthenticationString() -> String {
        return "z=\(authenticatedWebAPIUsername)&y=\(authenticatedWebAPIKey)"
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
                    self.getUserGameCompletionProgress()
                                        
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
        guard let url = URL(string: "https://retroachievements.org/API/API_GetGameInfoAndUserProgress.php?\(buildAuthenticationString())&g=\(gameID)&u=\(self.authenticatedWebAPIUsername)") else { fatalError("Missing URL") }
        
        let urlRequest = URLRequest(url: url)

        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                print("Request error: ", error)
                return
            }

            guard let response = response as? HTTPURLResponse else { return }
            print("RA Game Summary API Call Returned Code: " + String(response.statusCode))
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
