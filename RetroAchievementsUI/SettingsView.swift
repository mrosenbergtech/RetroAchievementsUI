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
    @State var storedWebAPIUsername: String = ""
    @State var storedWebAPIKey: String = ""
    @State var blankCredentials: Bool = false
    
    var body: some View {
        Form{
            Section(
                header: Text("RetroAchievements Login"), content: {
                    HStack {
                        Text("Authenticated:")
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
                    
                    HStack{
                        Text("Username: ")
                        TextField("Enter Username", text: $webAPIUsername)
                            .multilineTextAlignment(.center)
                            .onSubmit {
                                storedWebAPIUsername = webAPIUsername
                                network.authenticateRACredentials(webAPIUsername: storedWebAPIUsername, webAPIKey: storedWebAPIKey)
                            }
                    }
                    
                    HStack{
                        Text("Web API Key: ")
                        SecureField("Enter Web API Key", text: $webAPIKey)
                            .multilineTextAlignment(.center)
                            .onSubmit {
                                storedWebAPIKey = webAPIKey
                                network.authenticateRACredentials(webAPIUsername: storedWebAPIUsername, webAPIKey: storedWebAPIKey)
                            }
                    }
                    
                }
            )
            
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
        .alert("Please Enter RetroAchievement Credentials!", isPresented: $blankCredentials) {
            Button("OK", role: .cancel) { }
        }
    }
}

#Preview {
    @State var webAPIUsername = debugWebAPIUsername
    @State var webAPIKey = debugWebAPIKey
    @State var hardcoreMode = true
    let network = Network()
    network.authenticateRACredentials(webAPIUsername: debugWebAPIUsername, webAPIKey: debugWebAPIKey)
    return SettingsView(webAPIUsername: $webAPIUsername, webAPIKey: $webAPIKey, hardcoreMode: $hardcoreMode)
        .environmentObject(network)
}
