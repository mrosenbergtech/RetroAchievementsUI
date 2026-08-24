//
//  RARow.swift
//  RetroAchievementsUI
//
//  The standard list row: thumbnail, title, subtitle, metadata, accessory.
//
//  Every list in the app was previously hand-assembled from an HStack, a
//  KFImage with its own corner radius, and a marquee. Rows disagreed on
//  thumbnail size, spacing and separator inset, and a screen full of marquees
//  animated all at once. Titles here truncate instead of scrolling; the marquee
//  component is gone from the app entirely.
//

import SwiftUI
import Kingfisher

// MARK: - Thumbnail

struct RAThumbnail: View {
    let url: URL?
    var size: CGFloat = 52
    var cornerRadius: CGFloat = 10
    /// Badges are transparent PNGs that should not be cropped.
    var contentMode: SwiftUI.ContentMode = .fill

    var body: some View {
        KFImage(url)
            .resizable()
            .placeholder {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.raSurfaceSunken)
            }
            .fade(duration: 0.2)
            .aspectRatio(contentMode: contentMode)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.raSeparator.opacity(0.6), lineWidth: 0.5)
            )
    }
}

// MARK: - Metadata

/// Icon + value pair used along the bottom of a row (points, trophies, dates).
struct RAMeta: View {
    let systemImage: String
    let text: String
    var tint: Color = .raTextSecondary

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: systemImage)
                .font(.system(size: 10, weight: .semibold))
            Text(text)
                .font(.raStatSmall)
        }
        .foregroundStyle(tint)
        .lineLimit(1)
    }
}

// MARK: - Progress

/// Thin completion bar, tinted by award tier once a game has been awarded.
struct RAProgressBar: View {
    let value: Double
    var tier: AwardTier?
    var height: CGFloat = 4

    private var tint: Color {
        guard let tier else { return .raAccent }
        return RarityMaterial.of(tier).ink
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.raSurfaceSunken)
                Capsule()
                    .fill(tint)
                    .frame(width: max(0, min(1, value)) * geo.size.width)
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

// MARK: - Row

/// Standard row layout. Callers supply the pieces; spacing and insets are fixed
/// so every list in the app lines up.
struct RARow<Accessory: View, Footer: View>: View {
    let imageURL: URL?
    let title: String
    var subtitle: String?
    var thumbnailSize: CGFloat = 52
    var thumbnailContentMode: SwiftUI.ContentMode = .fill
    var titleLineLimit: Int = 2
    @ViewBuilder var accessory: Accessory
    @ViewBuilder var footer: Footer

    var body: some View {
        HStack(spacing: 12) {
            RAThumbnail(url: imageURL,
                        size: thumbnailSize,
                        contentMode: thumbnailContentMode)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.raNameplate)
                    .foregroundStyle(Color.raTextPrimary)
                    .lineLimit(titleLineLimit)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                if let subtitle {
                    Text(subtitle)
                        .font(.raNameplateSub)
                        .foregroundStyle(Color.raTextSecondary)
                        .lineLimit(1)
                }

                footer
            }

            Spacer(minLength: 4)

            accessory
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

// Convenience overloads so callers only spell out the parts they use.

extension RARow where Accessory == EmptyView {
    init(imageURL: URL?, title: String, subtitle: String? = nil,
         thumbnailSize: CGFloat = 52,
         thumbnailContentMode: SwiftUI.ContentMode = .fill,
         titleLineLimit: Int = 2,
         @ViewBuilder footer: () -> Footer) {
        self.init(imageURL: imageURL, title: title, subtitle: subtitle,
                  thumbnailSize: thumbnailSize,
                  thumbnailContentMode: thumbnailContentMode,
                  titleLineLimit: titleLineLimit,
                  accessory: { EmptyView() }, footer: footer)
    }
}
