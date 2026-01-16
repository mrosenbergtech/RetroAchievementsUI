//
//  SettingsView.swift
//  RetroAchievementsUI
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
    
    @State private var showingLogoutAlert = false
    
    var body: some View {
        Form {
            // ACCOUNT SECTION
            Section {
                HStack(spacing: 15) {
                    KFImage(URL(string: "https://retroachievements.org/" + (network.profile?.userPic ?? "UserPic/retroachievementsUI")))
                        .resizable()
                        .placeholder { Circle().fill(Color.gray.opacity(0.2)) }
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 56, height: 56)
                        .clipShape(Circle())
                    VStack(alignment: .leading) {
                        Text(network.webAPIAuthenticated ? network.authenticatedWebAPIUsername : "Not Signed In")
                            .font(.headline)
                            .lineLimit(1)                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(network.webAPIAuthenticated ? .green : .red)
                                .frame(width: 8, height: 8)
                            Text(network.webAPIAuthenticated ? "Authenticated" : "Action Required")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if network.webAPIAuthenticated {
                        Button("Logout") {
                            showingLogoutAlert = true
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .controlSize(.small)
                    } else {
                        Button("Login") {
                            shouldShowLoginSheet = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Account")
            } footer: {
                if !network.webAPIAuthenticated {
                    Text("Please enter your credentials to access your achievements and progress.")
                }
            }
            
            // GAMEPLAY & SEARCH SETTINGS
            Section("Preferences") {
                Toggle(isOn: $hardcoreMode) {
                    Label {
                        Text("Hardcore Mode")
                    } icon: {
                        Image(systemName: "flame.fill").foregroundColor(.orange)
                    }
                }
                
                Toggle(isOn: $unofficialSearchResults) {
                    Label {
                        Text("Include Unofficial Games")
                    } icon: {
                        Image(systemName: "magnifyingglass.circle.fill").foregroundColor(.purple)
                    }
                }
            }
            
            // STORAGE & DATA
            Section("Data Management") {
                Button(role: .destructive) {
                    let cache = ImageCache.default
                    cache.clearMemoryCache()
                    cache.clearDiskCache { print("Image Cache Cleared!") }
                } label: {
                    Label("Clear Image Cache", systemImage: "photo.on.rectangle.angled")
                        .foregroundColor(.red)
                }
                
                if let cacheDate = network.cacheDate {
                    Button {
                        Task { await network.refreshGameList() }
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Refresh Game List", systemImage: "arrow.clockwise")
                                .foregroundColor(.blue)
                            Text("Last synced: \(formattedDate(cacheDate))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    HStack {
                        Label("Updating Game List...", systemImage: "hourglass")
                        Spacer()
                        ProgressView()
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            Section {
                Link(destination: URL(string: "https://retroachievements.org")!) {
                    Label("Visit RetroAchievements.org", systemImage: "safari")
                }
            } header: {
                Text("Resources")
            }
        }
        .navigationTitle("Settings")
        .alert("Logout", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                webAPIUsername = ""
                webAPIKey = ""
                network.logout()
                shouldShowLoginSheet = true
            }
        } message: {
            Text("Are you sure you want to log out? You will need your API key to sign back in.")
        }
        .onAppear {
            if !network.webAPIAuthenticated {
                shouldShowLoginSheet = true
            }
        }
    }
    
    private func formattedDate(_ interval: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: interval)
        return date.formatted(date: .abbreviated, time: .shortened)
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
