//
//  SettingsView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//

import SwiftUI

struct RetroAchievementsLoginView: View {
    @EnvironmentObject var network: Network
    @Binding var shouldShowLoginSheet: Bool
    @Binding var webAPIUsername: String
    @Binding var webAPIKey: String
    @State var blankCredentials: Bool = false
    
    var body: some View {
        Form{
            Section(
                header: Text("RetroAchievements Login"), content: {
                    HStack {
                        Spacer()
                        Text("Authenticated:")
                        Image(systemName: "x.circle")
                            .foregroundColor(.red)
                        Spacer()
                    }                    
                    .alignmentGuide(.listRowSeparatorLeading) { _ in -20 }
                    
                    TextField("Username", text: $webAPIUsername)
                        .multilineTextAlignment(.center)
      
                    SecureField("Web API Key", text: $webAPIKey)
                        .multilineTextAlignment(.center)
                    
                    Button {
                        network.authenticateCredentials(webAPIUsername: webAPIUsername, webAPIKey: webAPIKey)
                    } label: {
                        HStack{
                            Spacer()
                            Text("Login")
                            Spacer()
                        }
                    }
                    
                    Button {
                        guard let url = URL(string: "https://api-docs.retroachievements.org/getting-started.html#get-your-web-api-key") else {
                             return
                        }

                        if UIApplication.shared.canOpenURL(url) {
                            print("Opening RA Login Credentials URL")
                             UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text("Get Login Credentials")
                            Spacer()
                        }
                    }
                }
            )
        }
    }
}

#Preview {
    @State var webAPIUsername = debugWebAPIUsername
    @State var webAPIKey = debugWebAPIKey
    @State var shouldShowLoginSheet = false
    let network = Network()
    network.authenticateCredentials(webAPIUsername: debugWebAPIUsername, webAPIKey: debugWebAPIKey)
    return RetroAchievementsLoginView(shouldShowLoginSheet: $shouldShowLoginSheet, webAPIUsername: $webAPIUsername, webAPIKey: $webAPIKey)
        .environmentObject(network)
}
