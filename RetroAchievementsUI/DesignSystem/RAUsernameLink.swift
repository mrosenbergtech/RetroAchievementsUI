//
//  RAUsernameLink.swift
//  RetroAchievementsUI
//
//  A username, anywhere it appears, is a way to that player's profile.
//
//  Shared rather than rebuilt per screen so every username behaves the same
//  and the next one added is a one-liner. Wiring is in two halves:
//
//    RAUsernameLink("SporyTike")            at the point of use
//    .userProfileNavigation(hardcoreMode:)  once, on the screen owning the
//                                           NavigationStack
//
//  A link with no host simply does nothing when tapped rather than dropping
//  the reader somewhere unexpected — better a dead name than a navigation
//  stack pushing a profile onto a screen that cannot show one.
//

import SwiftUI

/// A username, boxed so `navigationDestination(item:)` can key on it.
struct VisitedUser: Identifiable, Hashable {
    let id: String
}

private struct VisitedUserKey: EnvironmentKey {
    static let defaultValue: Binding<VisitedUser?> = .constant(nil)
}

extension EnvironmentValues {
    var visitedUser: Binding<VisitedUser?> {
        get { self[VisitedUserKey.self] }
        set { self[VisitedUserKey.self] = newValue }
    }
}

struct RAUsernameLink: View {
    @Environment(\.visitedUser) private var visitedUser

    let username: String
    var font: Font = .raBody.weight(.semibold)

    init(_ username: String, font: Font = .raBody.weight(.semibold)) {
        self.username = username
        self.font = font
    }

    var body: some View {
        Button {
            visitedUser.wrappedValue = VisitedUser(id: username)
        } label: {
            Text(username)
                .font(font)
                .foregroundStyle(Color.raAccent)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens \(username)'s profile")
    }
}

extension View {
    /// Lets any `RAUsernameLink` below this point push a profile.
    ///
    /// Apply inside the NavigationStack that should own the pushed screen —
    /// the achievement sheet pushes onto itself, the Community tab onto its
    /// own stack.
    func userProfileNavigation(hardcoreMode: Binding<Bool>) -> some View {
        modifier(UserProfileNavigation(hardcoreMode: hardcoreMode))
    }
}

private struct UserProfileNavigation: ViewModifier {
    @Binding var hardcoreMode: Bool
    @State private var visited: VisitedUser?

    func body(content: Content) -> some View {
        content
            .environment(\.visitedUser, $visited)
            .navigationDestination(item: $visited) { user in
                UserProfileView(hardcoreMode: $hardcoreMode, username: user.id)
            }
    }
}
