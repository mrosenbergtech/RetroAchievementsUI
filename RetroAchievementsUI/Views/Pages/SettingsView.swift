//
//  SettingsView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var network: Network
    @Binding var webAPIUsername: String
    @Binding var webAPIKey: String
    @Binding var hardcoreMode: Bool
    @Binding var shouldShowLoginSheet: Bool
    @State var storedWebAPIUsername: String = ""
    @State var storedWebAPIKey: String = ""
    @State var blankCredentials: Bool = false
    
    
    
    var body: some View {
        Form{
            Section(header: Text("RetroAchievements Login"), 
                    content: {
                        HStack {
                            Spacer()
                            
                            Text("Login Status:")
                                .bold()
                            
                            Spacer()
                            
                            if network.webAPIAuthenticated {
                                Image(systemName: "checkmark.circle")
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "x.circle")
                                    .foregroundColor(.red)
                            }
                            
                            Spacer()
                        }
                
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
                )                    
            .alignmentGuide(.listRowSeparatorLeading) { _ in -20 }

                
            Section(
                header: Text("Achievement Settings"),
                content: {
                    Toggle("Hardcode Mode", isOn: $hardcoreMode)
                }
            )
        }
        .onAppear {
            storedWebAPIUsername = webAPIUsername
            storedWebAPIKey = webAPIKey
            
            if webAPIUsername == "" && webAPIKey == "" {
                blankCredentials = true
            } else {
                blankCredentials = false
            }
        }

    }
}

#Preview {
    @State var webAPIUsername = debugWebAPIUsername
    @State var webAPIKey = debugWebAPIKey
    @State var hardcoreMode = true
    @State var shouldShowLoginSheet = false
    let network = Network()
    network.authenticateCredentials(webAPIUsername: debugWebAPIUsername, webAPIKey: debugWebAPIKey)
    return SettingsView(webAPIUsername: $webAPIUsername, webAPIKey: $webAPIKey, hardcoreMode: $hardcoreMode, shouldShowLoginSheet: $shouldShowLoginSheet)
        .environmentObject(network)
}
