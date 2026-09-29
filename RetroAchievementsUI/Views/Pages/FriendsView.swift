//
//  FriendsView.swift
//  RetroAchievementsUI
//
//  Who you follow on RetroAchievements, plus anyone you have pinned locally.
//
//  Content only: it lives inside CommunityView's segmented control, so the
//  navigation stack, the title and the ＋ button belong to that screen.
//
//  Two sources because the web API is read-only on the social graph: it will
//  tell you who you follow (API_GetUsersIFollow) but offers no way to follow
//  anyone, so following still happens on the website. Pins fill that gap — any
//  username, kept on this device, listed above the follows.
//
//  Rows show what the follow list itself carries (name and points) and fetch
//  the "currently playing" line lazily, one request per row as it appears.
//  Loading every friend's presence up front would be a request per friend
//  before the screen could draw, and the API rate-limits hard enough to punish
//  exactly that.
//

import SwiftUI
import Kingfisher

struct FriendsListView: View {
    @EnvironmentObject var network: Network
    @Binding var hardcoreMode: Bool

    @State private var isLoading = true
    @State private var loadError: RANetworkError?

    /// Follows minus anyone already pinned — a pinned friend appears once, at
    /// the top, rather than in both sections.
    private var unpinnedFollows: [FollowedUser] {
        network.followedUsers
            .filter { !network.isPinned($0.user) }
            .sorted { $0.points(hardcoreMode: hardcoreMode) > $1.points(hardcoreMode: hardcoreMode) }
    }

    private var isEmpty: Bool {
        network.pinnedUsernames.isEmpty && network.followedUsers.isEmpty
    }

    var body: some View {
        List {
            if !network.pinnedUsernames.isEmpty {
                Section {
                    ForEach(network.pinnedUsernames, id: \.self) { username in
                        row(username: username, points: nil)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    network.unpinUser(username)
                                } label: {
                                    Label("Unpin", systemImage: "pin.slash")
                                }
                            }
                    }
                } header: {
                    Text("Pinned")
                }
                .listRowBackground(Color.raSurfaceRaised)
            }

            if !unpinnedFollows.isEmpty {
                Section {
                    ForEach(unpinnedFollows) { follow in
                        row(username: follow.user,
                            points: follow.points(hardcoreMode: hardcoreMode),
                            followsBack: follow.isFollowingMe == true)
                    }
                } header: {
                    Text("Following")
                }
                .listRowBackground(Color.raSurfaceRaised)
            }

            if isEmpty && !isLoading {
                emptyState
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.raSurface)
        .overlay {
            if isLoading && isEmpty { ProgressView() }
        }
        .refreshable { await load(force: true) }
        .task { await load(force: false) }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.2")
                .font(.system(size: 30))
                .foregroundStyle(Color.raTextTertiary)
            Text("No friends yet")
                .font(.raTitle)
                .foregroundStyle(Color.raTextPrimary)
            if let loadError {
                Text(loadError.title)
                    .font(.raBody)
                    .foregroundStyle(Color.raTextSecondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Follow players on retroachievements.org, or pin any username with ＋.")
                    .font(.raBody)
                    .foregroundStyle(Color.raTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .listRowBackground(Color.clear)
    }

    private func row(username: String, points: Int?, followsBack: Bool = false) -> some View {
        NavigationLink {
            UserProfileView(hardcoreMode: $hardcoreMode, username: username)
        } label: {
            FriendRow(username: username,
                      points: points,
                      followsBack: followsBack,
                      hardcoreMode: hardcoreMode)
        }
    }

    private func load(force: Bool) async {
        network.loadPinnedUsernames()
        // The follow list rarely changes within a session, so a tab switch
        // reuses it; pull-to-refresh is the way to ask again.
        if !force && network.followedUsersLoaded {
            isLoading = false
            return
        }
        isLoading = network.followedUsers.isEmpty
        loadError = await network.getFollowedUsers()
        isLoading = false
    }
}

/// One friend. Fetches its own presence line when it scrolls into view.
private struct FriendRow: View {
    @EnvironmentObject var network: Network
    let username: String
    let points: Int?
    let followsBack: Bool
    let hardcoreMode: Bool

    private var profile: Profile? { network.otherProfileCache[Network.userKey(username)] }

    private var presence: String? {
        guard let message = profile?.richPresenceMsg?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !message.isEmpty,
              message.caseInsensitiveCompare("Unknown") != .orderedSame
        else { return nil }
        return message
    }

    /// The follow list carries points; a pinned user's row has none until its
    /// profile lands, so fall back to that.
    private var displayPoints: Int? {
        points ?? profile.map { hardcoreMode ? $0.totalPoints : $0.totalSoftcorePoints }
    }

    var body: some View {
        HStack(spacing: 12) {
            KFImage(RAImageURL.avatar(profile?.userPic ?? "/UserPic/\(username).png"))
                .resizable()
                .placeholder { Circle().fill(Color.raSurfaceSunken) }
                .aspectRatio(contentMode: .fill)
                .frame(width: 40, height: 40)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(username)
                        .font(.raBody.weight(.semibold))
                        .foregroundStyle(Color.raTextPrimary)
                    if followsBack {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.raTextTertiary)
                            .accessibilityLabel("Follows you back")
                    }
                }

                if let presence {
                    Text(presence)
                        .font(.raCaption)
                        .foregroundStyle(Color.raAccent)
                        .lineLimit(1)
                } else {
                    Text("—")
                        .font(.raCaption)
                        .foregroundStyle(Color.raTextTertiary)
                }
            }

            Spacer(minLength: 8)

            if let displayPoints {
                Text("\(displayPoints)")
                    .font(.raStatSmall)
                    .foregroundStyle(Color.raTextSecondary)
            }
        }
        .padding(.vertical, 2)
        // One request per row, and only once it is on screen. Network dedupes
        // concurrent asks for the same user and the result is cached, so
        // scrolling back and forth does not re-fetch.
        .task {
            guard profile == nil else { return }
            await network.getUserProfile(username: username)
        }
    }
}
