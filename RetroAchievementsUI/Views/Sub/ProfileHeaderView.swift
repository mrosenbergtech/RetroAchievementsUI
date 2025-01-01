//
//  ProfileHeaderView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 1/1/25.
//

import SwiftUI
import Kingfisher

struct ProfileHeaderView: View {
    @EnvironmentObject var network: Network
    @Binding var hardcoreMode: Bool

    var body: some View {
        HStack {
            KFImage(URL(string: "https://retroachievements.org/" + (network.profile?.userPic ?? "UserPic/retroachievementsUI")))
                .resizable()
                .clipShape(.rect(cornerRadius: 10))
                .scaleEffect(1.25)
                .frame(width: 50, height: 50)
                .padding()
            
            VStack{
                Text(network.profile?.user ?? "Username")
                    .font(.title)
                    .bold()

                ScrollingText(text: network.buildUserStatusMessage(), font: .preferredFont(forTextStyle: .subheadline), leftFade: 15, rightFade: 15, startDelay: 3, alignment: .center)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.gray)
                        .padding(.horizontal)
            }
        }
    }
}

#Preview {
    @Previewable @State var hardcoreMode: Bool = true
    let network = Network()
    Task {
        await network.authenticateCredentials(webAPIUsername: debugWebAPIUsername, webAPIKey: debugWebAPIKey)
        
    }
    return ProfileHeaderView(hardcoreMode: $hardcoreMode).environmentObject(network)
}
