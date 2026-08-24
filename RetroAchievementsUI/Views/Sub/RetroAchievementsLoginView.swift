//
//  RetroAchievementsLoginView.swift
//  RetroAchievementsUI
//

import SwiftUI

struct RetroAchievementsLoginView: View {
    @EnvironmentObject var network: Network
    @Binding var shouldShowLoginSheet: Bool
    @Binding var webAPIUsername: String
    @Binding var webAPIKey: String
    @State var loginPending: Bool = false
    
    var body: some View {
        ZStack {
            // Background Color to match the app theme
            Color.raSurface
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // HEADER SECTION
                VStack(spacing: 12) {
                    Image(systemName: "trophy.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundStyle(Color.raAccent)

                    Text("RetroAchievements")
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .foregroundStyle(Color.raTextPrimary)

                    Text("Enter your credentials to sync your progress")
                        .font(.raBody)
                        .foregroundStyle(Color.raTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                // LOGIN FIELDS
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundStyle(Color.raTextTertiary)
                            .frame(width: 30)
                        TextField("Username", text: $webAPIUsername)
                            .textContentType(.username)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    .padding()
                    .background(Color.raSurfaceRaised)
                    
                    Divider().overlay(Color.raSeparator).padding(.leading, 50)
                    
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundStyle(Color.raTextTertiary)
                            .frame(width: 30)
                        SecureField("Web API Key", text: $webAPIKey)
                            .textContentType(.password)
                    }
                    .padding()
                    .background(Color.raSurfaceRaised)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                
                // ACTIONS
                VStack(spacing: 16) {
                    Button {
                        performLogin()
                    } label: {
                        HStack {
                            if loginPending {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.trailing, 8)
                            }
                            Text(loginPending ? "Verifying..." : "Sign In")
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(webAPIUsername.isEmpty || webAPIKey.isEmpty
                                    ? Color.raSurfaceSunken : Color.raAccent)
                        .foregroundStyle(webAPIUsername.isEmpty || webAPIKey.isEmpty
                                         ? Color.raTextTertiary : .white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .disabled(webAPIUsername.isEmpty || webAPIKey.isEmpty || loginPending)
                    
                    Button {
                        if let url = URL(string: "https://api-docs.retroachievements.org/getting-started.html#get-your-web-api-key") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Where do I find my API Key?")
                            .font(.raCaption.weight(.semibold))
                            .foregroundStyle(Color.raAccent)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // FOOTER
                if !network.webAPIAuthenticated && !loginPending {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                        Text("Your API key is stored in the device Keychain and never shared.")
                    }
                    .font(.raCaption)
                    .foregroundStyle(Color.raTextTertiary)
                    .padding(.bottom, 20)
                }
            }
        }
        .animation(.default, value: loginPending)
        .onChange(of: network.webAPIAuthenticated) { oldValue, newValue in
            if newValue {
                // Small delay to let the user see the "Success" state before closing
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    shouldShowLoginSheet = false
                }
            }
        }
    }
    
    private func performLogin() {
        loginPending = true
        Task {
            // Force a minimum animation time so the UI doesn't flicker
            let startTime = Date()
            
            await network.authenticateCredentials(
                webAPIUsername: webAPIUsername,
                webAPIKey: webAPIKey
            )
            
            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed < 1.0 {
                try? await Task.sleep(nanoseconds: UInt64((1.0 - elapsed) * 1_000_000_000))
            }
            
            if !network.webAPIAuthenticated {
                loginPending = false
            }
        }
    }
}

#Preview {
    @Previewable @State var webAPIUsername = debugWebAPIUsername
    @Previewable @State var webAPIKey = debugWebAPIKey
    @Previewable @State var shouldShowLoginSheet = false
    let network = Network()
    return RetroAchievementsLoginView(shouldShowLoginSheet: $shouldShowLoginSheet, webAPIUsername: $webAPIUsername, webAPIKey: $webAPIKey)
        .environmentObject(network)
}
