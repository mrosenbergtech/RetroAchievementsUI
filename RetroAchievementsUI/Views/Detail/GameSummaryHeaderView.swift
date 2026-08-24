//
//  GameSummaryHeaderView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/20/24.
//

import SwiftUI
import Kingfisher

struct GameSummaryHeaderView: View {
    @EnvironmentObject var network: Network
    @Binding var hardcoreMode: Bool
    var gameID: Int

    private var summary: GameSummary? { network.gameSummaryCache[gameID] }

    var body: some View {
        if let summary {
            content(summary)
        } else {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
                .task { await network.getGameSummary(gameID: gameID) }
        }
    }

    // MARK: - Content

    private func content(_ summary: GameSummary) -> some View {
        let tier = AwardTier(highestAwardKind: summary.highestAwardKind)
        let earned = hardcoreMode ? summary.numAwardedToUserHardcore : summary.numAwardedToUser
        let fraction = summary.numAchievements > 0
            ? Double(earned) / Double(summary.numAchievements)
            : 0

        return VStack(spacing: 0) {
            // ImageTitle (the title screen) was decoded but never rendered.
            // It makes a far better sheet header than another 64pt icon.
            backdrop(summary)

            VStack(spacing: 12) {
                VStack(spacing: 4) {
                    Text(summary.title)
                        .font(.raDisplay)
                        .foregroundStyle(Color.raTextPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)

                    Text(summary.consoleName)
                        .font(.raCaption)
                        .foregroundStyle(Color.raTextSecondary)
                }

                if let tier {
                    RAChip(tier.longDisplayName.uppercased(),
                           systemImage: tier.isMasteryClass ? "rosette" : "checkmark.seal.fill",
                           tint: RarityMaterial.of(tier).ink)
                }

                if summary.numAchievements > 0 {
                    VStack(spacing: 6) {
                        HStack(spacing: 14) {
                            RAMeta(systemImage: "trophy.fill",
                                   text: "\(earned)/\(summary.numAchievements)")
                            if let points = summary.pointsTotal {
                                RAMeta(systemImage: "command.circle.fill", text: "\(points)")
                            }
                            Text("\(Int((fraction * 100).rounded()))%")
                                .font(.raStatSmall)
                                .foregroundStyle(tier.map { RarityMaterial.of($0).ink }
                                                 ?? Color.raTextSecondary)
                        }
                        RAProgressBar(value: fraction, tier: tier, height: 5)
                    }
                    .padding(.horizontal, 40)
                } else {
                    Text("No achievements yet")
                        .font(.raCaption)
                        .foregroundStyle(Color.raTextTertiary)
                }

                metadata(summary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
        }
    }

    /// Title screen behind the game icon.
    ///
    /// Shown whole rather than cropped: this was `.fill` inside a fixed 128pt
    /// frame, which sliced the top and bottom off most title screens. The art
    /// is the point, so it keeps its own aspect ratio and the header grows to
    /// fit — capped so an unusually tall image can't take over the sheet.
    private func backdrop(_ summary: GameSummary) -> some View {
        ZStack(alignment: .bottom) {
            KFImage(RAImageURL.titleScreen(summary.imageTitle)
                    ?? RAImageURL.gameIcon(summary.imageIcon))
                .resizable()
                .placeholder {
                    Color.raSurfaceSunken.frame(height: 160)
                }
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                // Tall enough that the usual 4:3 title screen fills the width
                // rather than sitting letterboxed between margins.
                .frame(maxHeight: 300)
                // Only the lowest strip is veiled, so the icon and the title
                // below it stay legible without dimming the artwork itself.
                .overlay(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.55),
                            .init(color: Color.raSurface.opacity(0.65), location: 0.85),
                            .init(color: Color.raSurface, location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            RAThumbnail(url: RAImageURL.gameIcon(summary.imageIcon), size: 68, cornerRadius: 14)
                .offset(y: 22)
        }
        .padding(.bottom, 22)
        .accessibilityHidden(true)
    }

    /// Genre, developer and release date were all decoded but never shown.
    @ViewBuilder
    private func metadata(_ summary: GameSummary) -> some View {
        let items: [(String, String)] = [
            ("Genre", summary.genre),
            ("Developer", summary.developer),
            ("Publisher", summary.publisher),
            ("Released", summary.released),
        ].compactMap { label, value in
            guard let value, !value.isEmpty else { return nil }
            return (label, value)
        }

        if !items.isEmpty {
            HStack(spacing: 6) {
                ForEach(items.prefix(2), id: \.0) { item in
                    RAChip(item.1, tint: .raTextSecondary)
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var hardcoreMode: Bool = true
    let network = Network()
    Task {
        await network.authenticateCredentials(webAPIUsername: debugWebAPIUsername, webAPIKey: debugWebAPIKey)
        await network.getGameSummary(gameID: 10003)
    }

    return GameSummaryHeaderView(hardcoreMode: $hardcoreMode, gameID: 10003)
        .environmentObject(network)
}
