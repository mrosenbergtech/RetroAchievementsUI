//
//  SettingsView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//

import SwiftUI
import Kingfisher

struct SettingsView: View {
    @EnvironmentObject var network: Network
    @Binding var webAPIUsername: String
    @Binding var webAPIKey: String
    @Binding var hardcoreMode: Bool
    @Binding var shouldShowLoginSheet: Bool
    @State var blankCredentials: Bool = false
    
    var body: some View {
        Form{
            Section(header: Text("RetroAchievements Login"), 
                content: {
                    HStack {
                        Spacer()
                        
                        Text("Login Status:")
                            .bold()
                                                    
                        if network.webAPIAuthenticated {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "x.circle")
                                .foregroundColor(.red)
                        }
                        
                        Spacer()
                    }
                
                    if network.webAPIAuthenticated {
                        Button {
                            webAPIUsername = ""
                            webAPIKey = ""
                            network.logout()
                            shouldShowLoginSheet = true
                        } label: {
                            HStack{
                                Spacer()
                                Text("Logout " + network.authenticatedWebAPIUsername)
                                Spacer()
                            }
                        }
                    } else {
                        Button {
                            shouldShowLoginSheet = true
                        } label: {
                            HStack {
                                Spacer()
                                
                                Text("Enter Credentials")
                                    .foregroundStyle(.cyan)
                                
                                Spacer()
                            }
                        }
                    }
                }
            )
            .alignmentGuide(.listRowSeparatorLeading) { _ in -20 }
                
            Section(
                header: Text("Other Settings"),
                content: {
                    VStack{
                        Toggle("Hardcode Mode", isOn: $hardcoreMode)
                        
                        Button {
                            let cache = ImageCache.default
                            cache.clearMemoryCache()
                            cache.clearDiskCache { print("Image Cache Cleared!") }
                        } label: {
                            HStack {
                                Spacer()
                                Text("Clear Image Cache")
                                    .foregroundStyle(.cyan)
                                Spacer()
                            }
                        }
                    }
                    
                }
            )
        }
        .onAppear {
            if webAPIUsername == "" && webAPIKey == "" {
                blankCredentials = true
            } else {
                blankCredentials = false
            }
            
            if !network.webAPIAuthenticated {
                shouldShowLoginSheet = true
            }
        }

    }
}

#Preview {
    @Previewable @State var webAPIUsername = debugWebAPIUsername
    @Previewable @State var webAPIKey = debugWebAPIKey
    @Previewable @State var hardcoreMode = true
    @Previewable @State var shouldShowLoginSheet = false
    let network = Network()
    Task {
        await network.authenticateCredentials(webAPIUsername: debugWebAPIUsername, webAPIKey: debugWebAPIKey)
    }
    return SettingsView(webAPIUsername: $webAPIUsername, webAPIKey: $webAPIKey, hardcoreMode: $hardcoreMode, shouldShowLoginSheet: $shouldShowLoginSheet)
        .environmentObject(network)
}
