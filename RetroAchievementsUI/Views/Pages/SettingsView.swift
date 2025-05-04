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
    @Binding var unofficialSearchResults: Bool
    @Binding var shouldShowLoginSheet: Bool
    @State var blankCredentials: Bool = false
    
    var body: some View {
        Form
        {
            Section(header: Text("RetroAchievements Login"),
                content:
                {
                    HStack
                    {
                        Spacer()
                        
                        Text("Login Status:")
                            .bold()
                                                    
                        if network.webAPIAuthenticated
                        {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.green)
                        }
                        else
                        {
                            Image(systemName: "x.circle")
                                .foregroundColor(.red)
                        }
                        
                        Spacer()
                    }
                
                    if network.webAPIAuthenticated {
                        Button
                        {
                            webAPIUsername = ""
                            webAPIKey = ""
                            network.logout()
                            shouldShowLoginSheet = true
                        }
                        label:
                        {
                            HStack
                            {
                                Spacer()
                                Text("Logout " + network.authenticatedWebAPIUsername)
                                    .foregroundStyle(.cyan)
                                Spacer()
                            }
                        }
                    } else {
                        Button
                        {
                            shouldShowLoginSheet = true
                        }
                        label:
                        {
                            HStack
                            {
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
                content:
                {
                    Toggle("Hardcode Mode", isOn: $hardcoreMode)
                        .alignmentGuide(.listRowSeparatorLeading) { _ in -20 }
                    
                    Toggle("Search for Unofficial Games", isOn: $unofficialSearchResults)
                        .alignmentGuide(.listRowSeparatorLeading) { _ in -20 }
                    
                    
                    Button
                    {
                        let cache = ImageCache.default
                        cache.clearMemoryCache()
                        cache.clearDiskCache { print("Image Cache Cleared!") }
                    }
                    label:
                    {
                        HStack
                        {
                            Spacer()
                            Text("Clear Image Cache")
                                .foregroundStyle(.cyan)
                            Spacer()
                        }
                    }
                    .alignmentGuide(.listRowSeparatorLeading) { _ in -20 }
                    
                    if (network.cacheDate != nil)
                    {
                        Button
                        {
                            Task {
                                await network.refreshGameList()
                            }
                        }
                        label:
                        {
                            HStack
                            {
                                Spacer()
                                Text("Refresh Game List - Saved: " + Date(timeIntervalSince1970: network.cacheDate ?? -1.0).description.dropLast(15))
                                    .foregroundStyle(.cyan)
                                    .multilineTextAlignment(.center)
                                Spacer()
                            }
                        }
                        .alignmentGuide(.listRowSeparatorLeading) { _ in -20 }
                    }
                    else
                    {
                        HStack
                        {
                            ScrollingText(text: "Getting Game List - Please Wait...", font: .preferredFont(forTextStyle: .subheadline), leftFade: 15, rightFade: 15, startDelay: 3, alignment: .center)
                                .foregroundStyle(.gray)
                            ProgressView()
                        }
                    }
                }
            )
        }
        .onAppear
        {
            if webAPIUsername == "" && webAPIKey == ""
            {
                blankCredentials = true
            }
            else
            {
                blankCredentials = false
            }
            
            if !network.webAPIAuthenticated
            {
                shouldShowLoginSheet = true
            }
        }

    }
}

#Preview {
    @Previewable @State var webAPIUsername = debugWebAPIUsername
    @Previewable @State var webAPIKey = debugWebAPIKey
    @Previewable @State var hardcoreMode = true
    @Previewable @State var unofficialSearchResults = false
    @Previewable @State var shouldShowLoginSheet = false
    let network = Network()
    Task {
        await network.authenticateCredentials(webAPIUsername: debugWebAPIUsername, webAPIKey: debugWebAPIKey)
    }
    return SettingsView(webAPIUsername: $webAPIUsername, webAPIKey: $webAPIKey, hardcoreMode: $hardcoreMode, unofficialSearchResults: $unofficialSearchResults, shouldShowLoginSheet: $shouldShowLoginSheet)
        .environmentObject(network)
}
