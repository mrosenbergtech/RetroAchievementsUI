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
    var body: some View {
        
        if (network.profile != nil && network.awards != nil) {
            NavigationView {
                VStack {
                    HStack {
                        KFImage(URL(string: "https://retroachievements.org/" + (network.profile?.userPic ?? "UserPic/retroachievementsUI")))
                            .resizable()
                            .clipShape(.rect(cornerRadius: 10))
                            .scaleEffect(0.75)
                            .frame(width: 50, height: 50)
                        
                        Text(network.profile?.user ?? "Username")
                            .font(.title)
                            .bold()
                    }
                    
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
