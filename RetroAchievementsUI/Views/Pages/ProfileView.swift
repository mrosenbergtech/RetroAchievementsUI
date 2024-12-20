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
                                     GameSummaryPreviewView(hardcoreMode: $hardcoreMode, imageIconString: recentlyPlayedGame.imageIcon, gameTitle: recentlyPlayedGame.title, gameConsoleName: recentlyPlayedGame.consoleName, maxPossible: recentlyPlayedGame.numPossibleAchievements, numAwardedHardcore: recentlyPlayedGame.numAchievedHardcore, numAwarded: recentlyPlayedGame.numAchieved, highestAwardKind: network.userGameCompletionProgress?.results.filter {$0.id == recentlyPlayedGame.id}.first?.highestAwardKind ?? nil)
                                }
                            }
                        }
                        
                        AwardsView(network: _network, hardcoreMode: $hardcoreMode)                        
                    }
                }
            }
            .refreshable {
                Task {
                    await network.getProfile()
                    await network.getUserGameCompletionProgress()
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
