//
//  ProfileView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//

import SwiftUI
import Kingfisher

struct SearchView: View {
    @EnvironmentObject var network: Network
    @Binding var hardcoreMode: Bool
    var body: some View {
        
        if (network.gameList.count > 0) {
            Text("Search Coming Soon!")
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
