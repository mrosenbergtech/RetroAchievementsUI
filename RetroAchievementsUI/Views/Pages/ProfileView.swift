//
//  ProfileView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//

import SwiftUI
import Kingfisher

struct ProfileView: View {
    @EnvironmentObject var network: Network
    @Binding var hardcoreMode: Bool
    @State private var timeRemaining = 60
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        
        if (network.profile != nil && network.awards != nil) {
            NavigationView {
                VStack {
                    ProfileHeaderView(hardcoreMode: $hardcoreMode)
                    
                    Form {
                        RecentGamesView(hardcoreMode: $hardcoreMode)
                        
                        RecentAchievementsView(hardcoreMode: $hardcoreMode)
                        
                        AwardsView(hardcoreMode: $hardcoreMode)
                    }
                }
                .navigationBarTitle("Profile")
                .navigationBarHidden(true)
            }
            .refreshable {
                Task {
                    await network.getProfile()
                    await network.getUserGameCompletionProgress()
                    await network.getUserRecentAchievements()
                    await network.getUserRecentGames()
                    await network.getAwards()
                }
            }
            .onReceive(timer) { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    // Refresh Data
                    print("Profile Data Expired - Refreshing...", terminator:" ")
                    Task {
                        await network.getProfile()
                        await network.getUserGameCompletionProgress()
                        await network.getUserRecentAchievements()
                        await network.getUserRecentGames()
                        await network.getAwards()
                        
                        timeRemaining = 60
                        print("Profile Data Refreshed & Timer Reset!")
                    }
                }
            }
        } else {
            ProgressView()
        }
    }
}

#Preview {
    @Previewable @State var hardcoreMode: Bool = true
    let network = Network()
    Task {
        await network.authenticateCredentials(webAPIUsername: debugWebAPIUsername, webAPIKey: debugWebAPIKey)
    }
    
    return ProfileView(hardcoreMode: $hardcoreMode)
        .environmentObject(network)
}
