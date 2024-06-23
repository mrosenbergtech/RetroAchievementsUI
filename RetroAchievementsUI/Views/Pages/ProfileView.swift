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
        
        if (network.profile != nil || network.userRecentlyPlayedGames.count >= 0 || network.awards != nil) {
            NavigationView {
                VStack {
                    HStack {
                        KFImage(URL(string: "https://retroachievements.org/" + (network.profile?.userPic ?? "UserPic/retroachievementsUI")))
                            .resizable()
                            .clipShape(.rect(cornerRadius: 10))
                            .scaleEffect(0.75)
                            .frame(width: 96, height: 96)
                        
                        VStack {
                            
                            Text(network.profile?.user ?? "Username")
                                .font(.title)
                                .bold()
                            
                            HStack {
                                Image(systemName: "command.circle.fill")
                                Text(String(((hardcoreMode ? network.profile?.totalPoints : network.profile?.totalSoftcorePoints) ?? 0)))
                            }
                        }
                    }
                    
                    Form {
                        Section(header: Text("Recently Played Games")) {
                            ForEach(network.userRecentlyPlayedGames) { recentlyPlayedGame in
                                NavigationLink(destination: GameSummaryView(hardcoreMode: $hardcoreMode, gameID: recentlyPlayedGame.id)){
                                    GameSummaryHeaderView(hardcoreMode: $hardcoreMode, gameID: recentlyPlayedGame.id)
                                }
                            }
                        }
                        
                        Section(header: Text("Awards")) {
                            AwardsView(network: _network, hardcoreMode: $hardcoreMode)
                        }
                        
                        
                    }
                }
            }
        } else {
            ProgressView()
        }
        
    }
}

#Preview {
    @State var hardcoreMode: Bool = true
    let network = Network()
    network.authenticateCredentials(webAPIUsername: debugWebAPIUsername, webAPIKey: debugWebAPIKey)
    return ProfileView(hardcoreMode: $hardcoreMode)
        .environmentObject(network)
}
