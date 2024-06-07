//
//  ProfileView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var network: Network
    var body: some View {
        
        if network.profile?.user != nil {
            VStack {
                Text(network.profile!.user)
                    .font(.title)
                    .bold()
                AsyncImage(url: URL(string: "https://retroachievements.org/" + (network.profile?.userPic ?? "UserPic/mrosen97")))
                { phase in
                    switch phase {
                    case .failure:
                        Image(systemName: "photo")
                            .font(.largeTitle)
                    case .success(let image):
                        image
                    default:
                        ProgressView()
                    }
                }
                .clipShape(.rect(cornerRadius: 25))
            }
        } else {
            ProgressView()
        }
        
    }
}

#Preview {
    ProfileView()
        .environmentObject(Network())
}
