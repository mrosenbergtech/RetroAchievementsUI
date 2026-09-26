//
//  CommunityView.swift
//  RetroAchievementsUI
//
//  Everything happening outside your own collection: the people you follow,
//  and the sets being written.
//
//  One tab with a segmented control rather than two tabs — the tab bar is full
//  at five, and a sixth would collapse into iOS's "More" list. Achievement of
//  the Week sits above the control, visible in both segments: it is one row,
//  it changes weekly, and it belongs with community news rather than with your
//  own stats.
//

import SwiftUI

struct CommunityView: View {
    @EnvironmentObject var network: Network
    @Binding var hardcoreMode: Bool

    enum Segment: String, CaseIterable, Identifiable {
        case friends = "Friends"
        case newSets = "New & Revised"
        var id: String { rawValue }
    }

    @State private var segment: Segment = .friends

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                AchievementOfTheWeekCard(hardcoreMode: $hardcoreMode)

                Picker("", selection: $segment) {
                    ForEach(Segment.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)

                switch segment {
                case .friends: FriendsListView(hardcoreMode: $hardcoreMode)
                case .newSets: NewSetsFeedView(hardcoreMode: $hardcoreMode)
                }
            }
            .padding(.top, 8)
            .background(Color.raSurface)
            .userProfileNavigation(hardcoreMode: $hardcoreMode)
            .navigationTitle("Community")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if segment == .friends {
                    ToolbarItem(placement: .topBarTrailing) { PinUserButton() }
                }
            }
        }
    }
}

/// The ＋ that pins a username, lifted out of the list so the toolbar can own
/// it while the list itself is just content inside the segment.
struct PinUserButton: View {
    @EnvironmentObject var network: Network
    @State private var showPrompt = false
    @State private var draft = ""
    @State private var rejection: String?

    var body: some View {
        Button { showPrompt = true } label: { Image(systemName: "plus") }
            .accessibilityLabel("Pin a user")
            .alert("Pin a user", isPresented: $showPrompt) {
                TextField("RetroAchievements username", text: $draft)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Cancel", role: .cancel) { draft = "" }
                Button("Pin") { pin() }
            } message: {
                // There is no user-search endpoint, so the name has to be
                // exact — say so rather than letting a typo look like a
                // missing account.
                Text("Exact username, as it appears on retroachievements.org.")
            }
            .alert("Couldn’t pin that",
                   isPresented: Binding(get: { rejection != nil },
                                        set: { if !$0 { rejection = nil } })) {
                Button("OK", role: .cancel) { rejection = nil }
            } message: {
                Text(rejection ?? "")
            }
    }

    private func pin() {
        let name = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        draft = ""
        guard !name.isEmpty else { return }
        guard Network.userKey(name) != Network.userKey(network.authenticatedWebAPIUsername) else {
            rejection = "That’s you — your own profile is the Profile tab."
            return
        }
        guard network.pinUser(name) else {
            rejection = "\(name) is already pinned."
            return
        }
    }
}
