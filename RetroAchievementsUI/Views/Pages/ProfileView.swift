//
//  ProfileView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var network: Network
    @Environment(\.selectedGameID) var selectedGameID: Binding<GameSheetItem?>
    @Binding var hardcoreMode: Bool
    
    @State private var forceSkeleton: Bool = false
    
    var body: some View {
        NavigationView {
            Group {
                if network.isFetching || forceSkeleton || network.profile == nil {
                    skeletonLayout
                        .background(Color(UIColor.systemBackground))
                        .transition(.opacity)
                } else {
                    VStack(spacing: 0) {
                        ProfileHeaderView(hardcoreMode: $hardcoreMode)
                            .background(Color(UIColor.systemBackground))
                            .overlay(Divider().opacity(0.5), alignment: .bottom)

                        Form {
                            Section(header: Label("Recently Played Games", systemImage: "clock.arrow.circlepath")) {
                                RecentGamesView(hardcoreMode: $hardcoreMode)
                            }
                            
                            Section(header: Label("Recent Achievements", systemImage: "medal")) {
                                RecentAchievementsView(hardcoreMode: $hardcoreMode)
                            }
                            
                            Section(header: Label("Awards", systemImage: "trophy")) {
                                AwardsView(hardcoreMode: $hardcoreMode)
                            }
                        }
                        .listStyle(.insetGrouped)
                        .refreshable {
                            await refreshWithMinimumDuration()
                        }
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: network.isFetching)
            .animation(.easeInOut(duration: 0.4), value: forceSkeleton)
            .animation(.easeInOut(duration: 0.4), value: network.profile == nil)
            .navigationBarTitle("Profile")
            .navigationBarHidden(true)
        }
        .task {
            if network.profile == nil {
                await network.fetchAllProfileData()
            }
        }
    }

    private func refreshWithMinimumDuration() async {
        forceSkeleton = true
        let startTime = Date()
        await network.fetchAllProfileData()
        let elapsed = Date().timeIntervalSince(startTime)
        let minimumDuration: TimeInterval = 1.5
        
        if elapsed < minimumDuration {
            let delay = UInt64((minimumDuration - elapsed) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: delay)
        }
        
        withAnimation {
            forceSkeleton = false
        }
    }

    private var skeletonLayout: some View {
        VStack(spacing: 0) {
            ProfileHeaderView(hardcoreMode: .constant(false))
                .overlay(Divider().opacity(0.5), alignment: .bottom)
            
            Form {
                Section("Recently Played Games") {
                    ForEach(0..<2, id: \.self) { _ in
                        SkeletonRow(hasImage: true)
                    }
                }
                Section("Recent Achievements") {
                    ForEach(0..<3, id: \.self) { _ in
                        SkeletonRow(hasImage: true)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .redacted(reason: .placeholder)
        .pulsing()
        .disabled(true)
    }
}

// MARK: - Supporting Views
struct SkeletonRow: View {
    var hasImage: Bool
    var body: some View {
        HStack {
            if hasImage {
                RoundedRectangle(cornerRadius: 8).frame(width: 48, height: 48)
            }
            VStack(alignment: .leading, spacing: 8) {
                Capsule().frame(width: 140, height: 14)
                Capsule().frame(width: 100, height: 10).opacity(0.6)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SkeletonPulse: ViewModifier {
    @State private var opacity = 0.4
    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: opacity)
            .onAppear { opacity = 0.9 }
    }
}

extension View {
    func pulsing() -> some View { modifier(SkeletonPulse()) }
}

#Preview {
    @Previewable @State var hardcoreMode: Bool = true
    let network = Network()
    Task { await network.authenticateCredentials(webAPIUsername: "debugUser", webAPIKey: "debugKey") }
    return ProfileView(hardcoreMode: $hardcoreMode).environmentObject(network)
}
