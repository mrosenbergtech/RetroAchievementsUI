//
//  SettingsView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//

import SwiftUI

struct RetroAchievementsLoginView: View {
    @EnvironmentObject var network: Network
    @Binding var webAPIUsername: String
    @Binding var webAPIKey: String
    @Binding var shouldShowLoginSheet: Bool
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
                    .alignmentGuide(.listRowSeparatorLeading) { _ in -20 }

                    
                    HStack{
                        Text("Username: ")
                        TextField("Enter Username", text: $webAPIUsername)
                            .multilineTextAlignment(.center)
                            .onSubmit {
                                storedWebAPIUsername = webAPIUsername
                                network.authenticateCredentials(webAPIUsername: storedWebAPIUsername, webAPIKey: storedWebAPIKey)
                            }
                    }        
                    .alignmentGuide(.listRowSeparatorLeading) { _ in -20 }

                    
                    HStack{
                        Text("Web API Key: ")
                        SecureField("Enter Web API Key", text: $webAPIKey)
                            .multilineTextAlignment(.center)
                            .onSubmit {
                                storedWebAPIKey = webAPIKey
                                network.authenticateCredentials(webAPIUsername: storedWebAPIUsername, webAPIKey: storedWebAPIKey)
                            }
                    }
                    
                }
            )
            
            Section(
                header: Text("Get Login Credentials"), content: {
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
                            
                            Image(systemName: "safari")
                                .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                                .padding(/*@START_MENU_TOKEN@*/EdgeInsets()/*@END_MENU_TOKEN@*/)
                            
                            Spacer()
                        }
                    }
                }
            )
            
        }
        .alert("Please Enter RetroAchievement Credentials!", isPresented: $blankCredentials) {
            Button("OK", role: .cancel) { }
        }
    }
}

#Preview {
    @State var webAPIUsername = debugWebAPIUsername
    @State var webAPIKey = debugWebAPIKey
    @State var shouldShowLoginSheet = false
    let network = Network()
    network.authenticateCredentials(webAPIUsername: debugWebAPIUsername, webAPIKey: debugWebAPIKey)
    return RetroAchievementsLoginView(webAPIUsername: $webAPIUsername, webAPIKey: $webAPIKey, shouldShowLoginSheet: $shouldShowLoginSheet)
        .environmentObject(network)
}
