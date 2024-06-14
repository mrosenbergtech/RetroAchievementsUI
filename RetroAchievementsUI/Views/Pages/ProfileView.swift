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
    var body: some View {
        
        if network.profile?.user != nil {
            VStack {
                Text(network.profile!.user)
                    .font(.title)
                    .bold()
                KFImage(URL(string: "https://retroachievements.org/" + (network.profile?.userPic ?? "UserPic/mrosen97")))
                .clipShape(.rect(cornerRadius: 25))
            }
        } else {
            ProgressView()
                .onAppear {
                    network.getProfile()
                }
        }
        
    }
}

#Preview {
    let network = Network()
    network.authenticateCredentials(webAPIUsername: debugWebAPIUsername, webAPIKey: debugWebAPIKey)
    return ProfileView()
        .environmentObject(network)
}
