//
//  RASkeleton.swift
//  RetroAchievementsUI
//
//  Loading placeholders. `SkeletonRow` / `SkeletonPulse` / `.pulsing()` used to
//  live inside ProfileView, while MyGamesView and GameSummaryView each
//  re-declared their own copy of the same rounded-rectangle markup.
//

import SwiftUI

struct SkeletonPulse: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var opacity = 0.4

    func body(content: Content) -> some View {
        content
            .opacity(reduceMotion ? 0.6 : opacity)
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                value: opacity
            )
            .onAppear { if !reduceMotion { opacity = 0.9 } }
    }
}

extension View {
    func pulsing() -> some View { modifier(SkeletonPulse()) }

    /// The full placeholder treatment: redacted content that breathes.
    func skeleton() -> some View {
        self.redacted(reason: .placeholder)
            .pulsing()
            .disabled(true)
    }
}

/// List-row placeholder: optional leading thumbnail plus two text lines.
struct SkeletonRow: View {
    var hasImage: Bool = true
    var imageSize: CGFloat = 48

    var body: some View {
        HStack(spacing: 12) {
            if hasImage {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.raSurfaceSunken)
                    .frame(width: imageSize, height: imageSize)
            }
            VStack(alignment: .leading, spacing: 8) {
                Capsule().fill(Color.raSurfaceSunken).frame(width: 140, height: 14)
                Capsule().fill(Color.raSurfaceSunken).frame(width: 100, height: 10).opacity(0.6)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}

/// Card-shaped placeholder matching `RACardFaceView`'s aspect ratio, so the grid
/// does not reflow when real cards arrive.
struct SkeletonCard: View {
    var body: some View {
        RoundedRectangle(cornerRadius: RACardMetrics.cornerRadius, style: .continuous)
            .fill(Color.raSurfaceSunken)
            .aspectRatio(RACardMetrics.aspectRatio, contentMode: .fit)
    }
}

#Preview {
    VStack(spacing: 20) {
        VStack { SkeletonRow(); SkeletonRow() }
        HStack { SkeletonCard(); SkeletonCard() }
    }
    .padding()
    .skeleton()
}
