//
//  ProfileHeaderView.swift
//  RetroAchievementsUI
//

import SwiftUI
import Kingfisher

struct ProfileHeaderView: View {
    @EnvironmentObject var network: Network
    @Binding var hardcoreMode: Bool
    /// Settings lives in a sheet raised from here rather than in a tab.
    var onOpenSettings: (() -> Void)?

    @State private var pulseAlpha: Double = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var points: Int {
        hardcoreMode ? network.profile?.totalPoints ?? 0
                     : network.profile?.totalSoftcorePoints ?? 0
    }

    /// Games the user has any progress in.
    private var gamesPlayed: Int {
        network.userGameCompletionProgress?.total
            ?? network.userGameCompletionProgress?.results.count
            ?? 0
    }

    /// Achievements earned across those games, respecting the hardcore toggle.
    ///
    /// Derived from completion progress, which the API caps at 500 games, so
    /// this undercounts for very large libraries.
    private var achievementsEarned: Int {
        (network.userGameCompletionProgress?.results ?? []).reduce(0) { total, game in
            total + (hardcoreMode ? game.numAwardedHardcore : game.numAwarded)
        }
    }

    var body: some View {
        // Compact by design: the profile has to fit one screen, so this block
        // gives up height wherever it can without losing information.
        VStack(spacing: 8) {
            HStack(alignment: .center, spacing: 12) {
                avatar

                VStack(alignment: .leading, spacing: 6) {
                    Text(network.profile?.user ?? "Username")
                        .font(.raDisplay)
                        .foregroundStyle(Color.raTextPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    HStack(spacing: 6) {
                        RAChip(text: network.isUserOnline ? "ONLINE" : "OFFLINE",
                               tint: network.isUserOnline ? .green : .raTextSecondary) {
                            RAStatusDot()
                        }

                        RAChip(hardcoreMode ? "HARDCORE" : "STANDARD",
                               systemImage: hardcoreMode ? "flame.fill" : "bolt.fill",
                               tint: hardcoreMode ? .orange : .blue)
                    }
                }

                Spacer(minLength: 0)

                // Points moved into the stat row below; this corner is now the
                // way into Settings, which no longer occupies a tab.
                Button {
                    onOpenSettings?()
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color.raTextSecondary)
                        .frame(width: 38, height: 38)
                        .background(Color.raSurfaceRaised, in: Circle())
                        .overlay(Circle().strokeBorder(Color.raSeparator, lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Settings")
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)

            stats

            statusLine
        }
        .padding(.bottom, 8)
        .background(Color.raSurface)
    }

    // MARK: - Avatar

    private var avatar: some View {
        ZStack {
            Circle()
                .stroke(network.isUserOnline ? Color.green : Color.raSeparator, lineWidth: 2.5)
                .frame(width: 54, height: 54)
                .opacity(network.isUserOnline && !reduceMotion ? pulseAlpha : 1)

            KFImage(RAImageURL.avatar(network.profile?.userPic))
                .resizable()
                .placeholder { Circle().fill(Color.raSurfaceSunken) }
                .fade(duration: 0.2)
                .aspectRatio(contentMode: .fill)
                .frame(width: 47, height: 47)
                .clipShape(Circle())
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulseAlpha = 0.35
            }
        }
    }

    // MARK: - Stats

    private var stats: some View {
        HStack(spacing: 0) {
            stat("Games Played", value: gamesPlayed)
            divider
            stat("Achievements", value: achievementsEarned)
            divider
            // Follows the Hardcore Mode toggle, and says which it is showing so
            // the number is never ambiguous.
            stat(hardcoreMode ? "Hardcore Pts" : "Softcore Pts", value: points)
        }
        .padding(.vertical, 8)
        .background(Color.raSurfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 16)
    }

    private func stat(_ label: String, value: Int) -> some View {
        VStack(spacing: 2) {
            Text(value, format: .number)
                .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                .foregroundStyle(Color.raTextPrimary)
                .contentTransition(.numericText())
            Text(label)
                .raMicroLabel()
                .foregroundStyle(Color.raTextTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.25), value: value)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.raSeparator)
            .frame(width: 1, height: 24)
    }

    // MARK: - Status

    /// The rich-presence line, scrolling so nothing is lost.
    ///
    /// It keeps the compact height that the one-screen profile needs — the old
    /// version's cost was the tinted bar and its padding, not the marquee, so
    /// only the bar is gone. ScrollingText sizes itself to the text and stays
    /// still unless the string actually overflows.
    @ViewBuilder
    private var statusLine: some View {
        if !network.isFetching {
            ScrollingText(text: Self.trimmed(network.buildUserStatusMessage()),
                          font: .preferredFont(forTextStyle: .caption1),
                          leftFade: 12,
                          rightFade: 12,
                          startDelay: 2,
                          alignment: .leading)
                .foregroundStyle(Color.raTextSecondary)
                .padding(.horizontal, 16)
        }
    }

    /// buildUserStatusMessage() wraps its text in brackets for the old bar.
    /// Its format is asserted by tests, so strip them at display time instead.
    static func trimmed(_ message: String) -> String {
        var text = message
        if text.hasPrefix("[") { text.removeFirst() }
        if text.hasSuffix("]") { text.removeLast() }
        return text
    }
}

#Preview {
    @Previewable @State var hardcoreMode: Bool = true
    let network = Network()
    Task {
        await network.authenticateCredentials(webAPIUsername: debugWebAPIUsername, webAPIKey: debugWebAPIKey)
    }
    return ProfileHeaderView(hardcoreMode: $hardcoreMode)
        .environmentObject(network)
}
